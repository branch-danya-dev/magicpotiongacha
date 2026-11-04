--!nonstrict
-- A dependency-injected, session-locked adapter for ONE player's DataStore key.
-- This is not a multi-profile transaction/escrow implementation.
--
-- All gameplay writes use the live profile returned by load(), and must first
-- pass isWritable(). The caller persists offline catch-up before exposing it.
-- owner MUST be unique for each live server/adapter session (e.g. JobId + GUID).
-- validate and UpdateAsync transforms must not yield. sleep may yield.

local ProfileStore = {}
ProfileStore.__index = ProfileStore

local RECORD_VERSION = 1
local MAX_SAFE_INTEGER = 9007199254740991

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function integer(value)
	return finite(value) and value % 1 == 0 and math.abs(value) <= MAX_SAFE_INTEGER
end

-- Reject values DataStore cannot faithfully persist, including cycles and NaN.
-- Aliased (but acyclic) tables are copied independently, like serialization.
local function clone(value, ancestors, depth)
	local kind = type(value)
	if kind == "nil" or kind == "boolean" or kind == "string" then
		return value
	elseif kind == "number" then
		assert(finite(value), "non_finite_number")
		return value
	end
	assert(kind == "table", "non_serializable_value")
	assert(depth < 64, "profile_too_deep")
	assert(not ancestors[value], "cyclic_profile")
	assert(getmetatable(value) == nil, "profile_metatable")
	ancestors[value] = true
	local result = {}
	local numericCount, maximumIndex, stringCount = 0, 0, 0
	for key, child in pairs(value) do
		assert(type(key) == "string" or (integer(key) and key >= 1), "invalid_profile_key")
		if type(key) == "number" then
			numericCount += 1
			maximumIndex = math.max(maximumIndex, key)
		else
			stringCount += 1
		end
		result[key] = clone(child, ancestors, depth + 1)
	end
	assert(numericCount == 0 or stringCount == 0, "mixed_profile_table")
	assert(numericCount == maximumIndex, "sparse_profile_array")
	ancestors[value] = nil
	return result
end

local function copy(value)
	return clone(value, {}, 0)
end

local function keyFor(userId)
	-- Studio's multi-player test users can have negative IDs.
	if not integer(userId) then
		return nil
	end
	return "p:" .. tostring(userId)
end

function ProfileStore.new(options)
	assert(type(options) == "table", "options_required")
	assert(options.dataStore ~= nil and type(options.dataStore.UpdateAsync) == "function", "data_store_required")
	assert(type(options.now) == "function", "clock_required")
	assert(type(options.sleep) == "function", "sleep_required")
	assert(type(options.validate) == "function", "validator_required")
	assert(options.migrate == nil or type(options.migrate) == "function", "invalid_migrator")
	assert(type(options.owner) == "string" and #options.owner > 0 and #options.owner <= 256, "unique_owner_required")
	local leaseSeconds = options.leaseSeconds or 120
	local margin = options.safetyMarginSeconds or math.min(15, leaseSeconds / 4)
	local retries = options.retries or 3
	local delay = options.retryDelaySeconds or 0.25
	local gateTimeout = options.gateTimeoutSeconds or 10
	assert(finite(leaseSeconds) and leaseSeconds >= 30 and leaseSeconds <= 3600, "invalid_lease_duration")
	assert(finite(margin) and margin >= 0 and margin < leaseSeconds, "invalid_safety_margin")
	assert(integer(retries) and retries >= 1 and retries <= 10, "invalid_retries")
	assert(finite(delay) and delay >= 0 and delay <= 5, "invalid_retry_delay")
	assert(finite(gateTimeout) and gateTimeout > 0 and gateTimeout <= 30, "invalid_gate_timeout")
	return setmetatable({
		_dataStore = options.dataStore,
		_nowFunction = options.now,
		_sleep = options.sleep,
		_validate = options.validate,
		_migrate = options.migrate,
		_owner = options.owner,
		_leaseSeconds = leaseSeconds,
		_safetyMargin = margin,
		_retries = retries,
		_retryDelay = delay,
		_gateTimeout = gateTimeout,
		_entries = {},
		_gates = {},
		_operationSequence = 0,
	}, ProfileStore)
end

function ProfileStore:_now()
	local ok, value = pcall(self._nowFunction)
	if not ok or not finite(value) or value < 0 then
		return nil
	end
	return value
end

function ProfileStore:_snapshot(profile, expectedUserId, allowMigration)
	if type(profile) ~= "table" then
		return nil, "invalid_profile"
	end
	local copied, snapshot = pcall(copy, profile)
	if not copied then
		return nil, "invalid_profile"
	end
	if expectedUserId ~= nil and snapshot.userId ~= nil and snapshot.userId ~= expectedUserId then
		return nil, "profile_user_mismatch"
	end
	if allowMigration and self._migrate then
		local migrated, result = pcall(self._migrate, snapshot)
		if not migrated or type(result) ~= "table" then return nil, "profile_migration_failed" end
		-- Recheck serialization and identity after migration; never trust its output.
		return self:_snapshot(result, expectedUserId, false)
	end
	local checked, valid, reason = pcall(self._validate, snapshot)
	if not checked or valid ~= true then
		return nil, "invalid_profile" .. (type(reason) == "string" and ":" .. reason or "")
	end
	return snapshot
end

function ProfileStore:_recordValid(record, expectedUserId, allowMigration)
	if type(record) ~= "table" or record.schemaVersion ~= RECORD_VERSION then
		return false, "unsupported_record_schema"
	end
	if not integer(record.revision) or record.revision < 1 or record.revision >= MAX_SAFE_INTEGER then
		return false, "invalid_record_revision"
	end
	if record.lastOperationId ~= nil and type(record.lastOperationId) ~= "string" then
		return false, "invalid_operation_id"
	end
	local lease = record.lease
	if lease ~= nil and (
		type(lease) ~= "table"
		or type(lease.owner) ~= "string"
		or #lease.owner == 0
		or not finite(lease.expiresAt)
		or lease.expiresAt < 0
	) then
		return false, "invalid_record_lease"
	end
	local snapshot, reason = self:_snapshot(record.profile, expectedUserId, allowMigration)
	if not snapshot then
		return false, reason
	end
	return true, nil, snapshot
end

function ProfileStore:_operationId(key, operation)
	self._operationSequence += 1
	return self._owner .. ":" .. key .. ":" .. operation .. ":" .. tostring(self._operationSequence)
end

function ProfileStore:_acquireGate(key)
	local startedAt = self:_now()
	if not startedAt then
		return false, "invalid_clock"
	end
	local interval = 0.05
	-- An attempt bound also handles a broken/frozen injected clock safely.
	local attempts = math.ceil(self._gateTimeout / interval)
	for _ = 0, attempts do
		if not self._gates[key] then
			self._gates[key] = true
			return true
		end
		local now = self:_now()
		if not now then
			return false, "invalid_clock"
		end
		if now - startedAt >= self._gateTimeout then
			break
		end
		self._sleep(interval)
	end
	return false, "profile_busy"
end

function ProfileStore:_guarded(key, operation)
	local acquired, reason = self:_acquireGate(key)
	if not acquired then
		return false, reason
	end
	local ok, first, second = pcall(operation)
	self._gates[key] = nil
	if not ok then
		local entry = self._entries[key]
		if entry then
			entry.readOnly = true
		end
		return false, "adapter_error"
	end
	return true, first, second
end

-- Errors may have an unknown write outcome. Each operation's ID remains stable
-- across retries; its transform recognizes an already committed operation.
function ProfileStore:_update(key, transform)
	for attempt = 1, self._retries do
		local attemptNow = self:_now()
		if not attemptNow then
			return nil, "invalid_clock"
		end
		local rejection = nil
		local ok, result = pcall(function()
			return self._dataStore:UpdateAsync(key, function(current)
				local replacement, reason = transform(current, attemptNow)
				rejection = reason
				return replacement
			end)
		end)
		if ok then
			if result == nil then
				return nil, rejection or "update_cancelled"
			end
			local valid, reason = self:_recordValid(result)
			if not valid then
				return nil, reason
			end
			return result
		end
		if attempt < self._retries then
			self._sleep(self._retryDelay * (2 ^ (attempt - 1)))
		end
	end
	return nil, "data_store_unavailable"
end

function ProfileStore:load(userId, createProfileFn)
	local key = keyFor(userId)
	if not key then
		return nil, "invalid_user_id"
	end
	if type(createProfileFn) ~= "function" then
		return nil, "profile_factory_required"
	end
	local entered, profile, reason = self:_guarded(key, function()
		local existing = self._entries[key]
		if existing then
			if self:isWritable(userId) then
				return existing.profile
			end
			return nil, "profile_read_only"
		end
		local operationId = self:_operationId(key, "load")
		-- Construct outside UpdateAsync: callbacks must never create side effects.
		local created, candidate = pcall(createProfileFn)
		if not created then
			return nil, "profile_factory_failed"
		end
		local defaultProfile, defaultReason = self:_snapshot(candidate, userId)
		if not defaultProfile then
			return nil, defaultReason
		end
		local result, updateReason = self:_update(key, function(current, now)
			if current == nil then
				return {
					schemaVersion = RECORD_VERSION,
					profile = copy(defaultProfile),
					lease = { owner = self._owner, expiresAt = now + self._leaseSeconds },
					revision = 1,
					lastOperationId = operationId,
				}
			end
			local valid, recordReason, migratedProfile = self:_recordValid(current, userId, true)
			if not valid then
				return nil, recordReason
			end
			local lease = current.lease
			if lease and lease.owner ~= self._owner and lease.expiresAt > now then
				return nil, "session_locked"
			end
			if current.lastOperationId == operationId and lease and lease.expiresAt > now then
				return current
			end
			return {
				schemaVersion = RECORD_VERSION,
				profile = migratedProfile,
				lease = { owner = self._owner, expiresAt = now + self._leaseSeconds },
				revision = current.revision + 1,
				lastOperationId = operationId,
			}
		end)
		if not result then
			return nil, updateReason
		end
		local now = self:_now()
		if not now or not result.lease or result.lease.owner ~= self._owner
			or result.lastOperationId ~= operationId
			or now >= result.lease.expiresAt - self._safetyMargin then
			return nil, "lease_not_confirmed"
		end
		local loaded, loadReason = self:_snapshot(result.profile, userId)
		if not loaded then
			return nil, loadReason
		end
		self._entries[key] = {
			userId = userId,
			profile = loaded,
			revision = result.revision,
			leaseExpiresAt = result.lease.expiresAt,
			readOnly = false,
			lost = false,
			closing = false,
			invalidated = false,
		}
		return loaded
	end)
	if not entered then
		return nil, profile
	end
	return profile, reason
end

function ProfileStore:get(userId)
	local key = keyFor(userId)
	local entry = key and self._entries[key]
	return entry and entry.profile or nil
end

function ProfileStore:isWritable(userId)
	local key = keyFor(userId)
	local entry = key and self._entries[key]
	if not entry or entry.readOnly or entry.lost or entry.closing or entry.invalidated then
		return false
	end
	local now = self:_now()
	return now ~= nil and now < entry.leaseExpiresAt - self._safetyMargin
end

-- Quarantine a possibly partially mutated profile after a simulation exception.
-- Do not persist it, release its lock, or restore writable defaults. A write
-- already in flight holds its own pre-invalidation snapshot and may complete;
-- it can never make this entry writable again. The saved lease expires normally.
function ProfileStore:invalidate(userId)
	local key = keyFor(userId)
	if not key then
		return false, "invalid_user_id"
	end
	local entry = self._entries[key]
	if not entry then
		return false, "profile_not_loaded"
	end
	entry.invalidated = true
	entry.readOnly = true
	entry.lost = true
	entry.closing = true
	return true
end

function ProfileStore:_saveLocked(key, releasing)
	local entry = self._entries[key]
	if not entry then
		if releasing then
			return true -- Idempotent duplicate PlayerRemoving/BindToClose release.
		end
		return false, "profile_not_loaded"
	end
	if releasing then
		entry.closing = true
	end
	if entry.invalidated then
		return false, "profile_invalidated"
	end
	if entry.lost then
		return false, "lease_lost"
	end
	if entry.closing and not releasing then
		return false, "profile_closing"
	end
	local now = self:_now()
	if not now then
		entry.readOnly = true
		return false, "invalid_clock"
	end
	if now >= entry.leaseExpiresAt then
		entry.readOnly = true
		entry.lost = true
		return false, "lease_expired"
	end
	-- Capture AFTER acquiring the per-key gate, so release cannot queue an older
	-- snapshot behind an autosave while gameplay advances the in-memory profile.
	local snapshot, reason = self:_snapshot(entry.profile, entry.userId)
	if not snapshot then
		entry.readOnly = true
		return false, reason
	end
	local expectedRevision = entry.revision
	local operationId = self:_operationId(key, releasing and "release" or "save")
	local result, updateReason = self:_update(key, function(current, attemptNow)
		if current == nil then
			return nil, "record_missing"
		end
		local valid, recordReason = self:_recordValid(current, entry.userId)
		if not valid then
			return nil, recordReason
		end
		-- A release may have committed before its response was lost.
		if releasing and current.lastOperationId == operationId and current.lease == nil then
			return current
		end
		local lease = current.lease
		if not lease or lease.owner ~= self._owner then
			return nil, "lease_lost"
		end
		if lease.expiresAt <= attemptNow then
			return nil, "lease_expired"
		end
		if current.lastOperationId == operationId then
			return current
		end
		if current.revision ~= expectedRevision then
			return nil, "revision_conflict"
		end
		return {
			schemaVersion = RECORD_VERSION,
			profile = copy(snapshot),
			lease = not releasing and { owner = self._owner, expiresAt = attemptNow + self._leaseSeconds } or nil,
			revision = current.revision + 1,
			lastOperationId = operationId,
		}
	end)
	if not result then
		entry.readOnly = true
		if updateReason == "lease_lost" or updateReason == "lease_expired"
			or updateReason == "revision_conflict" or updateReason == "record_missing" then
			entry.lost = true
		end
		return false, updateReason
	end
	if result.lastOperationId ~= operationId then
		entry.readOnly = true
		entry.lost = true
		return false, "write_not_confirmed"
	end
	if releasing then
		if result.lease ~= nil then
			entry.readOnly = true
			entry.lost = true
			return false, "release_not_confirmed"
		end
		self._entries[key] = nil
		return true
	end
	local confirmedNow = self:_now()
	if not confirmedNow or not result.lease or result.lease.owner ~= self._owner
		or confirmedNow >= result.lease.expiresAt then
		entry.readOnly = true
		entry.lost = true
		return false, "lease_not_confirmed"
	end
	entry.revision = result.revision
	entry.leaseExpiresAt = result.lease.expiresAt
	entry.readOnly = entry.invalidated
	return true
end

function ProfileStore:save(userId)
	local key = keyFor(userId)
	if not key then
		return false, "invalid_user_id"
	end
	local entered, ok, reason = self:_guarded(key, function()
		return self:_saveLocked(key, false)
	end)
	if not entered then
		return false, ok
	end
	return ok, reason
end

function ProfileStore:release(userId)
	local key = keyFor(userId)
	if not key then
		return false, "invalid_user_id"
	end
	local entry = self._entries[key]
	if entry then
		-- Freeze gameplay immediately, even while waiting for an autosave's gate.
		entry.closing = true
	end
	local entered, ok, reason = self:_guarded(key, function()
		return self:_saveLocked(key, true)
	end)
	if not entered then
		return false, ok
	end
	return ok, reason
end

return ProfileStore

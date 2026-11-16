--!nonstrict
-- Fixed server-configured Studio admission. NOT a live Teleport router.
local runtimeScript=rawget(getfenv(),"script")
local Island=if runtimeScript then require(runtimeScript.Parent.PersonalIsland) else require("./PersonalIsland")
local Session={}
function Session.new(expectedOwner,studio,memory)
	assert(studio==true and memory==true,"Island QA requires Studio memory mode")
	assert(Island.validOwner(expectedOwner,true),"Configure the QA owner before Play")
	local self={ownerUserId=expectedOwner,islandId=Island.identity(expectedOwner),generation=0,current=nil}
	function self:admit(userId,actor)
		if userId~=self.ownerUserId or actor==nil then return nil,"not_island_owner" end
		if self.current then
			if self.current.actor==actor then return self.current end
			return nil,"owner_session_busy"
		end
		self.generation+=1
		local token={islandId=self.islandId,ownerUserId=self.ownerUserId,generation=self.generation,actor=actor,phase="loading"}
		self.current=token
		return token
	end
	function self:matches(actor,token,phase)
		return token~=nil and self.current==token and token.actor==actor
			and token.generation==self.generation and (phase==nil or token.phase==phase)
	end
	function self:activate(actor,token,profileUserId)
		if not self:matches(actor,token,"loading") or profileUserId~=self.ownerUserId then return false end
		token.phase="active"; return true
	end
	function self:release(actor,token)
		if not self:matches(actor,token) then return false end
		token.phase="closed";self.current=nil;return true
	end
	return self
end
return Session

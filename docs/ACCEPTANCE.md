# Manual acceptance checklist

CLI/CI passing is necessary but does not mark any item below as completed.

## Studio greybox (memory mode)

- [ ] Open the generated place; Output has no script errors.
- [ ] HUD clearly says Studio progress is not persisted after Stop.
- [ ] Start Server with 2 clients: separate plots and separate balances (negative Studio UserIds supported).
- [ ] Walk onto own upgrade pad: exactly one intended purchase; insufficient Gold does not build anything.
- [ ] Visit another plot: all economic interactions are refused; public worker visuals remain visible.
- [ ] Click crystal; collect Mandrake; manually load and brew Healing; exactly one sale credited.
- [ ] Enable automation only after first successful manual recipe, with a brewer assigned.
- [ ] Assign/unassign workers: no simultaneous workplace assignment, original versus capped skill visible.
- [ ] Upgrade crystal; run autonomous Healing with farmer, carrier and brewer.
- [ ] Earn Gold, hire extra workers, unlock mine/distillery/Rage and complete the two-stage production chain.
- [ ] Full raw storage does not prevent a loaded ordinary potion from exporting.
- [ ] Discard requires confirmation; cannot discard quest stock through the ingredient control.
- [ ] Carrier with cargo pauses when removed and resumes without duplication when assigned again.
- [ ] Complete and claim a contract; repeated claim does not award twice; extras export.
- [ ] Test expiration of a contract and ordinary sale of its reserved output.
- [ ] Pipes move liquid intermediates but do not bypass solid transport.

## Real save / catch-up (isolated private QA experience)

- [ ] Set Studio memory mode false only in a separately published QA experience.
- [ ] Leave/rejoin: balances, workers, jobs, cargo, inputs and recipe discoveries survive.
- [ ] Offline production matches configured sources/transport/recipes; no duplicate gold for reserved potions.
- [ ] Rejoin repeatedly/open the welcome UI: no duplicate catch-up and no new slime rolls for the same interval.
- [ ] Test a gap longer than two hours; excess time is not collectable by another reconnect.
- [ ] Rapid reconnect/server change cannot run two writable sessions for the same profile.
- [ ] API access disabled or backend error: no writable fresh fallback and no overwrite of real data.
- [ ] Server shutdown saves active profiles; interrupted/unconfirmed saves fail closed and eventually recover from the last valid record.
- [ ] Future/malformed schema in a disposable QA key is rejected; it is not reset automatically.

## Mobile and scale

- [ ] Device emulator at narrow portrait and landscape sizes: text readable, buttons reachable, scrolling works.
- [ ] Real phone: joystick/camera remain usable when the factory menu is closed.
- [ ] Station → assign → choose worker works with touch; a closed menu does not intercept input.
- [ ] Eight-client max-load scenario: measure frame time, server step time, replication, memory and catch-up duration.
- [ ] Repeated respawns and join/leave cycles do not duplicate UI, plots or familiar visual instances.

**Public release remains blocked** until real-backend, mobile and multiplayer acceptance is recorded. Paid purchases/trading also require their own later security and policy gates.

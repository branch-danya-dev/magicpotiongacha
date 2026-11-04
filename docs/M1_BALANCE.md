# M1 economy traces — 2026-11-04

Reproduce with `npm test` (three `ECONOMY` lines in `build/verification.log`).
`tests/Scenarios.luau` starts with **0 Gold / 0 Essence / no ingredients**, the
three fixed starter workers, and uses real Protocol/Factory intents. There is no
seeded currency, discovery, equipment or tutorial reward in these scenarios.
The seeded production RNG uses Studio identity `-1`. Every intent advances one
simulated second; movement, touch interaction and network latency are excluded.
These are deterministic design probes, **not player retention or playtest data**.

| Strategy | First sale | Passive factory configured | First NPC claim | Intents | Crystal clicks | Manual harvests | Gold at claim | Gold over next autonomous 600 s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Manual batches fund pipes and crystal | 19 s | 105 s | 181 s | 63 | 30 | 7 | 124 | 756 |
| Pipes early, auto-brew with clicking until crystal upgrade | 19 s | 120 s | 190 s | 114 | 100 | 3 | 110 | 742 |
| Spend 100 Gold on garden first, then recover by brewing | 19 s | 172 s | 256 s | 102 | 51 | 10 | 136 | 742 |

All three finish all ten saved tutorial facts and the 5-Healing NPC order, then
earn for ten minutes without another click or harvest. The last strategy
demonstrates recovery from spending before the recommended upgrade. Some tutorial
facts complete together (manual Healing and its automatic sale); facts already
completed out of order are skipped when choosing the next hint.

## Proposed initial values

- Keep Healing at 2 Mandrake + 3 Essence, 6 base seconds, 14 Gold. Assigned capped
  Brewing speeds the batch and retains the existing small double-output chance.
- Set pipes to **28 Gold**, down from the M0 late purchase of 650. This guarantees
  access after at most two ordinary Healing sales. A 24-unit tank and 2 units per
  machine per second give visible buffering without bypassing source production.
- Keep passive crystal level 2 at **140 Gold** and 1 Essence/second. Either manual
  brewing or click-assisted automation funds it. The traces suggest manual
  intervention can currently beat the early carrier: transport, not the brew
  timer, is the initial bottleneck. A real touch playtest should decide whether
  to shorten the two solid-haul legs; do not tune from elapsed CLI time alone.
- Keep initial Hauling cap 10: 3 solids/crates per pickup, 4 base work seconds and
  1.25 work/second with the starter slime. Quest queue capacity is 6 per machine;
  delivered quest capacity remains 100. The 5-crate / 600-second first order has
  margin in all traces. Larger orders exercise queue backpressure and fair routing.
- Keep three free fixed workers and existing guaranteed Gold hires. No gacha,
  paid rescue, additional currency or M2 progression is used.

## Sources, sinks and recovery

Gold comes from normal automatic exports, explicit one-time contract payment,
and ordinary-value export of completed crates at expiry. Matched crates do not
earn Gold before claim/expiry; quota excess sells normally. Gold buys stations,
upgrades, pipes, warehouse capacity and fixed workers. Essence comes only from
crystal clicks, the assigned crystal worker or passive crystal upgrades; loading
and pipes transfer it, while brewing consumes it. Ingredients come from manual
harvest, staffed sources and the existing deployed-slime production event.

Spending all Gold cannot prevent manual Healing income. Missing workers can be
reassigned for free; discovery never needs a worker. A full raw warehouse can
stall ingredient delivery (including excess byproduct slime during a long idle),
but it cannot block export of an already loaded ordinary potion. Explicit,
confirmed disposal and warehouse upgrades provide recovery. There is no silent
auto-discard. Empty Essence tanks pause batches, and empty crystal reserves need
clicks or passive generation. Switching recipes preserves loaded inputs or rejects
the switch until there is room to return them; the Essence tank is retained.
Unassignment keeps cargo; reconnect restores it; expiry settles it once. An
expired first contract can be accepted again without a penalty or paid item.

`telemetry.first` stores first brew/auto-brew/upgrade/contract/tutorial timestamps.
`telemetry.stalls[station][reason]` records bounded simulated idle seconds, including
offline seconds. These diagnostic fields never grant rewards and are not sent to
an external service or exposed in the public snapshot. They are simulation-time
observations, not measured device performance.

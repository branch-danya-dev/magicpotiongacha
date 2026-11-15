# Future cosmetic Idle selector — contract, not live code

Owner-approved behavior: independently choose `Idle_Calm` or `Idle_Active` after
each whole cycle, configurable equal weights (0.5 / 0.5), fade time 0.3 s.
This file does not enable or implement a selector in the current game.

1. After authorized asset upload/native rig QA, load exactly two AnimationTracks
   once per client-visible pet through its AnimationController/Animator. Both
   use Idle priority and Looped=true. Wait for successful delivery and positive
   Length before choosing an initial phase. Missing tracks fail closed to the
   neutral existing visual, with no loading/retry loop per frame.
2. Give every pet its own cosmetic RNG instance/seed and initial phase so pets
   spawned together do not animate in formation. Seeds must not control economy,
   grant decisions or persisted state. No new remotes or server draw per cycle.
3. Use the **current track's DidLoop** once per completed loop. Ignore callbacks
   from fading-out tracks and obsolete lifecycle generations. Sample normalized
   configurable weights once; default Calm if u<0.5, Active otherwise. Negative,
   non-finite or zero-sum configurations must reject/fall back to the defaults.
4. If the same clip is selected, let its loop continue; do not call Play again
   or reset TimePosition. Repeated Calm or Active is valid; 50/50 does not force
   alternation. No per-frame random decisions.
5. On a different result, start the next clip at phase zero with Play(0.3, 1, 1)
   and fade the previous one out with Stop(0.3). Keep only those two tracks.
   The outgoing track is allowed to wrap at the completed-cycle boundary while
   fading; this retains a full incoming cycle before its next selection. Verify
   actual native fade timing/weights at fixed and low frame rates after upload.
6. When Move/React begins, invalidate pending Idle callbacks and suppress new
   selections immediately. Fade both Idle weights out (~0.15 s) while the
   higher-priority Movement/Action animation takes control. These clips and the
   gameplay state source are future work, not part of this package. Returning to
   Idle chooses a new starting variant/phase; action completion is not a reward.
7. On pet removal, fallback, respawn or disposal, stop tracks, disconnect loop
   listeners and invalidate generation tokens; destroy the two loaded tracks.
   Do not create a new Animator or tracks on every cycle. Respect the game's
   future reduced-motion policy without changing pet work simulation.

Native acceptance must cover Calm→Calm, Calm→Active, Active→Active and
Active→Calm; interruption during both fades; removal/recreation; missing/denied
animation IDs; independent phases for multiple pets; no accumulated tracks or
connections; and no influence on authority/economy. All remain **NOT RUN**.

Roblox documents loop events, fade arguments, restarting behavior and
same-priority weight blending in
[AnimationTrack](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack).
These API capabilities support the proposed design; they do not substitute for
native verification of this rig and these exact asset permissions.

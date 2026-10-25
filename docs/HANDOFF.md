# VOIDSHIFT — Phase 3 Handoff

## Implemented (Phase 3 stabilization)

- **Keyboard gravity shifts**: Q/E/R (and invert R) now route through the real shift
  pipeline with RIG energy cost, cooldown and HUD feedback (`game_manager.gd`).
- **Analog input fidelity**: dead zone-zeroed movement actions and magnitude-preserving
  player movement, so physical joysticks no longer snap to full tilt (`project.godot`,
  `player.gd`).
- **Shift economy**: gravity shifts consume RIG energy (`GRAVITY_SHIFT_COST`), are vetoed
  when unaffordable, and the `energy_efficiency` upgrade (Superconductor Stacks, -35%
  cost/stack) is now consumed (`gravity_manager.gd`).
- **Persistent stats & metaprogression**: permanent `bonus_max_hp`/`bonus_move_speed`
  stats, purchased gravity upgrades, and kinetic plating (+25 HP/stack) apply from
  spawn initialization; upgrades install into every new run (`player.gd`,
  `game_manager.gd`, `loot_manager.gd`).
- **Enemy facing bugs**: Hitbox no longer zeroes its collision layer on ready
  (projectile damage routing restored); Walker shield uses a wall-relative 52.5°
  frontal arc with 0.28 damage scaling and no heal-hack on damage; Lurker ambush
  teleports are geometry-validated (no more stranding inside walls).
- **Meta loop fixes**: pause is blocked during VICTORY and restores prior state on
  resume; initial HUD readouts are deferred until listeners connect; end screens render
  above touch controls; touch shift buttons wire into the EventBus; audio manager gained
  `stop_all()` + exit cleanup; save writes are now atomic and corrupt-JSON tolerant;
  threat spawn counts scale with room difficulty (1-4 enemies) for pacing.
- **Test suite hardening**: rewritten headless suite — 89 assertions across 17 groups,
  including analog pass-through, shift cost/veto, permanent stats, corrupt save
  resilience, difficulty-scaled spawns, end-to-end shield/ambush physics regressions,
  initial readouts, and a **full sector run smoke** (generate → BFS walk all rooms via
  real transitions → clear threats → defeat boss → VICTORY persisted to save).

## Entry points

- Run startup: `scripts/core/game_manager.gd` → `scenes/world/test_sector.tscn` → `scripts/world/test_sector.gd`
- Room generation and transition: `scripts/world/dungeon_builder.gd`, `scripts/world/runtime_room.gd`, `scripts/world/room_base.gd`
- Enemies and boss: `scripts/enemies/sentry_drone.gd`, `scripts/enemies/sentry_walker.gd`, `scripts/enemies/phase_lurker.gd`, `scripts/enemies/aegis_core.gd`
- Hazards: `scripts/world/gravity_rail.gd`, `scripts/world/decompression_breach.gd`
- HUD and end screens: `scripts/ui/hud.gd`, `scripts/world/test_sector.gd`
- Regression suite: `scenes/tests/test_runner_scene.tscn`, `scripts/tests/test_runner.gd`

## Controls

Keyboard and touch controls remain as documented in `README.md`: move with WASD/arrow
keys or the virtual stick; gravity shift with Q/E/R or the touch buttons (now energy-
costed); fire with Space or Fire; dash with Shift or Dash; pause with Escape/P or Pause.
Use the open airlock at a room edge to continue.

## Validation

- Godot 4.3 headless integration suite: **89 passed, 0 failed** (17 groups).
- Runtime sector boot (`--quit-after 240`) and main-menu boot (`--quit-after 60`),
  headless: **exit 0, zero script errors**.
- On fresh checkouts run the editor import pass once before the suite
  (`godot --headless --import --path .`) so `.godot/global_script_class_cache.cfg`
  covers all `class_name` scripts (the cache is git-ignored).
- Residual "ObjectDB instances leaked / resources still in use" messages at exit are a
  Godot 4.3 headless audio driver limitation (`AudioStreamPlaybackWAV` never released on
  stop under the dummy driver). Verified with an isolated minimal repro; not a project leak.
- Godot's enemy gravity reorientation and boss phase thresholds have dedicated
  regression coverage in suite groups 9 and 10.

## Android build blockers (as of this handoff)

Local on-device building remains blocked (no export templates/SDK), but CI now covers
the build: `.github/workflows/android-apk.yml` produces a debug-installable APK on
every push to `master` and on manual runs.

**Artifact retrieval:**
1. Repo → **Actions** tab → select the latest **Android Debug Export** run.
2. The run summary lists an artifact named **`VoidShift-debug-apk`**.
3. Download it; the zip archive contains **`VoidShift.apk`** at its root.
   Sideload on a device after enabling unknown-app installs.
4. Manual re-build: **Actions → Android Debug Export → Run workflow** (branch `master`).
5. Artifacts are kept for **14 days**; failure logs (`import.log`, `test.log`,
   `export.log`) are uploaded for 7 days when a step fails.

**CI pipeline order:** checkout → JDK 17 + Android SDK (API 34, build-tools 34.0.0) →
fetch pinned Godot **4.3-stable** editor + matching templates (cached) → fresh debug
keystore → clean `--import` → regression suite (fails on any `[FAIL]`) → keystore
injection into the preset (CI-only, reverted before commit) → `--export-debug
"Android" build/VoidShift.apk` → artifact upload. Template/editor versions are pinned
together in the workflow `env` block and must be changed in lockstep.

## Known limits and next work

- Rooms use a compact repeated station layout with script-drawn floor details; visual
  variety and more room templates would benefit playtesting.
- Decoding precision for Walker/Lurker readability on real devices is still untested on
  touch hardware; balance numbers are internally coherent (80 DPS player, 3-shot drones,
  frontal-shielded walkers push flanking) but playtest-tunable.
- Verify touch control scale and edge reach on real landscape devices, then build the
  Android APK once export templates + SDK are available (see blockers above).
- The boss beam and breach damage use the shared `HealthComponent` directly; projectile
  damage continues through the shared hitbox/hurtbox path.


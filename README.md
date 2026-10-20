# How to Suck — 3D Android stealth game

A stylized 3D game made in Godot 4.4.1 for Android arm64.

## The night shift

Choose one of two locations from the start screen: a furnished apartment or a late-night shop. Each site has its own layout, furniture, collectibles, spills and camera positions. The job has three stages:

1. Find all five highlighted valuables scattered around the selected location.
2. Once the valuables are collected, clean all seven dirt stains.
3. Reach the front door and leave before the four-minute shift ends.

Security cameras sweep the rooms. Spending too long in a camera's field of view raises the alert meter; moving out of sight lets it cool down. The owners call after movement is detected or enough time has passed. Answering lowers suspicion and adds a small time bonus, while ignoring or declining the call raises suspicion. Maximum alert or an expired timer ends the shift.

## Controls

- Touch joystick: walk around the selected location.
- Action button: collect a valuable, clean a stain, or use the exit.
- Pause: resume or restart the shift.
- Movement also supports the keyboard arrow keys for desktop testing.

## Included content

- Two distinct 3D locations: a furnished apartment and a night shop with shelf aisles, checkout, coolers and a staff desk.
- The apartment has a kitchen, living room, bedroom, bathroom, window, props and lighting.
- Animated cleaner character, third-person follow camera and animated security cameras.
- Touch-first HUD, mission stages, countdown, camera-alert meter, phone-call choice, pause/restart and win/lose panels.
- Original apartment ambience, a separate night-market ambience, and gameplay sound effects.
- Cool fluorescent lighting in the shop aisles and a warmer pool of light at the checkout.
- Android landscape export preset and a headless smoke-test step before APK export.

## Android APK

GitHub Actions can create build/HowToSuck.apk and upload it as the How-to-Suck-Android-APK artifact. Before export, the workflow imports the game and runs headless gameplay/runtime tests; after export, it verifies the APK archive and ARM64 Godot library. The APK workflow is configured for pushes to main or an explicit manual dispatch. The separate game-completion branch uses validation-only CI and does not trigger an APK export.

All 3D objects are original meshes built by the project; no third-party art assets are required.

## Automated checks

The `game-completion` branch runs a separate validation workflow which does **not** export an APK. It checks referenced assets, imports the project in Godot, runs a short runtime smoke test, and exercises the complete mission loop (including phone choices and replay-related state). The Android APK workflow remains separate and is intentionally run only after the game has passed its readiness checks.

# How to Suck — 3D Android game

A stylized 3D stealth-cleaning game made with Godot 4.4.1. The initial playable build has a furnished apartment, third-person character, touch joystick, interaction button, collectible valuables, dirt spots, countdown, and a phone call from the owners.

## Gameplay
1. Start the night shift.
2. Explore and collect five highlighted valuables.
3. Clean seven dirt spots using the interaction button.
4. Answer the owners' call and finish before time runs out.

## Build
GitHub Actions exports `build/HowToSuck.apk` and uploads it as the `How-to-Suck-Android-APK` artifact. It runs on pushes to main or manually via Actions → Build Android APK → Run workflow.

All initial environment assets are generated from 3D meshes and materials in Godot; no external assets are required.


## Android APK

Download the latest Android build from [GitHub Releases](https://github.com/kirovo389-creator/How-to-suck/releases/latest). The APK is debug-signed for testing.

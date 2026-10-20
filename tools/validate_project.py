#!/usr/bin/env python3
"""Fast, dependency-free structural checks for the How to Suck Godot project."""
from __future__ import annotations

import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []
checks: list[str] = []


def require(condition: bool, message: str) -> None:
    if condition:
        checks.append(message)
    else:
        errors.append(message)


def text(path: str) -> str:
    file_path = ROOT / path
    if not file_path.is_file():
        errors.append(f"Missing required file: {path}")
        return ""
    return file_path.read_text(encoding="utf-8")


project = text("project.godot")
preset = text("export_presets.cfg")
workflow = text(".github/workflows/android.yml")
world = text("scripts/world_builder.gd")
game = text("scripts/game.gd")
hud = text("scripts/hud.gd")

require('config_version=5' in project, "Godot project version is declared")
require('run/main_scene="res://scenes/main.tscn"' in project, "Main scene points to the shipped scene")
require('config/icon="res://assets/app_icon.svg"' in project, "Custom application icon is assigned")
require('renderer/rendering_method="gl_compatibility"' in project, "Mobile-compatible renderer is selected")
require('name="Android"' in preset, "Android export preset exists")
require('architectures/arm64-v8a=true' in preset, "Android arm64 architecture is enabled")
require('screen/orientation=0' in preset, "Android display is landscape")
require('gradle_build/min_sdk=' not in preset and 'gradle_build/target_sdk=' not in preset,
        "Non-Gradle export does not override Gradle-only SDK settings")
require('sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-34" "build-tools;34.0.0"' in workflow,
        "Android SDK platform and build-tools versions are fixed")
require('"cmdline-tools;latest"' in workflow and '"cmake;3.10.2.4988404"' in workflow and
        '"ndk;23.2.8568313"' in workflow,
        "Godot Android export dependencies are installed explicitly")
require('export/android/android_sdk_path = "$ANDROID_HOME"' in workflow and
        'export/android/java_sdk_path = "$JAVA_HOME"' in workflow,
        "Godot editor receives Android SDK and Java paths")
require('GODOT_ANDROID_KEYSTORE_DEBUG_PATH:' in workflow and
        'GODOT_ANDROID_KEYSTORE_DEBUG_USER: androiddebugkey' in workflow and
        'GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD: android' in workflow,
        "APK export has a reproducible debug-signing keystore")
require('name: Verify APK archive and native library' in workflow and
        workflow.index('name: Verify APK archive and native library') > workflow.index('name: Export APK'),
        "APK integrity and ARM64 native library are checked before upload")
require('branches: [main]' in workflow and 'workflow_dispatch:' in workflow,
        "APK publishing workflow only runs on main or explicit manual dispatch")
require('name: Run headless game smoke test' in workflow and
        workflow.index('name: Run headless game smoke test') < workflow.index('name: Export APK'),
        "Runtime smoke test is scheduled before APK export")
require('loot_total: int = 5' in game and 'dirt_remaining: int = 7' in game,
        "Mission objective counts are defined")
require('func _scan_security_cameras()' in game and 'alert_level >= 100.0' in game,
        "Security camera detection and alert-loss state exist")
player = text("scripts/player.gd")
require('func play_interaction(kind: String)' in player and
        'func _update_interaction_animation(delta: float)' in player and
        'player.call("play_interaction", "loot")' in game and
        'player.call("play_interaction", "dirt")' in game,
        "Pickup and cleaning use timed character interaction animations")
camera = text("scripts/security_camera.gd")
require('func _build_vision_cone()' in camera and 'VisionCone' in camera and
        'BaseMaterial3D.TRANSPARENCY_ALPHA' in camera and
        'Color(1.0, 0.055, 0.035, 0.2)' in camera,
        "Security cameras expose a low-cost field-of-view that turns red on detection")
require('func _finish_cutscene()' in game and 'func _finish(success: bool' in game and
        'play_escape_cutscene' in game,
        "Opening and ending cinematics plus end-state logic exist")
require('world.process_mode = Node.PROCESS_MODE_DISABLED' in game and
        'world.process_mode = _world_process_mode_before_pause' in game and
        'music.stream_paused = true' in game and 'music.stream_paused = false' in game and
        'var tween := target.create_tween()' in game,
        "Pause freezes world animation, target-bound tweens and audio, then restores them on resume")
require('func unlock_exit()' in world and 'set_meta("kind", "exit")' in world,
        "Exit is gated behind the mission objective")
require('func _build_store_room()' in world and 'func _build_store_furniture()' in world and
        'level_id == "store"' in world,
        "Apartment and shop 3D layouts are available")
require('signal location_selected(location_id: String)' in hud and
        'func _choose_location(location_id: String)' in hud and
        'func _select_level(selected_level: String)' in game,
        "Start screen can change locations before the shift begins")
require('signal call_answered' in hud and 'signal cutscene_skipped' in hud and
        'signal restart_pressed' in hud,
        "Call choices, cutscene skip and replay signals are declared")

resource_sources = [ROOT / "project.godot"]
for folder in ("scripts", "scenes"):
    resource_sources.extend((ROOT / folder).rglob("*.gd"))
    resource_sources.extend((ROOT / folder).rglob("*.tscn"))
resource_sources.extend((ROOT / "tests").rglob("*.gd"))
resource_sources.extend([ROOT / "export_presets.cfg"])
references: set[str] = set()
for source in resource_sources:
    if source.is_file():
        contents = source.read_text(encoding="utf-8")
        references.update(re.findall(r"res://[A-Za-z0-9_./-]+", contents))
missing = sorted(ref for ref in references if not (ROOT / ref.removeprefix("res://")).is_file())
require(not missing, "All literal res:// references resolve" if not missing else
        "Missing resource references: " + ", ".join(missing))

audio_files = sorted((ROOT / "audio").glob("*.wav"))
require(len(audio_files) == 9, "Nine original WAV sound assets are present")
for audio_path in audio_files:
    data = audio_path.read_bytes()
    valid = len(data) >= 44 and data[:4] == b"RIFF" and data[8:12] == b"WAVE"
    if valid:
        audio_format, channels, sample_rate, byte_rate, block_align, bits = struct.unpack_from("<HHIIHH", data, 20)
        declared_size = struct.unpack_from("<I", data, 40)[0]
        valid = (audio_format == 1 and channels == 1 and sample_rate == 11025
                 and byte_rate == sample_rate * 2 and block_align == 2 and bits == 16
                 and declared_size == len(data) - 44)
    require(valid, f"Valid 16-bit PCM audio: audio/{audio_path.name}")

required_files = [
    "scenes/main.tscn", "scenes/player.tscn", "scenes/hud.tscn", "scenes/world.tscn",
    "scenes/security_camera.tscn", "scenes/owner.tscn", "scripts/owner.gd", "scripts/player.gd", "scripts/hud.gd",
    "scripts/world_builder.gd", "scripts/follow_camera.gd", "scripts/security_camera.gd",
    "scripts/loot_animation.gd", "tests/gameplay_smoke_test.gd", "assets/title_art.svg", "assets/app_icon.svg",
    "audio/ambience.wav", "audio/store_ambience.wav", "audio/pickup.wav", "audio/clean.wav", "audio/phone.wav",
    "audio/alert.wav", "audio/win.wav", "audio/lose.wav", "audio/click.wav",
]
for relative_path in required_files:
    require((ROOT / relative_path).is_file(), f"Required game asset exists: {relative_path}")

print(f"Project validation: {len(checks)} passed, {len(errors)} failed.")
for message in checks:
    print(f"  PASS  {message}")
for message in errors:
    print(f"  FAIL  {message}")
sys.exit(1 if errors else 0)

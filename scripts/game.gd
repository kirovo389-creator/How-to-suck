extends Node3D

const PlayerScene = preload("res://scenes/player.tscn")
const HudScene = preload("res://scenes/hud.tscn")
const OwnerScene = preload("res://scenes/owner.tscn")
const WorldScene = preload("res://scenes/world.tscn")
const MUSIC_STREAM = preload("res://audio/ambience.wav")
const STORE_MUSIC_STREAM = preload("res://audio/store_ambience.wav")
const SOUND_PICKUP = preload("res://audio/pickup.wav")
const SOUND_CLEAN = preload("res://audio/clean.wav")
const SOUND_PHONE = preload("res://audio/phone.wav")
const SOUND_ALERT = preload("res://audio/alert.wav")
const SOUND_WIN = preload("res://audio/win.wav")
const SOUND_LOSE = preload("res://audio/lose.wav")
const SOUND_CLICK = preload("res://audio/click.wav")

var player
var hud
var world
var level_id: String = "apartment"
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var loot_found: int = 0
var loot_total: int = 5
var dirt_remaining: int = 7
var time_left: float = 240.0
var alert_level: float = 0.0
var shift_started: bool = false
var paused: bool = false
var cutscene_playing: bool = false
var cutscene_elapsed: float = 0.0
var ended: bool = false
var call_shown: bool = false
var call_active: bool = false
var call_elapsed: float = 0.0
var call_response_elapsed: float = 0.0
var _camera_scan_elapsed: float = 0.0
var _status_elapsed: float = 0.0
var _camera_warning_shown: bool = false
var _camera_visible: bool = false
var _ending_cutscene_active: bool = false
var _ending_cutscene_elapsed: float = 0.0
var _pending_ending_success: bool = false
var _pending_ending_heading: String = ""
var _pending_ending_message: String = ""
var _pending_ending_seconds: int = 0
var _world_process_mode_before_pause: int = Node.PROCESS_MODE_INHERIT

func _ready() -> void:
    _lighting()
    world = WorldScene.instantiate()
    world.name = "Apartment"
    world.set("level_id", level_id)
    add_child(world)
    player = PlayerScene.instantiate()
    player.name = "Player"
    player.position = Vector3(0.0, 0.0, 2.8)
    add_child(player)
    player.set_physics_process(false)
    hud = HudScene.instantiate()
    add_child(hud)
    hud.action_pressed.connect(_on_action_pressed)
    hud.location_selected.connect(_select_level)
    hud.cutscene_skipped.connect(_skip_cutscene)
    hud.movement_changed.connect(player.set_mobile_direction)
    hud.call_answered.connect(_answer_call)
    hud.call_declined.connect(_decline_call)
    hud.pause_pressed.connect(_toggle_pause)
    hud.resume_pressed.connect(_resume_game)
    hud.restart_pressed.connect(_restart_game)
    music = AudioStreamPlayer.new()
    music.name = "AmbientMusic"
    music.stream = _music_for_level()
    music.volume_db = -22.0
    add_child(music)
    music.play()
    music.finished.connect(_loop_music)
    sfx = AudioStreamPlayer.new()
    sfx.name = "SoundEffects"
    sfx.volume_db = -3.0
    add_child(sfx)
    hud.show_intro()
    _refresh_status()

func _exit_tree() -> void:
    _stop_audio()

func _stop_audio() -> void:
    if is_instance_valid(music):
        music.stop()
        music.stream = null
    if is_instance_valid(sfx):
        sfx.stop()
        sfx.stream = null

func _select_level(selected_level: String) -> void:
    if shift_started or ended:
        return
    if selected_level != "apartment" and selected_level != "store":
        return
    if selected_level == level_id and is_instance_valid(world):
        return
    level_id = selected_level
    if is_instance_valid(world):
        world.free()
    world = WorldScene.instantiate()
    world.name = "Store" if level_id == "store" else "Apartment"
    world.set("level_id", level_id)
    add_child(world)
    if is_instance_valid(music):
        music.stream = _music_for_level()
        music.play()

func _music_for_level() -> AudioStream:
    return STORE_MUSIC_STREAM if level_id == "store" else MUSIC_STREAM

func _process(delta: float) -> void:
    if cutscene_playing:
        cutscene_elapsed += delta
        if cutscene_elapsed >= 4.6:
            _finish_cutscene()
        return
    if _ending_cutscene_active:
        _ending_cutscene_elapsed += delta
        if _ending_cutscene_elapsed >= 3.8:
            _finish_ending_cutscene()
        return
    if not shift_started or ended or paused:
        return
    time_left -= delta
    call_elapsed += delta
    # A phone dialogue locks movement and its overlay covers the joystick, so do not
    # punish the player for being unable to walk out of a camera's view during a call.
    if not call_active:
        _camera_scan_elapsed += delta
        if _camera_scan_elapsed >= 0.12:
            _camera_scan_elapsed = 0.0
            _scan_security_cameras()
        if _camera_visible:
            alert_level = minf(100.0, alert_level + (12.0 + float(loot_found) * 1.6) * delta)
        else:
            alert_level = maxf(0.0, alert_level - 8.0 * delta)
        if alert_level >= 32.0 and not _camera_warning_shown:
            _camera_warning_shown = true
            hud.toast("КАМЕРА ЗАМЕТИЛА ДВИЖЕНИЕ — СКРОЙСЯ!")
            _play_sound("alert")
    if not call_shown and (call_elapsed >= 62.0 or alert_level >= 42.0):
        call_shown = true
        call_active = true
        call_response_elapsed = 0.0
        player.set_mobile_direction(Vector2.ZERO)
        player.set_physics_process(false)
        hud.show_call("Управляющий магазина: «Камеры заметили движение. Я скоро вернусь. Ты ещё убираешь?»" if level_id == "store" else "Хозяева: «На камерах какое-то движение. Мы скоро вернёмся. Ты ещё убираешь?»")
        _play_sound("phone")
    if call_active:
        call_response_elapsed += delta
        if call_response_elapsed >= 10.0:
            call_active = false
            hud.hide_call()
            player.set_mobile_direction(Vector2.ZERO)
            player.set_physics_process(true)
            alert_level = minf(100.0, alert_level + 22.0)
            hud.toast("Звонок пропущен. Хозяева ускорили возвращение.")
            _play_sound("alert")
    if alert_level >= 100.0:
        _finish(false, "СИГНАЛИЗАЦИЯ", "Камеры раскрыли тебя. " + ("Управляющий магазина получил сигнал тревоги." if level_id == "store" else "Хозяева уже вызвали охрану."))
        return
    if time_left <= 0.0:
        _finish(false, "ВРЕМЯ ВЫШЛО", "Ты не успел закончить смену до возвращения " + ("управляющего магазина." if level_id == "store" else "хозяев."))
        return
    _status_elapsed += delta
    if _status_elapsed >= 0.15:
        _status_elapsed = 0.0
        _refresh_status()
        _refresh_action_hint()

func _lighting() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.012, 0.021, 0.055)
    sky_material.sky_horizon_color = Color(0.12, 0.15, 0.21)
    sky_material.ground_bottom_color = Color(0.025, 0.03, 0.045)
    sky_material.ground_horizon_color = Color(0.1, 0.12, 0.16)
    sky_material.energy_multiplier = 0.7
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.42, 0.46, 0.56)
    environment.ambient_light_energy = 0.72
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)
    var moonlight := DirectionalLight3D.new()
    moonlight.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
    moonlight.light_color = Color(0.68, 0.76, 1.0)
    moonlight.light_energy = 0.72
    moonlight.shadow_enabled = true
    moonlight.directional_shadow_max_distance = 38.0
    add_child(moonlight)
    var kitchen_light := OmniLight3D.new()
    kitchen_light.position = Vector3(-6.5, 3.1, -5.2)
    kitchen_light.light_color = Color(0.68, 0.79, 1.0)
    kitchen_light.light_energy = 0.42
    kitchen_light.omni_range = 7.5
    kitchen_light.shadow_enabled = false
    add_child(kitchen_light)
    var living_light := OmniLight3D.new()
    living_light.position = Vector3(1.7, 3.3, 1.6)
    living_light.light_color = Color(1.0, 0.72, 0.46)
    living_light.light_energy = 0.58
    living_light.omni_range = 8.0
    living_light.shadow_enabled = false
    add_child(living_light)
    var bedroom_light := OmniLight3D.new()
    bedroom_light.position = Vector3(7.3, 3.1, -5.0)
    bedroom_light.light_color = Color(0.66, 0.69, 1.0)
    bedroom_light.light_energy = 0.36
    bedroom_light.omni_range = 7.0
    bedroom_light.shadow_enabled = false
    add_child(bedroom_light)

func _finish_cutscene() -> void:
    var follow_camera: Node = world.get_node_or_null("FollowCamera")
    if is_instance_valid(follow_camera):
        follow_camera.call("cancel_opening_cutscene")
    cutscene_playing = false
    cutscene_elapsed = 0.0
    player.set_mobile_direction(Vector2.ZERO)
    player.set_physics_process(true)
    hud.hide_cutscene()
    hud.toast("Сначала собери 5 ценностей. Затем убери 7 пятен и выйди через дверь.")
    _refresh_status()
    _refresh_action_hint()

func _skip_cutscene() -> void:
    if cutscene_playing:
        _finish_cutscene()
    elif _ending_cutscene_active:
        _finish_ending_cutscene()

func _finish_ending_cutscene() -> void:
    if not _ending_cutscene_active:
        return
    _ending_cutscene_active = false
    _ending_cutscene_elapsed = 0.0
    var follow_camera: Node = world.get_node_or_null("FollowCamera")
    if is_instance_valid(follow_camera):
        follow_camera.call("cancel_cutscene")
    hud.hide_cutscene()
    hud.show_ending(_pending_ending_success, _pending_ending_heading, _pending_ending_message, _pending_ending_seconds, alert_level)

func _scan_security_cameras() -> void:
    _camera_visible = false
    for candidate in get_tree().get_nodes_in_group("security_cameras"):
        if not is_instance_valid(candidate):
            continue
        var can_see: bool = bool(candidate.call("can_see", player))
        candidate.call("set_alert_active", can_see)
        if can_see:
            _camera_visible = true

func _on_action_pressed() -> void:
    if ended or paused or call_active or cutscene_playing:
        return
    if not shift_started:
        shift_started = true
        cutscene_playing = true
        cutscene_elapsed = 0.0
        player.set_mobile_direction(Vector2.ZERO)
        player.set_physics_process(false)
        hud.hide_intro()
        hud.show_cutscene("01:13 — Магазин закрылся. У тебя четыре минуты: найди ценности, убери разливы и выйди до возвращения управляющего." if level_id == "store" else "01:13 — Хозяева уехали. У тебя четыре минуты: забери ценности, убери следы и выйди до их возвращения.")
        var follow_camera: Node = world.get_node_or_null("FollowCamera")
        if is_instance_valid(follow_camera):
            follow_camera.call("play_opening_cutscene")
        _play_sound("click")
        return
    var target := _nearest_interactable()
    if target == null:
        hud.toast("Подойди ближе к предмету, пятну или выходу.")
        _play_sound("click")
        return
    var kind: String = str(target.get_meta("kind", ""))
    if kind == "loot":
        player.call("play_interaction", "loot")
        var label := str(target.get_meta("label", "Ценность"))
        _remove_interactable(target)
        loot_found += 1
        hud.toast("%s — найдено %d из %d" % [label, loot_found, loot_total])
        _play_sound("pickup")
        if loot_found == loot_total:
            hud.set_task("Все ценности найдены. Теперь убери 7 пятен.")
        _refresh_status()
    elif kind == "dirt":
        if loot_found < loot_total:
            hud.toast("Сначала найди все 5 ценностей. Уборка — последний этап.")
            _play_sound("click")
            return
        player.call("play_interaction", "dirt")
        _remove_interactable(target)
        dirt_remaining -= 1
        hud.toast("Пятно убрано. Осталось: %d" % dirt_remaining)
        _play_sound("clean")
        if dirt_remaining <= 0:
            world.call("unlock_exit")
            hud.set_task("Магазин чистый. Доберись до зелёной двери и выйди." if level_id == "store" else "Квартира чистая. Доберись до зелёной двери и выйди.")
            hud.toast("Магазин убран. Выход открыт — доберись до двери." if level_id == "store" else "Квартира убрана. Выход открыт — доберись до двери.")
        _refresh_status()
    elif kind == "exit":
        if loot_found < loot_total or dirt_remaining > 0:
            if loot_found < loot_total:
                hud.toast("Нельзя уходить: найди ещё %d ценностей." % (loot_total - loot_found))
            else:
                hud.toast("Сначала убери ещё %d пятен." % dirt_remaining)
            return
        _finish(true, "СМЕНА ЗАВЕРШЕНА", "Ты нашёл ценности, убрал магазин и вышел до возвращения управляющего." if level_id == "store" else "Ты забрал ценности, убрал квартиру и ушёл до возвращения хозяев.")
    _refresh_action_hint()

func _remove_interactable(target: Node3D) -> void:
    # Remove immediately from interaction queries, then play a short shrink animation.
    target.remove_from_group("interactable")
    var tween := target.create_tween()
    tween.tween_property(target, "scale", Vector3(0.04, 0.04, 0.04), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    tween.tween_callback(target.queue_free)

func _nearest_interactable() -> Node3D:
    var best: Node3D
    var best_distance: float = 2.45
    for candidate in get_tree().get_nodes_in_group("interactable"):
        if not is_instance_valid(candidate) or not candidate is Node3D:
            continue
        var item := candidate as Node3D
        var distance: float = player.global_position.distance_to(item.global_position)
        if distance < best_distance:
            best = item
            best_distance = distance
    return best

func _refresh_action_hint() -> void:
    if not shift_started or ended:
        hud.set_action_hint("НАЧАТЬ СМЕНУ")
        return
    if call_active:
        hud.set_action_hint("ТЕЛЕФОН ЗВОНИТ")
        return
    var target := _nearest_interactable()
    if target == null:
        hud.set_action_hint("ВЗЯТЬ / МЫТЬ")
        return
    var kind := str(target.get_meta("kind", ""))
    if kind == "loot":
        hud.set_action_hint("ВЗЯТЬ: " + str(target.get_meta("label", "ЦЕННОСТЬ")).to_upper())
    elif kind == "dirt":
        hud.set_action_hint("УБРАТЬ ПЯТНО" if loot_found >= loot_total else "СНАЧАЛА ЦЕННОСТИ")
    elif kind == "exit":
        hud.set_action_hint("ВЫЙТИ" if loot_found >= loot_total and dirt_remaining == 0 else "ВЫХОД ЗАКРЫТ")
    else:
        hud.set_action_hint("ВЗАИМОДЕЙСТВИЕ")

func _answer_call() -> void:
    if not call_active:
        return
    call_active = false
    hud.hide_call()
    player.set_mobile_direction(Vector2.ZERO)
    player.set_physics_process(true)
    alert_level = maxf(0.0, alert_level - 24.0)
    time_left = minf(240.0, time_left + 8.0)
    hud.toast("Ты успокоил хозяев. Тревога снизилась, но время продолжает идти.")
    _play_sound("click")
    _refresh_status()

func _decline_call() -> void:
    if not call_active:
        return
    call_active = false
    hud.hide_call()
    player.set_mobile_direction(Vector2.ZERO)
    player.set_physics_process(true)
    alert_level = minf(100.0, alert_level + 18.0)
    hud.toast("Ты сбросил звонок. Подозрения выросли.")
    _play_sound("alert")
    _refresh_status()

func _toggle_pause() -> void:
    if not shift_started or ended:
        return
    if paused:
        _resume_game()
    else:
        paused = true
        player.set_mobile_direction(Vector2.ZERO)
        player.set_physics_process(false)
        if is_instance_valid(world):
            _world_process_mode_before_pause = world.process_mode
            world.process_mode = Node.PROCESS_MODE_DISABLED
        if is_instance_valid(music):
            music.stream_paused = true
        if is_instance_valid(sfx):
            sfx.stream_paused = true
        hud.show_pause(true)

func _resume_game() -> void:
    paused = false
    if is_instance_valid(world):
        world.process_mode = _world_process_mode_before_pause
    if is_instance_valid(music):
        music.stream_paused = false
    if is_instance_valid(sfx):
        sfx.stream_paused = false
    hud.show_pause(false)
    player.set_mobile_direction(Vector2.ZERO)
    player.set_physics_process(true)

func _restart_game() -> void:
    get_tree().reload_current_scene()

func _finish(success: bool, heading: String, message: String) -> void:
    if ended:
        return
    ended = true
    paused = false
    cutscene_playing = false
    call_active = false
    player.set_mobile_direction(Vector2.ZERO)
    player.set_physics_process(false)
    hud.hide_cutscene()
    hud.hide_call()
    hud.show_pause(false)
    var seconds_left := int(maxf(0.0, time_left))
    _pending_ending_success = success
    _pending_ending_heading = heading
    _pending_ending_message = message
    _pending_ending_seconds = seconds_left
    _ending_cutscene_active = true
    _ending_cutscene_elapsed = 0.0
    var follow_camera: Node = world.get_node_or_null("FollowCamera")
    if success:
        if is_instance_valid(follow_camera):
            follow_camera.call("play_escape_cutscene")
        hud.show_cutscene("Ты выходишь в ночной двор. За спиной закрывается дверь — смена завершена.")
        _play_sound("win")
        if is_instance_valid(music):
            music.volume_db = -30.0
        return
    # On failure, let the owner physically return to the apartment before the results panel.
    var owner_actor := OwnerScene.instantiate() as Node3D
    owner_actor.name = "ReturningManager" if level_id == "store" else "ReturningOwner"
    owner_actor.position = Vector3(0.0, 0.0, 9.35)
    add_child(owner_actor)
    owner_actor.call("set_target", player)
    if is_instance_valid(follow_camera):
        follow_camera.call("play_return_cutscene", owner_actor)
    hud.show_cutscene("Щёлкнул замок… Управляющий магазина вернулся. Ночную смену пора заканчивать." if level_id == "store" else "Щёлкнул замок… Хозяева вернулись. Ночную смену пора заканчивать.")
    _play_sound("lose")
    if is_instance_valid(music):
        music.volume_db = -26.0

func _refresh_status() -> void:
    if is_instance_valid(hud):
        hud.update_status(loot_found, loot_total, dirt_remaining, int(maxf(0.0, time_left)), alert_level, shift_started)

func _play_sound(sound_name: String) -> void:
    if not is_instance_valid(sfx):
        return
    var streams := {
        "pickup": SOUND_PICKUP,
        "clean": SOUND_CLEAN,
        "phone": SOUND_PHONE,
        "alert": SOUND_ALERT,
        "win": SOUND_WIN,
        "lose": SOUND_LOSE,
        "click": SOUND_CLICK
    }
    if streams.has(sound_name):
        sfx.stream = streams[sound_name]
        sfx.play()

func _loop_music() -> void:
    if is_instance_valid(music) and not ended:
        music.play()

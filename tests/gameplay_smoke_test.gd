extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var main: Node = MainScene.instantiate()
    root.add_child(main)
    current_scene = main
    await process_frame

    _check(main.has_method("_on_action_pressed"), "main gameplay script loaded")
    _check(main.has_method("_has_interaction_line_of_sight"), "interactions require a clear line of sight")
    var player := main.get("player") as Node3D
    var world := main.get("world") as Node3D
    if not is_instance_valid(player) or not is_instance_valid(world):
        _check(false, "player and 3D apartment initialized")
        await _cleanup_and_quit(main, 1)
        return
    _check(world.get_node_or_null("FollowCamera") is Camera3D, "follow camera exists")
    var initial_player_position := player.global_position
    var existing_interactables := get_nodes_in_group("interactable")
    for item in existing_interactables:
        if is_instance_valid(item):
            item.remove_from_group("interactable")
    var test_wall := StaticBody3D.new()
    test_wall.name = "InteractionOcclusionTestWall"
    test_wall.position = Vector3(-7.0, 1.0, 0.0)
    var test_wall_collision := CollisionShape3D.new()
    var test_wall_shape := BoxShape3D.new()
    test_wall_shape.size = Vector3(0.5, 2.4, 3.0)
    test_wall_collision.shape = test_wall_shape
    test_wall.add_child(test_wall_collision)
    world.add_child(test_wall)
    var probe_target := Node3D.new()
    probe_target.name = "OccludedInteractionProbe"
    probe_target.position = Vector3(-6.0, 1.45, 0.0)
    probe_target.set_meta("kind", "loot")
    world.add_child(probe_target)
    probe_target.add_to_group("interactable")
    player.global_position = Vector3(-8.0, 0.0, 0.0)
    await physics_frame
    _check(not bool(main.call("_has_interaction_line_of_sight", probe_target)),
        "a wall blocks direct interaction with a hidden object")
    _check(main.call("_nearest_interactable") == null,
        "nearest-interactable refuses objects behind a wall")
    probe_target.position = Vector3(-8.85, 1.45, 0.0)
    await physics_frame
    _check(bool(main.call("_has_interaction_line_of_sight", probe_target)),
        "clear sight restores object interaction")
    _check(main.call("_nearest_interactable") == probe_target,
        "a nearby unobstructed object can be selected")
    for item in existing_interactables:
        if is_instance_valid(item):
            item.add_to_group("interactable")
    probe_target.queue_free()
    test_wall.queue_free()
    player.global_position = initial_player_position
    await process_frame
    var exit_target := world.get_node_or_null("ExitInteraction") as Node3D
    if not is_instance_valid(exit_target):
        _check(false, "exit interaction exists")
        await _cleanup_and_quit(main, 1)
        return

    var hud := main.get("hud") as CanvasLayer
    var hud_root := hud.get("_root") as Control
    _check(hud_root.get_node_or_null("CrouchButton") is Button, "mobile HUD exposes the crouch control")
    _check(hud_root.get_node_or_null("SprintButton") is Button, "mobile HUD exposes the sprint control")
    _check(hud.has_signal("sprint_pressed"), "HUD emits sprint input")
    _check(main.has_method("_toggle_sprint"), "game handles sprint activation")
    _check(player.has_method("set_sprinting"), "player supports sprint movement")
    hud.call("_choose_location", "store")
    await process_frame
    world = main.get("world") as Node3D
    _check(str(world.get("level_id")) == "store", "intro can switch to the shop level")
    var background_music := main.get("music") as AudioStreamPlayer
    _check(background_music.stream == load("res://audio/store_ambience.wav"), "shop uses its own ambient sound")
    _check(world.get_node_or_null("AisleLight0") is OmniLight3D, "shop has dedicated aisle lighting")
    var security_cameras := get_nodes_in_group("security_cameras")
    _check(security_cameras.size() == 3, "shop has three active security cameras")
    if not security_cameras.is_empty():
        var first_camera := security_cameras[0] as Node3D
        var vision_cone := first_camera.get_node_or_null("CameraHead/VisionCone") as MeshInstance3D
        # VisionCone is parented to the moving head, so its footprint follows the sweep.
        if not is_instance_valid(vision_cone):
            vision_cone = first_camera.find_child("VisionCone", true, false) as MeshInstance3D
        _check(is_instance_valid(vision_cone), "security camera shows a floor field-of-view")
        var vision_material := first_camera.get("_vision_material") as StandardMaterial3D
        _check(is_instance_valid(vision_material), "camera vision indicator has a mobile-friendly material")
        if is_instance_valid(vision_material):
            first_camera.call("set_alert_active", true)
            _check(vision_material.albedo_color.r > 0.8 and vision_material.albedo_color.g < 0.2,
                "camera vision field turns red when detecting the player")
            first_camera.call("set_alert_active", false)
            _check(vision_material.albedo_color.b > 0.7 and vision_material.albedo_color.r < 0.3,
                "camera vision field returns to blue when safe")
    _check(_count_kind("loot") == 5, "shop level has five valuables")
    _check(_count_kind("dirt") == 7, "shop level has seven spills")
    # Complete an entire shop shift first, not just a resource-count check.
    var shop_hud := main.get("hud") as CanvasLayer
    main.set("call_active", true)
    main.set("alert_level", 30.0)
    main.call("_answer_call")
    _check((shop_hud.get("_toast_label") as Label).text.contains("управляющего"),
        "shop phone answer names the manager")
    main.set("time_left", 240.0)
    main.set("alert_level", 0.0)
    main.set("shift_started", true)
    main.set("call_active", true)
    main.set("call_response_elapsed", 9.9)
    main.set("call_elapsed", 0.0)
    main.call("_process", 0.2)
    _check((shop_hud.get("_toast_label") as Label).text.contains("Управляющий"),
        "missed shop call names the manager")
    main.set("shift_started", false)
    main.set("alert_level", 0.0)
    main.set("time_left", 240.0)
    main.set("call_active", false)
    main.set("call_shown", false)
    main.set("call_response_elapsed", 0.0)
    main.set("call_elapsed", 0.0)
    main.call("_on_action_pressed")
    _check(bool(main.get("shift_started")), "shop shift starts from the intro")
    var store_opening_text := (hud.get("_cutscene_label") as Label).text
    _check(store_opening_text.contains("Магазин"), "shop opening cinematic uses the shop story")
    main.call("_skip_cutscene")
    await process_frame
    var shop_player_for_animation := main.get("player") as Node3D
    _check(shop_player_for_animation.has_method("play_interaction"), "player has dedicated pickup and cleaning animations")
    var shop_arms: Array = shop_player_for_animation.get("_arms")
    var broom_arm := shop_arms[1] as Node3D
    var broom_arm_rotation_before := broom_arm.rotation.x
    shop_player_for_animation.call("play_interaction", "dirt")
    _check(bool(shop_player_for_animation.call("is_interacting")), "cleaning animation starts on interaction")
    shop_player_for_animation.call("_update_interaction_animation", 0.1)
    _check(not is_equal_approx(broom_arm.rotation.x, broom_arm_rotation_before),
        "cleaning animation moves the arm holding the broom")
    await create_timer(0.72).timeout
    _check(not bool(shop_player_for_animation.call("is_interacting")), "interaction animation returns to the idle pose")
    await _complete_objectives(main)
    _check((shop_hud.get("_toast_label") as Label).text.contains("Магазин"), "shop cleanup uses shop-specific text")
    world = main.get("world") as Node3D
    exit_target = world.get_node_or_null("ExitInteraction") as Node3D
    _check(bool(exit_target.get_meta("unlocked", false)), "shop exit opens after every objective")
    await create_timer(0.7).timeout
    var shop_player := main.get("player") as Node3D
    shop_player.global_position = exit_target.global_position
    main.call("_on_action_pressed")
    _check(bool(main.get("ended")), "shop mission completes at the exit")
    _check(bool(main.get("_ending_cutscene_active")), "shop escape starts its ending cinematic")
    main.call("_skip_cutscene")
    await process_frame
    var shop_ending_overlay := shop_hud.get("_ending_overlay") as Control
    _check(is_instance_valid(shop_ending_overlay) and shop_ending_overlay.visible, "shop results panel appears")

    # Load a new run so apartment tests begin with untouched collectibles and timer.
    current_scene = null
    main.queue_free()
    await process_frame
    main = MainScene.instantiate()
    root.add_child(main)
    current_scene = main
    await process_frame
    player = main.get("player") as Node3D
    world = main.get("world") as Node3D
    exit_target = world.get_node_or_null("ExitInteraction") as Node3D
    hud = main.get("hud") as CanvasLayer
    hud_root = hud.get("_root") as Control
    background_music = main.get("music") as AudioStreamPlayer
    _check(str(world.get("level_id")) == "apartment", "fresh shift starts in the apartment")
    _check(background_music.stream == load("res://audio/ambience.wav"), "apartment ambience is restored")
    _check(_count_kind("loot") == 5 and _count_kind("dirt") == 7, "fresh apartment objectives are intact")
    main.set("time_left", 180.0)
    main.set("alert_level", 30.0)
    main.set("call_active", true)
    hud.call("show_call", "Тест звонка")
    main.call("_answer_call")
    _check(not bool(main.get("call_active")), "answering the phone closes the call")
    _check(int(main.get("time_left")) == 188, "answering the phone grants the time bonus")
    _check(int(main.get("alert_level")) == 6, "answering the phone lowers suspicion")
    main.set("call_active", true)
    main.set("alert_level", 12.0)
    hud.call("show_call", "Тест звонка")
    main.call("_decline_call")
    _check(not bool(main.get("call_active")), "declining the phone closes the call")
    _check(int(main.get("alert_level")) == 30, "declining the phone raises suspicion")
    # Movement is allowed only after the shift has started.
    main.set("shift_started", true)
    main.call("_sync_player_processing")
    # Test movement in an open hallway, not next to the coffee-table collider.
    player.global_position = Vector3(-7.0, 0.0, 0.0)
    var player_start := player.global_position
    player.set_mobile_direction(Vector2.RIGHT)
    await physics_frame
    await physics_frame
    player.set_mobile_direction(Vector2.ZERO)
    _check(player.global_position.x > player_start.x + 0.01, "virtual joystick moves the player")
    main.set("shift_started", false)
    main.call("_sync_player_processing")

    # Return the game to a clean initial state after isolated phone-choice checks.
    main.set("alert_level", 0.0)
    main.set("time_left", 240.0)
    main.set("call_elapsed", 0.0)
    main.set("call_response_elapsed", 0.0)
    main.set("call_active", false)
    main.set("call_shown", false)
    main.set("_camera_visible", false)
    main.set("_camera_warning_shown", false)

    var loot: Array[Node3D] = []
    var dirt: Array[Node3D] = []
    for candidate in get_nodes_in_group("interactable"):
        if not (candidate is Node3D):
            continue
        var item := candidate as Node3D
        var kind := str(item.get_meta("kind", ""))
        if kind == "loot":
            loot.append(item)
        elif kind == "dirt":
            dirt.append(item)
    _check(loot.size() == 5, "five valuables are placed")
    _check(dirt.size() == 7, "seven stains are placed")

    main.call("_on_action_pressed")
    _check(bool(main.get("shift_started")), "shift starts from the intro")
    _check((hud.get("_cutscene_label") as Label).text.contains("Хозяева"), "apartment opening cinematic uses the apartment story")
    var cinematic_time_before_pause: float = float(main.get("cutscene_elapsed"))
    main.call("_toggle_pause")
    await create_timer(0.24).timeout
    _check(is_equal_approx(float(main.get("cutscene_elapsed")), cinematic_time_before_pause),
        "pause freezes the opening cinematic")
    main.call("_resume_game")
    _check(not player.is_physics_processing(), "resume during opening cinematic keeps player controls locked")
    main.call("_skip_cutscene")
    _check(not bool(main.get("cutscene_playing")), "opening cinematic can be skipped")
    _check(player.is_physics_processing(), "player controls unlock after opening cinematic")
    player.global_position = Vector3(-7.0, 0.0, 0.0)
    player.set_mobile_direction(Vector2.RIGHT)
    main.call("_toggle_sprint")
    _check(bool(player.get("is_sprinting")), "sprint toggles on")
    _check(float(player.get("move_speed")) > 4.0, "sprint increases player speed")
    await physics_frame
    await physics_frame
    _check(bool(player.get("is_moving")), "player movement state updates before sprint stamina is measured")
    var stamina_bar := hud.get("_stamina_bar") as ProgressBar
    _check(is_instance_valid(stamina_bar), "HUD has a live stamina progress bar")
    var stamina_before_sprint: float = float(main.get("stamina"))
    main.call("_process", 0.25)
    _check(float(main.get("stamina")) < stamina_before_sprint, "moving while sprinting drains stamina")
    _check(is_instance_valid(stamina_bar) and is_equal_approx(stamina_bar.value, float(main.get("stamina"))),
        "stamina bar mirrors gameplay stamina (bar=%.3f, game=%.3f)" % [
            stamina_bar.value if is_instance_valid(stamina_bar) else -1.0,
            float(main.get("stamina"))
        ])
    main.set("stamina", 5.0)
    main.set("_stamina_regen_delay", 0.0)
    main.call("_process", 0.25)
    _check(not bool(player.get("is_sprinting")), "empty stamina automatically stops sprinting")
    player.set_mobile_direction(Vector2.ZERO)
    await physics_frame
    main.set("stamina", 100.0)
    main.set("_stamina_regen_delay", 0.0)
    main.call("_toggle_sprint")
    _check(bool(player.get("is_sprinting")), "sprint can be enabled again after recovery")
    main.call("_toggle_crouch")
    await process_frame
    _check(bool(player.get("is_crouching")), "crouching can be enabled")
    _check(not bool(player.get("is_sprinting")), "crouching cancels sprinting")
    main.call("_toggle_crouch")
    await process_frame
    _check(not bool(player.get("is_crouching")), "standing restores normal movement")
    main.call("_toggle_crouch")
    await process_frame
    _check(bool(player.get("is_crouching")), "crouch mode can be enabled")
    _check(float(player.get("move_speed")) < 4.0, "crouch mode reduces movement speed")
    _check(is_equal_approx(float((player.get_node("CharacterVisual") as Node3D).scale.y), 0.72),
        "crouch lowers the character visuals")
    var player_collider := player.get_node("PlayerCollider") as CollisionShape3D
    _check(is_equal_approx((player_collider.shape as CapsuleShape3D).height, 1.12),
        "crouch lowers the physical collision capsule")
    main.call("_toggle_crouch")
    await process_frame
    _check(not bool(player.get("is_crouching")), "crouch mode can be disabled")
    _check(is_equal_approx(float((player.get_node("CharacterVisual") as Node3D).scale.y), 1.0),
        "standing restores the character visuals")
    _check(is_equal_approx((player_collider.shape as CapsuleShape3D).height, 1.58),
        "standing restores the physical collision capsule")
    main.set("call_active", true)
    hud.call("show_call", "Проверка паузы во время звонка")
    main.call("_toggle_pause")
    main.call("_resume_game")
    _check(not player.is_physics_processing(), "resume during phone call keeps player controls locked")
    main.call("_answer_call")
    _check(player.is_physics_processing(), "answering phone restores player controls")
    await process_frame
    var tween_probe := Node3D.new()
    tween_probe.name = "PauseTweenProbe"
    world.add_child(tween_probe)
    main.call("_remove_interactable", tween_probe)
    await process_frame
    var pause_time_before: float = float(main.get("time_left"))
    var pause_loot_position := loot[0].global_position
    var pause_cameras := get_nodes_in_group("security_cameras")
    var pause_camera_head: Node3D
    var pause_camera_rotation: float = 0.0
    if not pause_cameras.is_empty():
        pause_camera_head = (pause_cameras[0] as Node3D).get("_head") as Node3D
        pause_camera_rotation = pause_camera_head.rotation.y
    main.call("_toggle_pause")
    var probe_scale_at_pause := tween_probe.scale
    _check(bool(main.get("paused")), "pause freezes the shift")
    _check((world.process_mode == Node.PROCESS_MODE_DISABLED), "pause disables the 3D world process tree")
    _check(bool((main.get("music") as AudioStreamPlayer).stream_paused), "pause suspends ambient audio")
    await create_timer(0.3).timeout
    _check(is_equal_approx(float(main.get("time_left")), pause_time_before), "mission timer remains frozen while paused")
    _check(loot[0].global_position.distance_to(pause_loot_position) < 0.001, "collectible bobbing stops while paused")
    _check(is_instance_valid(tween_probe) and tween_probe.scale.distance_to(probe_scale_at_pause) < 0.001,
        "interaction shrink animation stops while paused")
    if is_instance_valid(pause_camera_head):
        _check(is_equal_approx(pause_camera_head.rotation.y, pause_camera_rotation), "security camera sweep stops while paused")
    main.call("_resume_game")
    _check(not bool(main.get("paused")), "resume restores the shift")
    _check(world.process_mode != Node.PROCESS_MODE_DISABLED, "resume restores world processing")
    _check(not bool((main.get("music") as AudioStreamPlayer).stream_paused), "resume restores ambient audio")
    await create_timer(0.25).timeout
    _check(not is_instance_valid(tween_probe), "interaction shrink animation resumes after unpausing")

    player.global_position = exit_target.global_position
    main.call("_on_action_pressed")
    _check(not bool(main.get("ended")), "exit is blocked until objectives are complete")
    player.global_position = dirt[0].global_position
    main.call("_on_action_pressed")
    _check(int(main.get("dirt_remaining")) == 7, "cleaning is blocked until all valuables are found")

    await _complete_objectives(main)
    _check((hud.get("_toast_label") as Label).text.contains("Квартира"), "apartment cleanup uses apartment-specific text")
    _check(int(main.get("loot_found")) == 5, "all five valuables can be collected")
    _check(int(main.get("dirt_remaining")) == 0, "all seven stains can be cleaned")

    _check(bool(exit_target.get_meta("unlocked", false)), "exit unlocks when the apartment is clean")
    await create_timer(0.28).timeout
    await process_frame
    player.global_position = exit_target.global_position
    main.call("_on_action_pressed")
    _check(bool(main.get("ended")), "using the exit finishes the shift")
    _check(bool(main.get("_ending_cutscene_active")), "successful escape starts the ending cinematic")
    main.call("_skip_cutscene")
    _check(not bool(main.get("_ending_cutscene_active")), "successful ending cinematic can be skipped")
    _check(is_instance_valid(hud.get("_ending_overlay")) and (hud.get("_ending_overlay") as Control).visible, "success results panel appears")

    # Verify loss paths without allowing them to interfere with the full win flow.
    main.set("ended", false)
    world.set("_exit_unlocked", false)
    exit_target.set_meta("unlocked", false)
    var hinge := world.get_node_or_null("ExitDoorHinge") as Node3D
    if is_instance_valid(hinge):
        hinge.rotation.y = 0.0
    main.set("call_shown", true)
    main.set("time_left", 0.25)
    main.set("alert_level", 0.0)
    main.set("_camera_visible", false)
    main.set("_camera_scan_elapsed", 0.0)
    main.call("_process", 1.0)
    _check(bool(main.get("ended")), "running out of time ends the shift")
    _check(bool(main.get("_ending_cutscene_active")), "owners return after a failed shift")
    _check(not bool(exit_target.get_meta("unlocked", false)), "failure does not incorrectly open the exit")
    var returning_owner := main.get("_returning_owner") as Node3D
    _check(is_instance_valid(returning_owner), "failure creates a tracked returning owner")
    if is_instance_valid(hinge):
        _check(absf(hinge.rotation.y) < 0.01, "failure leaves the exit door closed")
    main.call("_skip_cutscene")
    _check(not bool(main.get("_ending_cutscene_active")), "return cutscene can be skipped")
    if is_instance_valid(returning_owner):
        _check(not returning_owner.is_physics_processing(), "returning owner stops moving after the results screen")

    main.set("ended", false)
    main.set("time_left", 120.0)
    main.set("alert_level", 99.0)
    main.set("_camera_visible", true)
    main.set("_camera_scan_elapsed", -10.0)
    main.call("_process", 0.2)
    _check(bool(main.get("ended")), "maximum camera alert ends the shift")

    var exit_code := 0
    if failures == 0:
        print("PASS: full gameplay, pause, phone and failure regression tests completed.")
    else:
        push_error("%d gameplay smoke test(s) failed." % failures)
        exit_code = 1
    await _cleanup_and_quit(main, exit_code)
    return

func _cleanup_and_quit(main_scene: Node, exit_code: int) -> void:
    current_scene = null
    if is_instance_valid(main_scene):
        var music_player := main_scene.get("music") as AudioStreamPlayer
        var sound_player := main_scene.get("sfx") as AudioStreamPlayer
        var has_audio_cleanup: bool = main_scene.has_method("_stop_audio")
        _check(has_audio_cleanup, "game exposes deterministic audio shutdown")
        if has_audio_cleanup:
            main_scene.call("_stop_audio")
        if is_instance_valid(music_player):
            _check(not music_player.playing, "ambient music stops when the scene closes")
            _check(music_player.stream == null, "ambient stream releases its resource")
        if is_instance_valid(sound_player):
            _check(not sound_player.playing, "sound effects stop when the scene closes")
            _check(sound_player.stream == null, "sound effect stream releases its resource")
        main_scene.queue_free()
    await process_frame
    await process_frame
    await create_timer(0.35).timeout
    call_deferred("quit", exit_code)

func _complete_objectives(main_scene: Node) -> void:
    var player_node := main_scene.get("player") as Node3D
    var loot_items: Array[Node3D] = []
    for candidate in get_nodes_in_group("interactable"):
        if is_instance_valid(candidate) and str(candidate.get_meta("kind", "")) == "loot":
            loot_items.append(candidate as Node3D)
    for item in loot_items:
        player_node.global_position = item.global_position
        main_scene.call("_on_action_pressed")
        await process_frame
    var dirt_items: Array[Node3D] = []
    for candidate in get_nodes_in_group("interactable"):
        if is_instance_valid(candidate) and str(candidate.get_meta("kind", "")) == "dirt":
            dirt_items.append(candidate as Node3D)
    for stain in dirt_items:
        player_node.global_position = stain.global_position
        main_scene.call("_on_action_pressed")
        await process_frame

func _count_kind(kind: String) -> int:
    var count := 0
    for candidate in get_nodes_in_group("interactable"):
        if is_instance_valid(candidate) and str(candidate.get_meta("kind", "")) == kind:
            count += 1
    return count

func _check(condition: bool, label: String) -> void:
    if condition:
        print("PASS: " + label)
    else:
        failures += 1
        push_error("FAIL: " + label)

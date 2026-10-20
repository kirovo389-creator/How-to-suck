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
    var player := main.get("player") as Node3D
    var world := main.get("world") as Node3D
    if not is_instance_valid(player) or not is_instance_valid(world):
        _check(false, "player and 3D apartment initialized")
        await _cleanup_and_quit(main, 1)
        return
    _check(world.get_node_or_null("FollowCamera") is Camera3D, "follow camera exists")
    var exit_target := world.get_node_or_null("ExitInteraction") as Node3D
    if not is_instance_valid(exit_target):
        _check(false, "exit interaction exists")
        await _cleanup_and_quit(main, 1)
        return

    var hud := main.get("hud") as CanvasLayer
    hud.call("_choose_location", "store")
    await process_frame
    world = main.get("world") as Node3D
    _check(str(world.get("level_id")) == "store", "intro can switch to the shop level")
    var background_music := main.get("music") as AudioStreamPlayer
    _check(background_music.stream == load("res://audio/store_ambience.wav"), "shop uses its own ambient sound")
    _check(world.get_node_or_null("AisleLight0") is OmniLight3D, "shop has dedicated aisle lighting")
    _check(_count_kind("loot") == 5, "shop level has five valuables")
    _check(_count_kind("dirt") == 7, "shop level has seven spills")
    # Complete an entire shop shift first, not just a resource-count check.
    main.call("_on_action_pressed")
    _check(bool(main.get("shift_started")), "shop shift starts from the intro")
    main.call("_skip_cutscene")
    await process_frame
    await _complete_objectives(main)
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
    var shop_hud := main.get("hud") as CanvasLayer
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
    # Test movement in an open hallway, not next to the coffee-table collider.
    player.global_position = Vector3(-7.0, 0.0, 0.0)
    var player_start := player.global_position
    player.set_mobile_direction(Vector2.RIGHT)
    await physics_frame
    await physics_frame
    player.set_mobile_direction(Vector2.ZERO)
    _check(player.global_position.x > player_start.x + 0.01, "virtual joystick moves the player")

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
    main.call("_skip_cutscene")
    _check(not bool(main.get("cutscene_playing")), "opening cinematic can be skipped")
    await process_frame
    main.call("_toggle_pause")
    _check(bool(main.get("paused")), "pause freezes the shift")
    main.call("_resume_game")
    _check(not bool(main.get("paused")), "resume restores the shift")

    player.global_position = exit_target.global_position
    main.call("_on_action_pressed")
    _check(not bool(main.get("ended")), "exit is blocked until objectives are complete")
    player.global_position = dirt[0].global_position
    main.call("_on_action_pressed")
    _check(int(main.get("dirt_remaining")) == 7, "cleaning is blocked until all valuables are found")

    await _complete_objectives(main)
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
    if is_instance_valid(hinge):
        _check(absf(hinge.rotation.y) < 0.01, "failure leaves the exit door closed")
    main.call("_skip_cutscene")
    _check(not bool(main.get("_ending_cutscene_active")), "return cutscene can be skipped")

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
        main_scene.queue_free()
    await process_frame
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

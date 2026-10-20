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
        quit(1)
        return
    _check(world.get_node_or_null("FollowCamera") is Camera3D, "follow camera exists")

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

    for item in loot:
        player.global_position = item.global_position
        main.call("_on_action_pressed")
        await process_frame
    _check(int(main.get("loot_found")) == 5, "all five valuables can be collected")

    for item in dirt:
        player.global_position = item.global_position
        main.call("_on_action_pressed")
        await process_frame
    _check(int(main.get("dirt_remaining")) == 0, "all seven stains can be cleaned")

    var exit_target := world.get_node_or_null("ExitInteraction") as Node3D
    if not is_instance_valid(exit_target):
        _check(false, "exit interaction exists")
        quit(1)
        return
    _check(bool(exit_target.get_meta("unlocked", false)), "exit unlocks when the apartment is clean")
    await process_frame
    player.global_position = exit_target.global_position
    main.call("_on_action_pressed")
    _check(bool(main.get("ended")), "using the exit finishes the shift")

    if failures == 0:
        print("PASS: full gameplay loop completed in headless test.")
        quit(0)
    else:
        push_error("%d gameplay smoke test(s) failed." % failures)
        quit(1)

func _check(condition: bool, label: String) -> void:
    if condition:
        print("PASS: " + label)
    else:
        failures += 1
        push_error("FAIL: " + label)

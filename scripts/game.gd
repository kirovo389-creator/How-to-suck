extends Node3D
const PlayerScene = preload("res://scenes/player.tscn")
const HudScene = preload("res://scenes/hud.tscn")
const WorldBuilder = preload("res://scripts/world_builder.gd")
var player
var hud
var loot_found := 0
var loot_total := 5
var dirt_remaining := 7
var time_left := 240.0
var shift_started := false
var call_timer := 0.0
var call_active := false
var ended := false

func _ready():
    _lighting()
    var world = WorldBuilder.new()
    world.name = "ApartmentLevel"
    add_child(world)
    player = PlayerScene.instantiate()
    player.position = Vector3(0,0,5)
    add_child(player)
    var startup_camera := world.get_node_or_null("FollowCamera") as Camera3D
    if is_instance_valid(startup_camera):
        startup_camera.call("set_target", player)
        startup_camera.make_current()
    hud = HudScene.instantiate()
    add_child(hud)
    hud.action_pressed.connect(_action)
    hud.movement_changed.connect(player.set_mobile_direction)
    hud.call_answered.connect(_answer_call)
    hud.show_intro()
    _status()

func _lighting():
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_SKY
    var sky = Sky.new()
    var sm = ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.015,0.025,0.07)
    sm.sky_horizon_color = Color(0.12,0.14,0.19)
    sky.sky_material = sm
    e.sky = sky
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.38,0.42,0.55)
    e.ambient_light_energy = 0.55
    env.environment = e
    add_child(env)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48,-28,0)
    sun.light_color = Color(0.78,0.83,1)
    sun.light_energy = 0.8
    sun.shadow_enabled = true
    add_child(sun)

func _process(delta):
    if not shift_started or ended or call_active:
        return
    time_left -= delta
    call_timer += delta
    if loot_found >= loot_total and dirt_remaining > 0:
        hud.set_task("Уборка: очисти все пятна")
    if call_timer > 55.0:
        call_active = true
        hud.show_call("Мы видели движение на камерах. Уже едем домой!")
    if time_left <= 0:
        ended = true
        hud.show_ending(false)

func _action():
    if not shift_started:
        shift_started = true
        hud.hide_intro()
        hud.toast("Найди 5 ценностей, затем убери 7 пятен.")
        return
    if call_active:
        return
    var target = _nearest_interactable()
    if target == null:
        hud.toast("Подойди ближе к предмету или пятну.")
        return
    var kind = target.get_meta("kind","")
    target.queue_free()
    if kind == "loot":
        loot_found += 1
        hud.toast("Ценность найдена: %d/%d" % [loot_found,loot_total])
    elif kind == "dirt":
        dirt_remaining -= 1
        hud.toast("Пятно убрано. Осталось: %d" % dirt_remaining)
        if dirt_remaining <= 0:
            ended = true
            hud.show_ending(true)
    _status()

func _nearest_interactable():
    var best = null
    var best_dist = 2.8
    for item in get_tree().get_nodes_in_group("interactable"):
        if not is_instance_valid(item):
            continue
        var d = player.global_position.distance_to(item.global_position)
        if d < best_dist:
            best = item
            best_dist = d
    return best

func _answer_call():
    call_active = false
    call_timer = -999.0
    time_left = maxf(25.0,time_left-15.0)
    hud.toast("Звонок завершён. Быстрее заканчивай смену!")

func _status():
    if is_instance_valid(hud):
        hud.update_status(loot_found,loot_total,dirt_remaining,int(maxf(0,time_left)))

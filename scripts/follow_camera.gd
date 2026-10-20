extends Camera3D

@export var follow_speed: float = 5.8
@export var cutscene_duration: float = 4.6

var target: Node3D
var _cutscene_active: bool = false
var _cutscene_elapsed: float = 0.0
var _cutscene_style: int = 0
var _cutscene_subject: Node3D
var _cutscene_start: Vector3
var _cutscene_kitchen: Vector3
var _cutscene_center: Vector3
var _cutscene_bedroom: Vector3

func _ready() -> void:
    target = _find_target()

func play_opening_cutscene() -> void:
    _cutscene_style = 0
    target = _find_target()
    _cutscene_elapsed = 0.0
    _cutscene_start = global_position
    if is_instance_valid(target):
        _cutscene_kitchen = target.global_position + Vector3(-8.8, 7.3, 7.0)
        _cutscene_center = Vector3(0.0, 8.4, -0.8)
        _cutscene_bedroom = target.global_position + Vector3(7.5, 7.5, -7.0)
    else:
        _cutscene_kitchen = Vector3(-8.8, 7.3, 9.8)
        _cutscene_center = Vector3(0.0, 8.4, -0.8)
        _cutscene_bedroom = Vector3(7.5, 7.5, -4.2)
    _cutscene_active = true

func play_return_cutscene(subject: Node3D) -> void:
    target = _find_target()
    _cutscene_style = 1
    _cutscene_subject = subject
    _cutscene_elapsed = 0.0
    _cutscene_start = global_position
    _cutscene_kitchen = subject.global_position + Vector3(-3.8, 3.6, 4.5)
    _cutscene_center = subject.global_position + Vector3(0.0, 4.8, 6.5)
    _cutscene_bedroom = target.global_position + Vector3(3.2, 3.6, 5.2)
    _cutscene_active = true

func cancel_cutscene() -> void:
    _cutscene_active = false
    _cutscene_elapsed = 0.0
    _cutscene_style = 0

func cancel_opening_cutscene() -> void:
    cancel_cutscene()

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        target = _find_target()
    if not is_instance_valid(target):
        return
    if _cutscene_active:
        _cutscene_elapsed += delta
        var progress := clampf(_cutscene_elapsed / cutscene_duration, 0.0, 1.0)
        if progress < 0.34:
            global_position = _cutscene_start.lerp(_cutscene_kitchen, smoothstep(0.0, 0.34, progress))
        elif progress < 0.68:
            global_position = _cutscene_kitchen.lerp(_cutscene_center, smoothstep(0.34, 0.68, progress))
        else:
            global_position = _cutscene_center.lerp(_cutscene_bedroom, smoothstep(0.68, 1.0, progress))
        var look_target := Vector3(0.0, 1.0, -1.0)
        if _cutscene_style == 1:
            if progress < 0.7 and is_instance_valid(_cutscene_subject):
                look_target = _cutscene_subject.global_position + Vector3(0.0, 1.0, 0.0)
            else:
                look_target = target.global_position + Vector3(0.0, 0.85, 0.0)
        look_at(look_target, Vector3.UP)
        if _cutscene_elapsed >= cutscene_duration:
            _cutscene_active = false
        return
    var desired := target.global_position + Vector3(0.0, 10.0, 11.0)
    global_position = global_position.lerp(desired, clampf(delta * follow_speed, 0.0, 1.0))
    look_at(target.global_position + Vector3(0.0, 0.8, 0.0), Vector3.UP)

func _find_target() -> Node3D:
    var scene := get_tree().current_scene
    if is_instance_valid(scene):
        return scene.get_node_or_null("Player") as Node3D
    return null

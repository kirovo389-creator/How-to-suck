extends Node3D

@export var bob_height: float = 0.12
@export var bob_speed: float = 2.2
@export var spin_speed: float = 0.55
var _base_y: float = 0.0
var _phase: float = 0.0

func _ready() -> void:
    _base_y = position.y
    _phase = float(get_instance_id() % 101) * 0.061

func _process(delta: float) -> void:
    var t := float(Time.get_ticks_msec()) / 1000.0
    position.y = _base_y + sin(t * bob_speed + _phase) * bob_height
    rotation.y += spin_speed * delta

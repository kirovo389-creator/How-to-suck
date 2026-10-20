extends CharacterBody3D

@export var move_speed: float = 4.0
var mobile_direction: Vector2 = Vector2.ZERO
var _animation_time: float = 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _torso: Node3D

func _ready() -> void:
    _make_character()
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.29
    capsule.height = 1.58
    collider.shape = capsule
    collider.position.y = 0.79
    add_child(collider)

func set_mobile_direction(direction: Vector2) -> void:
    mobile_direction = direction.limit_length(1.0)

func _physics_process(delta: float) -> void:
    var keyboard := Vector2(
        Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
        Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    )
    var direction := keyboard if keyboard.length() > 0.12 else mobile_direction
    direction = direction.limit_length(1.0)
    velocity.x = direction.x * move_speed
    velocity.z = direction.y * move_speed
    velocity.y = 0.0
    move_and_slide()
    var moving := direction.length() > 0.05
    if moving:
        rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.y), delta * 11.0)
    _animation_time += delta * (9.2 if moving else 2.2)
    for index in range(_legs.size()):
        _legs[index].rotation.x = sin(_animation_time + float(index) * PI) * (0.42 if moving else 0.025)
    for index in range(_arms.size()):
        var swing := sin(_animation_time + float(index) * PI + PI) * (0.3 if moving else 0.025)
        _arms[index].rotation.x = swing
        _arms[index].rotation.z = (-0.08 if index == 0 else 0.08) + (swing * 0.3)
    if is_instance_valid(_torso):
        _torso.position.y = 1.02 + (absf(sin(_animation_time * 2.0)) * 0.025 if moving else 0.0)

func _make_character() -> void:
    var uniform := Color(0.055, 0.27, 0.31)
    var dark := Color(0.035, 0.045, 0.06)
    var skin := Color(0.72, 0.48, 0.34)
    var shoe := Color(0.025, 0.03, 0.04)
    _torso = Node3D.new()
    _torso.position = Vector3(0.0, 1.02, 0.0)
    add_child(_torso)
    _box(_torso, Vector3(0.0, 0.0, 0.0), Vector3(0.56, 0.62, 0.34), uniform)
    _box(_torso, Vector3(0.0, -0.34, 0.0), Vector3(0.58, 0.12, 0.36), dark)
    _sphere(self, Vector3(0.0, 1.52, 0.015), Vector3(0.225, 0.245, 0.22), skin)
    _sphere(self, Vector3(0.0, 1.69, -0.02), Vector3(0.235, 0.105, 0.235), Color(0.075, 0.045, 0.028))
    _sphere(self, Vector3(0.0, 1.59, 0.213), Vector3(0.025, 0.02, 0.018), Color(0.12, 0.07, 0.05))
    for x in [-0.075, 0.075]:
        _sphere(self, Vector3(x, 1.55, 0.204), Vector3(0.024, 0.018, 0.012), Color(0.035, 0.03, 0.025))
    for index in range(2):
        var side := -1.0 if index == 0 else 1.0
        var hip := Node3D.new()
        hip.position = Vector3(side * 0.17, 0.69, 0.0)
        add_child(hip)
        _box(hip, Vector3(0.0, -0.22, 0.0), Vector3(0.19, 0.48, 0.22), dark)
        _box(hip, Vector3(0.0, -0.48, 0.055), Vector3(0.23, 0.12, 0.34), shoe)
        _legs.append(hip)
        var shoulder := Node3D.new()
        shoulder.position = Vector3(side * 0.35, 1.28, 0.0)
        add_child(shoulder)
        _box(shoulder, Vector3(0.0, -0.21, 0.0), Vector3(0.16, 0.43, 0.17), uniform)
        _sphere(shoulder, Vector3(0.0, -0.43, 0.035), Vector3(0.09, 0.095, 0.09), skin)
        _arms.append(shoulder)
    # Work belt, shoulder strap and a small utility pouch.
    _box(_torso, Vector3(0.23, -0.18, 0.02), Vector3(0.1, 0.27, 0.11), Color(0.6, 0.39, 0.17))
    _box(self, Vector3(-0.2, 1.0, -0.2), Vector3(0.28, 0.42, 0.15), Color(0.2, 0.22, 0.2))
    _box(self, Vector3(0.4, 0.47, 0.22), Vector3(0.055, 0.78, 0.055), Color(0.5, 0.34, 0.18))
    _box(self, Vector3(0.4, 0.09, 0.22), Vector3(0.29, 0.08, 0.23), Color(0.22, 0.64, 0.75))

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.position = position
    instance.material_override = _material(color)
    parent.add_child(instance)
    return instance

func _sphere(parent: Node3D, position: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    instance.mesh = mesh
    instance.position = position
    instance.scale = scale_value
    instance.material_override = _material(color)
    parent.add_child(instance)
    return instance

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    return material

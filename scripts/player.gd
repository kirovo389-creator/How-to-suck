extends CharacterBody3D

@export var move_speed: float = 4.0
var mobile_direction: Vector2 = Vector2.ZERO
var _animation_time: float = 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _torso: Node3D
var _interaction_elapsed: float = -1.0
var _interaction_kind: String = ""
var _rest_arm_rotations: Array[Vector3] = []
var is_crouching: bool = false
var is_sprinting: bool = false
var is_moving: bool = false
var _standing_speed: float = 4.0
var _visual_root: Node3D
var _collider: CollisionShape3D
var _capsule: CapsuleShape3D

func _ready() -> void:
    _standing_speed = move_speed
    _make_character()
    for arm in _arms:
        _rest_arm_rotations.append(arm.rotation)
    _collider = CollisionShape3D.new()
    _collider.name = "PlayerCollider"
    _capsule = CapsuleShape3D.new()
    _capsule.radius = 0.29
    _capsule.height = 1.58
    _collider.shape = _capsule
    _collider.position.y = 0.79
    add_child(_collider)

func set_mobile_direction(direction: Vector2) -> void:
    mobile_direction = direction.limit_length(1.0)

func set_crouching(enabled: bool) -> void:
    is_crouching = enabled
    if enabled:
        is_sprinting = false
    _refresh_move_speed()
    if is_instance_valid(_visual_root):
        _visual_root.scale.y = 0.72 if enabled else 1.0
    call_deferred("_apply_crouch_collision", enabled)

func set_sprinting(enabled: bool) -> void:
    is_sprinting = enabled and not is_crouching
    _refresh_move_speed()

func _refresh_move_speed() -> void:
    if is_crouching:
        move_speed = _standing_speed * 0.58
    elif is_sprinting:
        move_speed = _standing_speed * 1.65
    else:
        move_speed = _standing_speed

func _apply_crouch_collision(enabled: bool) -> void:
    if not is_instance_valid(_capsule) or not is_instance_valid(_collider):
        return
    _capsule.height = 1.12 if enabled else 1.58
    _collider.position.y = 0.56 if enabled else 0.79

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
    is_moving = direction.length() > 0.05
    var moving := is_moving
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
    _update_interaction_animation(delta)

func play_interaction(kind: String) -> void:
    if kind != "loot" and kind != "dirt":
        return
    _interaction_kind = kind
    _interaction_elapsed = 0.0

func is_interacting() -> bool:
    return _interaction_elapsed >= 0.0

func _update_interaction_animation(delta: float) -> void:
    if _interaction_elapsed < 0.0:
        return
    _interaction_elapsed += delta
    var progress := clampf(_interaction_elapsed / 0.62, 0.0, 1.0)
    var weight := sin(progress * PI)
    var bend := 0.25 if _interaction_kind == "loot" else 0.42
    if is_instance_valid(_torso):
        _torso.rotation.x = bend * weight
    var active_arm_index := 1 if _interaction_kind == "dirt" else 0
    var secondary_arm_index := 1 - active_arm_index
    var reach := -0.62 if _interaction_kind == "loot" else -1.0
    if active_arm_index < _arms.size():
        _arms[active_arm_index].rotation.x = _rest_arm_rotations[active_arm_index].x + reach * weight
        _arms[active_arm_index].rotation.z = _rest_arm_rotations[active_arm_index].z + (-0.08 if active_arm_index == 0 else 0.08) * weight
    if secondary_arm_index < _arms.size():
        _arms[secondary_arm_index].rotation.x = _rest_arm_rotations[secondary_arm_index].x - 0.18 * weight
    if progress >= 1.0:
        _interaction_elapsed = -1.0
        _interaction_kind = ""
        if is_instance_valid(_torso):
            _torso.rotation = Vector3.ZERO
        for index in range(_arms.size()):
            _arms[index].rotation = _rest_arm_rotations[index]

func _make_character() -> void:
    _visual_root = Node3D.new()
    _visual_root.name = "CharacterVisual"
    add_child(_visual_root)
    var uniform := Color(0.055, 0.27, 0.31)
    var dark := Color(0.035, 0.045, 0.06)
    var skin := Color(0.72, 0.48, 0.34)
    var shoe := Color(0.025, 0.03, 0.04)
    _torso = Node3D.new()
    _torso.position = Vector3(0.0, 1.02, 0.0)
    _visual_root.add_child(_torso)
    _box(_torso, Vector3(0.0, 0.0, 0.0), Vector3(0.56, 0.62, 0.34), uniform)
    _box(_torso, Vector3(0.0, -0.34, 0.0), Vector3(0.58, 0.12, 0.36), dark)
    _sphere(_visual_root, Vector3(0.0, 1.52, 0.015), Vector3(0.225, 0.245, 0.22), skin)
    _sphere(_visual_root, Vector3(0.0, 1.69, -0.02), Vector3(0.235, 0.105, 0.235), Color(0.075, 0.045, 0.028))
    _sphere(_visual_root, Vector3(0.0, 1.59, 0.213), Vector3(0.025, 0.02, 0.018), Color(0.12, 0.07, 0.05))
    for x in [-0.075, 0.075]:
        _sphere(_visual_root, Vector3(x, 1.55, 0.204), Vector3(0.024, 0.018, 0.012), Color(0.035, 0.03, 0.025))
    for index in range(2):
        var side := -1.0 if index == 0 else 1.0
        var hip := Node3D.new()
        hip.position = Vector3(side * 0.17, 0.69, 0.0)
        _visual_root.add_child(hip)
        _box(hip, Vector3(0.0, -0.22, 0.0), Vector3(0.19, 0.48, 0.22), dark)
        _box(hip, Vector3(0.0, -0.48, 0.055), Vector3(0.23, 0.12, 0.34), shoe)
        _legs.append(hip)
        var shoulder := Node3D.new()
        shoulder.position = Vector3(side * 0.35, 1.28, 0.0)
        _visual_root.add_child(shoulder)
        _box(shoulder, Vector3(0.0, -0.21, 0.0), Vector3(0.16, 0.43, 0.17), uniform)
        _sphere(shoulder, Vector3(0.0, -0.43, 0.035), Vector3(0.09, 0.095, 0.09), skin)
        _arms.append(shoulder)
    # The broom is parented to the cleaner's right hand so sweeping is visible.
    _box(_arms[1], Vector3(0.04, -0.58, 0.18), Vector3(0.055, 0.82, 0.055), Color(0.5, 0.34, 0.18))
    _box(_arms[1], Vector3(0.04, -0.98, 0.18), Vector3(0.29, 0.08, 0.23), Color(0.22, 0.64, 0.75))
    # Work belt, shoulder strap and a small utility pouch.
    _box(_torso, Vector3(0.23, -0.18, 0.02), Vector3(0.1, 0.27, 0.11), Color(0.6, 0.39, 0.17))
    _box(_visual_root, Vector3(-0.2, 1.0, -0.2), Vector3(0.28, 0.42, 0.15), Color(0.2, 0.22, 0.2))

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

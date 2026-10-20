extends CharacterBody3D

@export var walk_speed: float = 1.65
var target: Node3D
var _walk_time: float = 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []

func _ready() -> void:
    _make_character()
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.3
    capsule.height = 1.72
    collider.shape = capsule
    collider.position.y = 0.86
    add_child(collider)

func set_target(value: Node3D) -> void:
    target = value

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        velocity = Vector3.ZERO
        return
    var toward := target.global_position - global_position
    toward.y = 0.0
    var moving := toward.length() > 1.15
    if moving:
        var direction := toward.normalized()
        velocity.x = direction.x * walk_speed
        velocity.z = direction.z * walk_speed
        rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 4.5)
    else:
        velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta * 3.0)
        velocity.z = move_toward(velocity.z, 0.0, walk_speed * delta * 3.0)
    velocity.y = 0.0
    move_and_slide()
    _walk_time += delta * (7.2 if moving else 1.4)
    for index in range(_legs.size()):
        _legs[index].rotation.x = sin(_walk_time + float(index) * PI) * (0.32 if moving else 0.018)
    for index in range(_arms.size()):
        _arms[index].rotation.x = sin(_walk_time + float(index) * PI + PI) * (0.18 if moving else 0.01)

func _make_character() -> void:
    var jacket := Color(0.27, 0.3, 0.32)
    var pants := Color(0.085, 0.11, 0.15)
    var skin := Color(0.68, 0.47, 0.34)
    var shoe := Color(0.035, 0.04, 0.05)
    var torso := Node3D.new()
    torso.position.y = 1.04
    add_child(torso)
    _box(torso, Vector3(0.0, 0.0, 0.0), Vector3(0.61, 0.66, 0.36), jacket)
    _box(torso, Vector3(0.0, 0.02, 0.19), Vector3(0.22, 0.52, 0.035), Color(0.73, 0.7, 0.61))
    _box(torso, Vector3(0.0, -0.31, 0.0), Vector3(0.64, 0.13, 0.39), pants)
    _sphere(self, Vector3(0.0, 1.59, 0.0), Vector3(0.235, 0.255, 0.22), skin)
    _sphere(self, Vector3(0.0, 1.75, -0.015), Vector3(0.245, 0.12, 0.235), Color(0.13, 0.095, 0.07))
    _sphere(self, Vector3(-0.09, 1.79, 0.025), Vector3(0.12, 0.075, 0.15), Color(0.13, 0.095, 0.07))
    for x in [-0.075, 0.075]:
        _sphere(self, Vector3(x, 1.61, 0.205), Vector3(0.022, 0.019, 0.014), Color(0.025, 0.025, 0.03))
    for index in range(2):
        var side := -1.0 if index == 0 else 1.0
        var hip := Node3D.new()
        hip.position = Vector3(side * 0.17, 0.72, 0.0)
        add_child(hip)
        _box(hip, Vector3(0.0, -0.22, 0.0), Vector3(0.2, 0.48, 0.23), pants)
        _box(hip, Vector3(0.0, -0.49, 0.055), Vector3(0.24, 0.12, 0.34), shoe)
        _legs.append(hip)
        var shoulder := Node3D.new()
        shoulder.position = Vector3(side * 0.37, 1.29, 0.0)
        add_child(shoulder)
        _box(shoulder, Vector3(0.0, -0.2, 0.0), Vector3(0.17, 0.43, 0.19), jacket)
        _sphere(shoulder, Vector3(0.0, -0.42, 0.025), Vector3(0.08, 0.09, 0.08), skin)
        _arms.append(shoulder)
    # A key ring makes the returning owner readable even in the dim entry hall.
    _box(self, Vector3(0.43, 0.55, 0.22), Vector3(0.06, 0.58, 0.06), Color(0.63, 0.49, 0.22))
    var key_ring := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 0.11
    ring_mesh.outer_radius = 0.16
    ring_mesh.rings = 8
    ring_mesh.ring_segments = 14
    key_ring.mesh = ring_mesh
    key_ring.position = Vector3(0.43, 0.23, 0.22)
    key_ring.rotation.x = deg_to_rad(90.0)
    key_ring.material_override = _material(Color(0.85, 0.68, 0.3))
    add_child(key_ring)

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = position
    node.material_override = _material(color)
    parent.add_child(node)
    return node

func _sphere(parent: Node3D, position: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    node.mesh = mesh
    node.position = position
    node.scale = scale_value
    node.material_override = _material(color)
    parent.add_child(node)
    return node

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    return material

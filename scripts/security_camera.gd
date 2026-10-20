extends Node3D

@export var detection_range: float = 9.0
@export_range(10.0, 100.0, 1.0) var field_of_view: float = 66.0
@export var sweep_degrees: float = 34.0
@export var sweep_speed: float = 0.72

var _head: Node3D
var _lens_light: OmniLight3D
var _phase: float = 0.0

func _ready() -> void:
    add_to_group("security_cameras")
    _phase = float(get_instance_id() % 997) / 997.0 * TAU
    _build_model()

func _process(_delta: float) -> void:
    if is_instance_valid(_head):
        _head.rotation.y = sin(float(Time.get_ticks_msec()) / 1000.0 * sweep_speed + _phase) * deg_to_rad(sweep_degrees)

func can_see(target: Node3D) -> bool:
    if not is_instance_valid(target):
        return false
    var origin := global_position + Vector3(0.0, -0.16, 0.0)
    var target_pos := target.global_position + Vector3(0.0, 0.82, 0.0)
    var direction := target_pos - origin
    var flat_direction := Vector3(direction.x, 0.0, direction.z)
    if flat_direction.length() > detection_range:
        return false
    if flat_direction.length_squared() < 0.001:
        return true
    var forward := -_head.global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    if forward.dot(flat_direction.normalized()) < cos(deg_to_rad(field_of_view * 0.5)):
        return false
    var query := PhysicsRayQueryParameters3D.create(origin, target_pos)
    query.exclude = [target.get_rid()]
    query.collision_mask = 1
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty()

func set_alert_active(active: bool) -> void:
    if not is_instance_valid(_lens_light):
        return
    _lens_light.light_color = Color(1.0, 0.12, 0.08) if active else Color(0.16, 0.62, 0.88)
    _lens_light.light_energy = 1.8 if active else 0.45

func _build_model() -> void:
    var base_material := _material(Color(0.075, 0.095, 0.12))
    var base := MeshInstance3D.new()
    var base_mesh := BoxMesh.new()
    base_mesh.size = Vector3(0.42, 0.22, 0.32)
    base.mesh = base_mesh
    base.material_override = base_material
    add_child(base)
    var support := MeshInstance3D.new()
    var support_mesh := BoxMesh.new()
    support_mesh.size = Vector3(0.12, 0.18, 0.12)
    support.mesh = support_mesh
    support.position = Vector3(0.0, -0.18, 0.0)
    support.material_override = base_material
    add_child(support)
    _head = Node3D.new()
    _head.position = Vector3(0.0, -0.22, -0.05)
    add_child(_head)
    var housing := MeshInstance3D.new()
    var housing_mesh := BoxMesh.new()
    housing_mesh.size = Vector3(0.34, 0.22, 0.36)
    housing.mesh = housing_mesh
    housing.material_override = _material(Color(0.13, 0.17, 0.21))
    _head.add_child(housing)
    var lens := MeshInstance3D.new()
    var lens_mesh := SphereMesh.new()
    lens_mesh.radius = 0.075
    lens.mesh = lens_mesh
    lens.position = Vector3(0.0, 0.0, -0.2)
    lens.scale = Vector3(1.0, 1.0, 0.45)
    lens.material_override = _material(Color(0.08, 0.48, 0.68), 0.22, true)
    _head.add_child(lens)
    _lens_light = OmniLight3D.new()
    _lens_light.position = Vector3(0.0, 0.0, -0.3)
    _lens_light.omni_range = 1.4
    _lens_light.shadow_enabled = false
    _head.add_child(_lens_light)
    set_alert_active(false)

func _material(color: Color, roughness: float = 0.7, glow: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 0.8
    return material

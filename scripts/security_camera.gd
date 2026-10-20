extends Node3D

@export var detection_range: float = 9.0
@export_range(10.0, 100.0, 1.0) var field_of_view: float = 66.0
@export var sweep_degrees: float = 34.0
@export var sweep_speed: float = 0.72

var _head: Node3D
var _lens_light: OmniLight3D
var _vision_cone: MeshInstance3D
var _vision_material: StandardMaterial3D
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
    if is_instance_valid(_vision_material):
        _vision_material.albedo_color = Color(1.0, 0.055, 0.035, 0.2) if active else Color(0.12, 0.62, 0.95, 0.12)

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
    _build_vision_cone()
    set_alert_active(false)

func _build_vision_cone() -> void:
    # A subtle floor projection shows the live field of view without a costly
    # volumetric effect, which is important for mobile rendering.
    _vision_cone = MeshInstance3D.new()
    _vision_cone.name = "VisionCone"
    var vertices := PackedVector3Array()
    var segments := 28
    var floor_y := -2.72
    for index in range(segments):
        var angle_a := -deg_to_rad(field_of_view * 0.5) + deg_to_rad(field_of_view) * float(index) / float(segments)
        var angle_b := -deg_to_rad(field_of_view * 0.5) + deg_to_rad(field_of_view) * float(index + 1) / float(segments)
        vertices.append(Vector3(0.0, floor_y, 0.0))
        vertices.append(Vector3(sin(angle_a) * detection_range, floor_y, -cos(angle_a) * detection_range))
        vertices.append(Vector3(sin(angle_b) * detection_range, floor_y, -cos(angle_b) * detection_range))
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    var cone_mesh := ArrayMesh.new()
    cone_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    _vision_cone.mesh = cone_mesh
    _vision_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _vision_material = StandardMaterial3D.new()
    _vision_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _vision_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _vision_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    _vision_material.roughness = 1.0
    _vision_material.albedo_color = Color(0.12, 0.62, 0.95, 0.12)
    _vision_cone.material_override = _vision_material
    _head.add_child(_vision_cone)

func _material(color: Color, roughness: float = 0.7, glow: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 0.8
    return material

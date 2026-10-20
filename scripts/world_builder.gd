extends Node3D

const CameraScene = preload("res://scenes/security_camera.tscn")
var level_id: String = "apartment"
var _exit_hinge: Node3D
var _exit_target: Node3D
var _exit_unlocked: bool = false

func _ready() -> void:
    if level_id == "store":
        _build_store_room()
        _build_store_furniture()
        _build_store_decor()
    else:
        _build_room()
        _build_partitions()
        _build_furniture()
        _build_decor()
    _build_collectibles()
    _build_exit()
    _build_security_cameras()
    _build_camera()

func unlock_exit() -> void:
    if _exit_unlocked:
        return
    _exit_unlocked = true
    if is_instance_valid(_exit_hinge):
        var tween := create_tween()
        tween.tween_property(_exit_hinge, "rotation:y", deg_to_rad(-98.0), 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    if is_instance_valid(_exit_target):
        _exit_target.set_meta("unlocked", true)

func _material(color: Color, roughness: float = 0.82, metalness: float = 0.0, glow: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metalness
    if color.a < 0.99:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.25
    return material

func _mesh_box(parent: Node3D, name_value: String, position: Vector3, size: Vector3, color: Color, roughness: float = 0.82) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = name_value
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, roughness)
    parent.add_child(mesh_instance)
    return mesh_instance

func _box(name_value: String, position: Vector3, size: Vector3, color: Color, collision: bool = true) -> MeshInstance3D:
    if collision:
        var body := StaticBody3D.new()
        body.name = name_value
        body.position = position
        add_child(body)
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = size
        shape.shape = box_shape
        body.add_child(shape)
        return _mesh_box(body, name_value + "Mesh", Vector3.ZERO, size, color)
    return _mesh_box(self, name_value, position, size, color)

func _sphere(parent: Node3D, name_value: String, position: Vector3, scale_value: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = name_value
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    instance.mesh = mesh
    instance.position = position
    instance.scale = scale_value
    instance.material_override = _material(color, 0.48, 0.05, glow)
    parent.add_child(instance)
    return instance

func _cylinder(parent: Node3D, name_value: String, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = name_value
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 16
    instance.mesh = mesh
    instance.position = position
    instance.material_override = _material(color)
    parent.add_child(instance)
    return instance

func _build_store_room() -> void:
    _box("Store polished floor", Vector3(0.0, -0.18, 0.0), Vector3(24.0, 0.35, 20.0), Color(0.19, 0.23, 0.25))
    _box("Store back wall west", Vector3(-9.0, 2.0, -10.0), Vector3(6.0, 4.0, 0.3), Color(0.13, 0.21, 0.26))
    _box("Store back wall east", Vector3(5.0, 2.0, -10.0), Vector3(14.0, 4.0, 0.3), Color(0.13, 0.21, 0.26))
    _box("Store left wall", Vector3(-12.0, 2.0, 0.0), Vector3(0.3, 4.0, 20.0), Color(0.11, 0.18, 0.23))
    _box("Store right wall", Vector3(12.0, 2.0, 0.0), Vector3(0.3, 4.0, 20.0), Color(0.11, 0.18, 0.23))
    _box("Store front wall west", Vector3(-6.7, 1.8, 10.0), Vector3(10.6, 3.6, 0.3), Color(0.11, 0.18, 0.23))
    _box("Store front wall east", Vector3(6.7, 1.8, 10.0), Vector3(10.6, 3.6, 0.3), Color(0.11, 0.18, 0.23))
    _box("Shopfront glass left", Vector3(-6.0, 2.0, 9.79), Vector3(4.5, 2.35, 0.045), Color(0.08, 0.31, 0.4, 0.48), false)
    _box("Shopfront glass right", Vector3(6.0, 2.0, 9.79), Vector3(4.5, 2.35, 0.045), Color(0.08, 0.31, 0.4, 0.48), false)
    _box("Shop entrance mat", Vector3(0.0, 0.018, 8.9), Vector3(2.8, 0.045, 1.25), Color(0.075, 0.26, 0.26), false)
    for x in [-9.5, -6.0, -2.5, 1.0, 4.5, 8.0]:
        _box("Store tile inlay", Vector3(x, 0.012, 0.0), Vector3(0.035, 0.025, 18.8), Color(0.28, 0.32, 0.32), false)
    for z in [-8.4, -0.8, 5.9]:
        _box("Store floor stripe", Vector3(0.0, 0.015, z), Vector3(22.8, 0.02, 0.035), Color(0.34, 0.37, 0.36), false)
    _box("Storefront sign housing", Vector3(0.0, 3.18, -9.72), Vector3(6.4, 0.7, 0.12), Color(0.035, 0.07, 0.085), false)
    var sign := Label3D.new()
    sign.name = "StorefrontSign"
    sign.text = "NIGHT MARKET"
    sign.position = Vector3(0.0, 3.05, -9.63)
    sign.rotation.y = PI
    sign.font_size = 64
    sign.pixel_size = 0.006
    sign.modulate = Color(0.34, 0.94, 0.78)
    sign.outline_size = 8
    sign.outline_modulate = Color(0.015, 0.045, 0.055)
    add_child(sign)

func _build_store_furniture() -> void:
    var shelf_frame := Color(0.16, 0.22, 0.24)
    var shelf_edge := Color(0.47, 0.54, 0.54)
    var shelf_positions: Array[float] = [-8.0, -4.0, 0.0, 4.0, 8.0]
    var product_colors: Array[Color] = [
        Color(0.78, 0.23, 0.18),
        Color(0.18, 0.56, 0.68),
        Color(0.87, 0.62, 0.22),
        Color(0.28, 0.54, 0.31),
        Color(0.53, 0.35, 0.69)
    ]
    for row in range(shelf_positions.size()):
        var x: float = shelf_positions[row]
        _box("Aisle shelf left upright %d" % row, Vector3(x - 0.56, 0.9, -4.45), Vector3(0.095, 1.8, 6.35), shelf_frame)
        _box("Aisle shelf right upright %d" % row, Vector3(x + 0.56, 0.9, -4.45), Vector3(0.095, 1.8, 6.35), shelf_frame)
        for shelf_level in [0.42, 0.98, 1.53]:
            _box("Shelf deck %d %.2f" % [row, shelf_level], Vector3(x, shelf_level, -4.45), Vector3(1.12, 0.075, 6.35), shelf_edge, false)
        for section in range(4):
            var z: float = -6.65 + float(section) * 1.48
            for layer in range(2):
                for side_index in range(2):
                    var offset_x: float = -0.27 if side_index == 0 else 0.27
                    var color_index: int = (row + section + layer + side_index) % product_colors.size()
                    _box("Stock %d %d %d %d" % [row, section, layer, side_index], Vector3(x + offset_x, 0.67 + float(layer) * 0.57, z), Vector3(0.24, 0.34, 0.31), product_colors[color_index], false)
    _box("Checkout counter", Vector3(-8.7, 0.63, 4.75), Vector3(4.1, 1.25, 1.25), Color(0.21, 0.27, 0.28))
    _box("Checkout countertop", Vector3(-8.7, 1.29, 4.75), Vector3(4.18, 0.12, 1.34), Color(0.54, 0.57, 0.53), false)
    _box("Checkout front panel", Vector3(-8.7, 0.65, 4.1), Vector3(3.85, 0.82, 0.045), Color(0.09, 0.16, 0.18), false)
    _box("Register base", Vector3(-7.75, 1.48, 4.43), Vector3(0.72, 0.28, 0.45), Color(0.07, 0.09, 0.105))
    _box("Register display", Vector3(-7.75, 1.73, 4.4), Vector3(0.62, 0.28, 0.09), Color(0.2, 0.69, 0.58), false)
    _box("Barcode scanner", Vector3(-9.0, 1.4, 4.5), Vector3(0.52, 0.07, 0.36), Color(0.095, 0.13, 0.14), false)
    for basket_index in range(3):
        _box("Shopping basket %d" % basket_index, Vector3(-10.7 + basket_index * 0.7, 0.26, 6.55), Vector3(0.55, 0.42, 0.65), Color(0.13, 0.42, 0.46))
    _box("Staff desk", Vector3(8.7, 0.58, 4.85), Vector3(3.0, 1.1, 1.3), Color(0.28, 0.2, 0.14))
    _box("Staff desk top", Vector3(8.7, 1.17, 4.85), Vector3(3.08, 0.1, 1.38), Color(0.45, 0.34, 0.23), false)
    _box("Staff locker", Vector3(10.65, 1.05, 6.7), Vector3(1.15, 2.0, 0.8), Color(0.23, 0.3, 0.31))
    _box("Staff locker handle", Vector3(10.04, 1.1, 6.7), Vector3(0.055, 0.5, 0.07), Color(0.74, 0.71, 0.6), false)
    _box("Cold display", Vector3(10.55, 1.16, -5.1), Vector3(1.4, 2.25, 5.7), Color(0.2, 0.28, 0.31))
    _box("Cold display glass", Vector3(9.82, 1.2, -5.1), Vector3(0.035, 1.85, 5.2), Color(0.17, 0.49, 0.57, 0.44), false)
    for z in [-6.8, -5.1, -3.4]:
        _box("Cooler light", Vector3(9.79, 1.2, z), Vector3(0.025, 0.04, 1.35), Color(0.25, 0.85, 0.88), false)
    for x in [-4.2, -2.2]:
        _cylinder(self, "Queue post", Vector3(x, 0.46, 6.55), 0.065, 0.9, shelf_edge)
    _box("Queue belt", Vector3(-3.2, 0.65, 6.55), Vector3(1.95, 0.045, 0.06), Color(0.72, 0.31, 0.16), false)

func _build_store_decor() -> void:
    var signs: Array[String] = ["SNACKS", "HOME", "TECH", "TOYS", "DAILY"]
    var aisle_x: Array[float] = [-8.0, -4.0, 0.0, 4.0, 8.0]
    for index in range(signs.size()):
        var x: float = aisle_x[index]
        _box("Aisle marker board %d" % index, Vector3(x, 2.04, -0.95), Vector3(1.1, 0.27, 0.11), Color(0.035, 0.085, 0.095), false)
        var marker_text := Label3D.new()
        marker_text.name = "Aisle marker label %d" % index
        marker_text.text = signs[index]
        marker_text.position = Vector3(x, 2.06, -0.875)
        marker_text.rotation.y = PI
        marker_text.font_size = 38
        marker_text.pixel_size = 0.004
        marker_text.modulate = Color(0.74, 0.91, 0.88)
        add_child(marker_text)
    _box("Wall poster frame", Vector3(11.77, 2.2, 2.5), Vector3(0.08, 1.65, 2.2), Color(0.06, 0.11, 0.12), false)
    _box("Wall poster", Vector3(11.71, 2.2, 2.5), Vector3(0.025, 1.42, 1.95), Color(0.15, 0.42, 0.39), false)
    _box("Break room poster frame", Vector3(-11.77, 2.15, -3.3), Vector3(0.08, 1.4, 1.8), Color(0.42, 0.27, 0.15), false)
    _box("Break room poster", Vector3(-11.71, 2.15, -3.3), Vector3(0.025, 1.18, 1.58), Color(0.2, 0.37, 0.45), false)

func _build_room() -> void:
    _box("Wooden floor", Vector3(0.0, -0.18, 0.0), Vector3(24.0, 0.35, 20.0), Color(0.25, 0.17, 0.125))
    # Outer walls leave clear openings for a wide window and the front exit.
    _box("Back wall west", Vector3(-9.0, 2.0, -10.0), Vector3(6.0, 4.0, 0.3), Color(0.17, 0.23, 0.3))
    _box("Back wall east", Vector3(5.0, 2.0, -10.0), Vector3(14.0, 4.0, 0.3), Color(0.17, 0.23, 0.3))
    _box("Left wall", Vector3(-12.0, 2.0, 0.0), Vector3(0.3, 4.0, 20.0), Color(0.14, 0.2, 0.27))
    _box("Right wall", Vector3(12.0, 2.0, 0.0), Vector3(0.3, 4.0, 20.0), Color(0.14, 0.2, 0.27))
    _box("Front wall west", Vector3(-6.7, 1.8, 10.0), Vector3(10.6, 3.6, 0.3), Color(0.14, 0.2, 0.27))
    _box("Front wall east", Vector3(6.7, 1.8, 10.0), Vector3(10.6, 3.6, 0.3), Color(0.14, 0.2, 0.27))
    # Floor zones use non-colliding inlays; the walls remain open enough for mobile navigation.
    _box("Kitchen tile", Vector3(-6.8, 0.012, -5.8), Vector3(9.8, 0.04, 8.0), Color(0.31, 0.37, 0.38), false)
    _box("Living room rug", Vector3(2.0, 0.025, 1.55), Vector3(7.2, 0.05, 5.4), Color(0.22, 0.105, 0.13), false)
    _box("Bedroom carpet", Vector3(7.2, 0.025, -6.0), Vector3(7.2, 0.05, 7.0), Color(0.22, 0.21, 0.29), false)
    _box("Bathroom tile", Vector3(-8.0, 0.018, 5.6), Vector3(6.5, 0.05, 6.0), Color(0.28, 0.36, 0.38), false)
    # Window: blue panes, metal bars and a sill.
    _box("Window glass", Vector3(-4.0, 2.45, -9.79), Vector3(3.8, 1.65, 0.045), Color(0.075, 0.24, 0.38), false)
    _box("Window frame top", Vector3(-4.0, 3.31, -9.74), Vector3(4.05, 0.11, 0.12), Color(0.62, 0.66, 0.64), false)
    _box("Window frame bottom", Vector3(-4.0, 1.58, -9.74), Vector3(4.05, 0.11, 0.12), Color(0.62, 0.66, 0.64), false)
    _box("Window frame left", Vector3(-6.0, 2.45, -9.74), Vector3(0.11, 1.8, 0.12), Color(0.62, 0.66, 0.64), false)
    _box("Window frame right", Vector3(-2.0, 2.45, -9.74), Vector3(0.11, 1.8, 0.12), Color(0.62, 0.66, 0.64), false)
    _box("Window mullion", Vector3(-4.0, 2.45, -9.72), Vector3(0.075, 1.7, 0.12), Color(0.62, 0.66, 0.64), false)
    # Baseboards and architectural trim.
    _box("Left baseboard", Vector3(-11.78, 0.11, 0.0), Vector3(0.1, 0.22, 19.5), Color(0.38, 0.29, 0.22), false)
    _box("Right baseboard", Vector3(11.78, 0.11, 0.0), Vector3(0.1, 0.22, 19.5), Color(0.38, 0.29, 0.22), false)
    _box("Back baseboard east", Vector3(5.0, 0.11, -9.78), Vector3(14.0, 0.22, 0.1), Color(0.38, 0.29, 0.22), false)
    _box("Back baseboard west", Vector3(-9.0, 0.11, -9.78), Vector3(6.0, 0.22, 0.1), Color(0.38, 0.29, 0.22), false)

func _build_partitions() -> void:
    var plaster := Color(0.22, 0.29, 0.34)
    # Bedroom divider, with a broad passage at the center.
    _box("Bedroom divider west", Vector3(3.5, 1.45, -2.4), Vector3(3.0, 2.9, 0.22), plaster)
    _box("Bedroom divider east", Vector3(10.1, 1.45, -2.4), Vector3(3.8, 2.9, 0.22), plaster)
    _box("Bedroom divider trim", Vector3(3.5, 2.94, -2.4), Vector3(3.1, 0.08, 0.28), Color(0.39, 0.3, 0.24), false)
    # Short kitchen divider creates separate rooms without trapping the player.
    _box("Kitchen divider north", Vector3(-1.6, 1.25, -7.8), Vector3(0.22, 2.5, 4.0), plaster)
    _box("Kitchen divider south", Vector3(-1.6, 1.25, -1.1), Vector3(0.22, 2.5, 2.4), plaster)
    _box("Bathroom divider", Vector3(-4.3, 1.25, 5.9), Vector3(0.22, 2.5, 5.0), plaster)

func _build_furniture() -> void:
    var wood := Color(0.3, 0.17, 0.105)
    var wood_light := Color(0.43, 0.26, 0.16)
    var cream := Color(0.66, 0.59, 0.47)
    var metal := Color(0.47, 0.53, 0.56)
    # Kitchen: cabinets, counter, refrigerator and a sink.
    _box("Kitchen counter", Vector3(-8.0, 0.65, -7.5), Vector3(5.8, 1.3, 1.0), wood)
    _box("Countertop", Vector3(-8.0, 1.33, -7.5), Vector3(5.95, 0.12, 1.13), cream, false)
    _box("Cabinet door A", Vector3(-9.75, 0.66, -6.97), Vector3(1.5, 0.9, 0.035), wood_light, false)
    _box("Cabinet door B", Vector3(-8.0, 0.66, -6.97), Vector3(1.5, 0.9, 0.035), wood_light, false)
    _box("Cabinet door C", Vector3(-6.25, 0.66, -6.97), Vector3(1.5, 0.9, 0.035), wood_light, false)
    _box("Fridge", Vector3(-10.2, 1.35, -5.7), Vector3(1.1, 2.6, 1.1), Color(0.58, 0.66, 0.69))
    _box("Fridge handle", Vector3(-9.62, 1.38, -5.45), Vector3(0.045, 0.75, 0.045), metal, false)
    _box("Sink basin", Vector3(-6.2, 1.4, -7.5), Vector3(0.85, 0.08, 0.6), Color(0.24, 0.31, 0.33), false)
    _cylinder(self, "Tap stem", Vector3(-6.2, 1.54, -7.72), 0.035, 0.25, metal)
    _box("Dining table", Vector3(-4.15, 0.87, -2.3), Vector3(3.0, 0.16, 1.75), wood)
    for x in [-5.1, -3.2]:
        for z in [-2.85, -1.7]:
            _box("Dining chair seat", Vector3(x, 0.48, z), Vector3(0.65, 0.12, 0.6), Color(0.19, 0.13, 0.09))
            _box("Dining chair back", Vector3(x, 0.81, z - 0.24), Vector3(0.65, 0.58, 0.1), Color(0.19, 0.13, 0.09))
    # Living room.
    _box("Sofa base", Vector3(2.0, 0.45, 1.15), Vector3(4.2, 0.58, 1.45), Color(0.36, 0.2, 0.17))
    _box("Sofa back", Vector3(2.0, 0.91, 0.48), Vector3(4.2, 0.82, 0.32), Color(0.43, 0.25, 0.21))
    for x in [0.55, 2.0, 3.45]:
        _box("Sofa cushion", Vector3(x, 0.78, 1.1), Vector3(1.28, 0.2, 1.2), Color(0.5, 0.31, 0.26), false)
        _box("Sofa pillow", Vector3(x, 1.02, 0.84), Vector3(0.55, 0.36, 0.18), Color(0.75, 0.61, 0.45), false)
    _box("Coffee table", Vector3(2.0, 0.43, 3.1), Vector3(2.5, 0.12, 1.1), wood_light)
    for x in [0.95, 3.05]:
        for z in [2.75, 3.45]:
            _box("Coffee table leg", Vector3(x, 0.22, z), Vector3(0.09, 0.38, 0.09), wood)
    _box("TV console", Vector3(2.0, 0.46, -1.15), Vector3(3.3, 0.72, 0.55), wood)
    _box("TV screen frame", Vector3(2.0, 1.38, -1.32), Vector3(2.4, 1.42, 0.16), Color(0.035, 0.045, 0.055))
    _box("TV screen", Vector3(2.0, 1.39, -1.225), Vector3(2.18, 1.2, 0.025), Color(0.055, 0.18, 0.24), false)
    # Bedroom furniture and bedside lamp.
    _box("Bed frame", Vector3(7.4, 0.34, -6.1), Vector3(3.4, 0.42, 4.5), wood)
    _box("Mattress", Vector3(7.4, 0.64, -6.1), Vector3(3.2, 0.26, 4.3), Color(0.62, 0.66, 0.7), false)
    _box("Duvet", Vector3(7.4, 0.79, -5.7), Vector3(3.05, 0.12, 3.2), Color(0.35, 0.42, 0.53), false)
    _box("Bed headboard", Vector3(7.4, 1.0, -8.25), Vector3(3.4, 1.25, 0.18), wood_light)
    _box("Pillow left", Vector3(6.65, 0.91, -7.65), Vector3(1.0, 0.18, 0.65), Color(0.82, 0.8, 0.72), false)
    _box("Pillow right", Vector3(8.15, 0.91, -7.65), Vector3(1.0, 0.18, 0.65), Color(0.82, 0.8, 0.72), false)
    _box("Wardrobe", Vector3(10.3, 1.45, -8.25), Vector3(2.3, 2.9, 1.1), wood)
    _box("Wardrobe left door", Vector3(9.76, 1.48, -7.68), Vector3(1.02, 2.65, 0.035), wood_light, false)
    _box("Wardrobe right door", Vector3(10.83, 1.48, -7.68), Vector3(1.02, 2.65, 0.035), wood_light, false)
    _box("Bedside table", Vector3(9.95, 0.42, -3.75), Vector3(0.95, 0.75, 0.7), wood)
    _box("Bedside drawer", Vector3(9.95, 0.47, -3.37), Vector3(0.7, 0.2, 0.035), wood_light, false)
    _cylinder(self, "Bedside lamp base", Vector3(9.95, 0.85, -3.75), 0.18, 0.08, metal)
    _cylinder(self, "Bedside lamp shade", Vector3(9.95, 1.08, -3.75), 0.22, 0.27, Color(0.9, 0.68, 0.35))
    var bedside_light := OmniLight3D.new()
    bedside_light.position = Vector3(9.95, 1.15, -3.75)
    bedside_light.light_color = Color(1.0, 0.63, 0.31)
    bedside_light.light_energy = 0.38
    bedside_light.omni_range = 3.8
    bedside_light.shadow_enabled = false
    add_child(bedside_light)
    # Bathroom: vanity, mirror, towels and washer.
    _box("Bathroom vanity", Vector3(-8.1, 0.67, 4.0), Vector3(1.8, 1.28, 0.82), cream)
    _box("Bathroom basin", Vector3(-8.1, 1.34, 4.0), Vector3(1.55, 0.12, 0.7), Color(0.72, 0.78, 0.79), false)
    _box("Bathroom mirror", Vector3(-8.1, 2.17, 3.56), Vector3(1.55, 1.25, 0.06), Color(0.18, 0.34, 0.42), false)
    _box("Mirror frame", Vector3(-8.1, 2.17, 3.51), Vector3(1.68, 1.38, 0.06), wood_light, false)
    _box("Washing machine", Vector3(-10.5, 0.72, 7.0), Vector3(1.2, 1.38, 1.15), Color(0.61, 0.68, 0.7))
    _cylinder(self, "Washing machine door", Vector3(-10.5, 0.72, 6.405), 0.37, 0.06, Color(0.16, 0.24, 0.29))
    _box("Folded towels", Vector3(-6.9, 1.55, 4.0), Vector3(0.58, 0.15, 0.42), Color(0.78, 0.82, 0.78), false)

func _build_decor() -> void:
    var wood_light := Color(0.43, 0.26, 0.16)
    # Framed artwork on the main walls.
    _box("Living painting frame", Vector3(6.2, 2.05, 9.78), Vector3(1.8, 1.2, 0.09), Color(0.42, 0.29, 0.18), false)
    _box("Living painting", Vector3(6.2, 2.05, 9.71), Vector3(1.58, 0.98, 0.025), Color(0.09, 0.31, 0.36), false)
    _sphere(self, "Art sun", Vector3(6.52, 2.25, 9.68), Vector3(0.4, 0.4, 0.04), Color(0.93, 0.59, 0.29), true)
    _box("Bedroom artwork frame", Vector3(11.77, 2.3, -3.7), Vector3(0.09, 1.3, 1.7), wood_light, false)
    _box("Bedroom artwork", Vector3(11.71, 2.3, -3.7), Vector3(0.025, 1.08, 1.45), Color(0.19, 0.34, 0.4), false)
    _sphere(self, "Artwork moon", Vector3(11.68, 2.48, -3.9), Vector3(0.04, 0.38, 0.38), Color(0.91, 0.74, 0.48), true)
    # Plants, books, small kitchen props.
    _cylinder(self, "Plant pot", Vector3(9.2, 0.37, 2.15), 0.32, 0.62, Color(0.5, 0.21, 0.14))
    _sphere(self, "Plant leaf A", Vector3(9.0, 0.92, 2.15), Vector3(0.27, 0.48, 0.24), Color(0.13, 0.35, 0.21))
    _sphere(self, "Plant leaf B", Vector3(9.4, 0.9, 2.04), Vector3(0.24, 0.44, 0.22), Color(0.17, 0.43, 0.25))
    _sphere(self, "Plant leaf C", Vector3(9.2, 1.13, 2.22), Vector3(0.23, 0.4, 0.2), Color(0.2, 0.47, 0.27))
    _box("Cookbook red", Vector3(-6.2, 1.45, -7.5), Vector3(0.45, 0.12, 0.55), Color(0.59, 0.16, 0.14), false)
    _box("Cookbook green", Vector3(-6.2, 1.57, -7.5), Vector3(0.4, 0.1, 0.51), Color(0.19, 0.42, 0.29), false)
    _cylinder(self, "Kitchen jar", Vector3(-9.5, 1.58, -7.52), 0.11, 0.38, Color(0.73, 0.79, 0.79))
    # Warm practical lights along the living space.
    _cylinder(self, "Floor lamp stem", Vector3(4.85, 1.15, 2.0), 0.045, 2.25, Color(0.24, 0.22, 0.2))
    _cylinder(self, "Floor lamp shade", Vector3(4.85, 2.35, 2.0), 0.28, 0.34, Color(0.83, 0.67, 0.43))
    var floor_light := OmniLight3D.new()
    floor_light.position = Vector3(4.85, 2.3, 2.0)
    floor_light.light_color = Color(1.0, 0.7, 0.43)
    floor_light.light_energy = 0.48
    floor_light.omni_range = 5.2
    floor_light.shadow_enabled = false
    add_child(floor_light)

func _build_collectibles() -> void:
    if level_id == "store":
        _item("Смартфон покупателя", "loot", Vector3(-8.7, 1.45, 4.55), Vector3(0.28, 0.055, 0.46), Color(0.18, 0.78, 0.94))
        _item("Коллекционная фигурка", "loot", Vector3(-4.0, 1.56, -3.65), Vector3(0.28, 0.33, 0.28), Color(0.91, 0.43, 0.17))
        _item("Игровая приставка", "loot", Vector3(0.0, 1.62, -5.05), Vector3(0.52, 0.22, 0.34), Color(0.25, 0.75, 0.95))
        _item("Дорогие часы", "loot", Vector3(4.0, 1.58, -2.95), Vector3(0.37, 0.12, 0.3), Color(0.95, 0.75, 0.2))
        _item("Конверт из сейфа", "loot", Vector3(8.25, 1.28, 4.65), Vector3(0.42, 0.055, 0.3), Color(0.23, 0.82, 0.4))
        var store_stains: Array[Vector3] = [
            Vector3(-6.1, 0.018, 1.0),
            Vector3(-2.0, 0.018, 2.2),
            Vector3(2.1, 0.018, 1.0),
            Vector3(6.2, 0.018, 1.7),
            Vector3(-6.0, 0.018, -8.1),
            Vector3(2.0, 0.018, -8.1),
            Vector3(8.5, 0.018, 0.0)
        ]
        for store_index in range(store_stains.size()):
            _item("Разлив в магазине %d" % (store_index + 1), "dirt", store_stains[store_index], Vector3(0.8, 0.035, 0.55), Color(0.12, 0.075, 0.042), 3)
        return
    _item("Золотые часы", "loot", Vector3(-8.0, 1.45, -7.5), Vector3(0.42, 0.12, 0.32), Color(0.98, 0.67, 0.17))
    _item("Шкатулка", "loot", Vector3(-4.15, 1.05, -2.3), Vector3(0.42, 0.28, 0.36), Color(0.85, 0.2, 0.36))
    _item("Редкая приставка", "loot", Vector3(2.8, 0.9, -1.12), Vector3(0.56, 0.22, 0.34), Color(0.23, 0.73, 0.91))
    _item("Кольцо с камнем", "loot", Vector3(9.6, 0.86, -3.75), Vector3(0.24, 0.24, 0.24), Color(0.18, 0.95, 0.78), 2)
    _item("Конверт с деньгами", "loot", Vector3(2.0, 0.55, 3.1), Vector3(0.42, 0.055, 0.3), Color(0.26, 0.78, 0.34))
    var stains := [
        Vector3(-8.9, 0.018, -2.2),
        Vector3(-3.3, 0.018, 0.2),
        Vector3(0.0, 0.018, 4.75),
        Vector3(5.2, 0.018, 4.9),
        Vector3(8.85, 0.018, 1.0),
        Vector3(-7.1, 0.018, 7.4),
        Vector3(4.25, 0.018, -3.1)
    ]
    for index in range(stains.size()):
        _item("Грязное пятно %d" % (index + 1), "dirt", stains[index], Vector3(0.78, 0.035, 0.52), Color(0.13, 0.085, 0.052), 3)

func _item(label: String, kind: String, position_value: Vector3, size: Vector3, color: Color, shape_kind: int = 0) -> Node3D:
    var item := Node3D.new()
    item.name = label
    item.position = position_value
    item.add_to_group("interactable")
    item.set_meta("kind", kind)
    item.set_meta("label", label)
    if kind == "loot":
        item.set_script(load("res://scripts/loot_animation.gd"))
    add_child(item)
    var instance := MeshInstance3D.new()
    instance.name = "Visual"
    if shape_kind == 1:
        var sphere_mesh := SphereMesh.new()
        sphere_mesh.radius = 0.5
        sphere_mesh.height = 1.0
        instance.mesh = sphere_mesh
        instance.scale = size
    elif shape_kind == 2:
        var torus := TorusMesh.new()
        torus.inner_radius = 0.21
        torus.outer_radius = 0.45
        torus.rings = 12
        torus.ring_segments = 8
        instance.mesh = torus
        instance.scale = size
    elif shape_kind == 3:
        var stain_mesh := CylinderMesh.new()
        stain_mesh.top_radius = 0.47
        stain_mesh.bottom_radius = 0.39
        stain_mesh.height = 0.018
        stain_mesh.radial_segments = 18
        instance.mesh = stain_mesh
        instance.scale = Vector3(size.x, 1.0, size.z)
    else:
        var box_mesh := BoxMesh.new()
        box_mesh.size = size
        instance.mesh = box_mesh
    instance.material_override = _material(color, 0.35, 0.05, kind == "loot")
    item.add_child(instance)
    if kind == "loot":
        var light := OmniLight3D.new()
        light.light_color = color
        light.light_energy = 0.38
        light.omni_range = 1.5
        light.shadow_enabled = false
        light.position.y = 0.28
        item.add_child(light)
        var ring := MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = 0.38
        ring_mesh.outer_radius = 0.42
        ring_mesh.rings = 8
        ring_mesh.ring_segments = 16
        ring.mesh = ring_mesh
        ring.position.y = 0.35
        ring.rotation.x = deg_to_rad(90.0)
        ring.material_override = _material(Color(color.r, color.g, color.b, 0.65), 0.3, 0.05, true)
        item.add_child(ring)
    return item

func _build_exit() -> void:
    # Door frame with a hinge that swings open when every task is complete.
    _box("Exit frame left", Vector3(-0.72, 1.2, 9.77), Vector3(0.14, 2.4, 0.26), Color(0.45, 0.3, 0.19), false)
    _box("Exit frame right", Vector3(0.72, 1.2, 9.77), Vector3(0.14, 2.4, 0.26), Color(0.45, 0.3, 0.19), false)
    _box("Exit frame top", Vector3(0.0, 2.35, 9.77), Vector3(1.55, 0.14, 0.26), Color(0.45, 0.3, 0.19), false)
    _exit_hinge = StaticBody3D.new()
    _exit_hinge.name = "ExitDoorHinge"
    _exit_hinge.position = Vector3(-0.62, 0.0, 9.72)
    add_child(_exit_hinge)
    var door_collision := CollisionShape3D.new()
    var door_shape := BoxShape3D.new()
    door_shape.size = Vector3(1.2, 2.25, 0.12)
    door_collision.shape = door_shape
    door_collision.position = Vector3(0.62, 1.15, 0.0)
    _exit_hinge.add_child(door_collision)
    _mesh_box(_exit_hinge, "Exit door", Vector3(0.62, 1.15, 0.0), Vector3(1.2, 2.25, 0.12), Color(0.16, 0.35, 0.39))
    _mesh_box(_exit_hinge, "Door window", Vector3(0.62, 1.52, -0.07), Vector3(0.42, 0.55, 0.025), Color(0.09, 0.22, 0.28), 0.35)
    _sphere(_exit_hinge, "Door handle", Vector3(0.98, 1.0, -0.1), Vector3(0.07, 0.07, 0.07), Color(0.92, 0.68, 0.27), true)
    _exit_target = Node3D.new()
    _exit_target.name = "ExitInteraction"
    _exit_target.position = Vector3(0.0, 0.9, 8.75)
    _exit_target.add_to_group("interactable")
    _exit_target.set_meta("kind", "exit")
    _exit_target.set_meta("label", "Выход")
    _exit_target.set_meta("unlocked", false)
    add_child(_exit_target)
    var marker := MeshInstance3D.new()
    var marker_mesh := CylinderMesh.new()
    marker_mesh.top_radius = 0.48
    marker_mesh.bottom_radius = 0.48
    marker_mesh.height = 0.018
    marker.mesh = marker_mesh
    marker.position = Vector3(0.0, 0.03, 8.72)
    marker.material_override = _material(Color(0.2, 0.72, 0.55, 0.65), 0.3, 0.0, true)
    add_child(marker)

func _build_camera() -> void:
    var camera := Camera3D.new()
    camera.name = "FollowCamera"
    camera.position = Vector3(0.0, 10.0, 11.0)
    camera.rotation_degrees = Vector3(-42.0, 0.0, 0.0)
    camera.current = true
    camera.fov = 58.0
    camera.set_script(load("res://scripts/follow_camera.gd"))
    add_child(camera)

func _build_security_cameras() -> void:
    var positions: Array[Vector3] = [
        Vector3(-10.8, 3.0, -8.2),
        Vector3(10.75, 3.0, 0.2),
        Vector3(8.2, 3.0, -9.2)
    ]
    if level_id == "store":
        positions = [
            Vector3(-10.8, 3.0, -8.2),
            Vector3(10.75, 3.0, 7.2),
            Vector3(8.2, 3.0, -8.8)
        ]
    for index in range(positions.size()):
        var camera := CameraScene.instantiate() as Node3D
        camera.name = "SecurityCamera%d" % (index + 1)
        camera.position = positions[index]
        var direction := Vector3(-positions[index].x, 0.0, -positions[index].z)
        camera.rotation.y = atan2(-direction.x, -direction.z)
        if index == 2:
            camera.rotation.y = deg_to_rad(155.0)
        add_child(camera)

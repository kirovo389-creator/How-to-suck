extends Node3D
func _ready():
    _build_room()
    _furniture()
    _collectibles()
    _camera()

func _mat(c: Color, rough := 0.85) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    return m

func _box(n: String,p: Vector3,s: Vector3,c: Color,collision := true):
    if collision:
        var body = StaticBody3D.new()
        body.name = n
        body.position = p
        add_child(body)
        var cs = CollisionShape3D.new()
        var shape = BoxShape3D.new()
        shape.size = s
        cs.shape = shape
        body.add_child(cs)
        var mesh = MeshInstance3D.new()
        mesh.name = n+"Mesh"
        var bm = BoxMesh.new()
        bm.size = s
        mesh.mesh = bm
        mesh.material_override = _mat(c)
        body.add_child(mesh)
    else:
        var mesh = MeshInstance3D.new()
        mesh.name = n
        var bm = BoxMesh.new()
        bm.size = s
        mesh.mesh = bm
        mesh.position = p
        mesh.material_override = _mat(c)
        add_child(mesh)

func _build_room():
    _box("Wood floor",Vector3(0,-0.18,0),Vector3(24,0.35,20),Color(0.31,0.2,0.13))
    _box("Back wall",Vector3(0,2,-10),Vector3(24,4,0.3),Color(0.23,0.29,0.34))
    _box("Left wall",Vector3(-12,2,0),Vector3(0.3,4,20),Color(0.19,0.25,0.31))
    _box("Right wall",Vector3(12,2,0),Vector3(0.3,4,20),Color(0.19,0.25,0.31))
    _box("Front wall",Vector3(0,1.3,10),Vector3(24,2.6,0.3),Color(0.19,0.25,0.31))
    _box("Kitchen tile",Vector3(-6,0.012,-4.8),Vector3(7,0.04,7),Color(0.42,0.46,0.44),false)
    _box("Living rug",Vector3(2,0.025,1),Vector3(7,0.05,5),Color(0.28,0.12,0.16),false)
    _box("Window",Vector3(-3.8,2.45,-9.78),Vector3(3.5,1.6,0.04),Color(0.13,0.28,0.42),false)
    _box("Bedroom carpet",Vector3(7,0.025,-5.2),Vector3(7,0.05,7),Color(0.28,0.25,0.33),false)
    _box("Bathroom tiles",Vector3(-7,0.02,5.5),Vector3(6,0.04,6),Color(0.35,0.43,0.45),false)

func _furniture():
    var wood = Color(0.32,0.16,0.09)
    var cream = Color(0.66,0.59,0.47)
    _box("Kitchen counter",Vector3(-8,0.65,-7.5),Vector3(5.8,1.3,1),wood)
    _box("Counter top",Vector3(-8,1.34,-7.5),Vector3(6,0.12,1.12),cream,false)
    _box("Fridge",Vector3(-10.2,1.35,-5.7),Vector3(1.1,2.6,1.1),Color(0.64,0.7,0.73))
    _box("Dining table",Vector3(-4,0.9,-2.1),Vector3(3.2,0.18,2),wood)
    for x in [-5.2,-2.8]:
        for z in [-2.8,-1.4]:
            _box("Chair seat",Vector3(x,0.48,z),Vector3(0.75,0.12,0.72),Color(0.22,0.15,0.11))
            _box("Chair back",Vector3(x,0.9,z-0.3),Vector3(0.75,0.8,0.12),Color(0.22,0.15,0.11))
    _box("Sofa base",Vector3(2,0.48,1.1),Vector3(4.2,0.65,1.45),Color(0.42,0.24,0.19))
    _box("Sofa back",Vector3(2,1,0.45),Vector3(4.2,0.9,0.3),Color(0.49,0.29,0.23))
    for x in [0.6,2,3.4]:
        _box("Sofa cushion",Vector3(x,0.86,1.1),Vector3(1.25,0.22,1.2),Color(0.58,0.36,0.28),false)
    _box("Coffee table",Vector3(2,0.45,3.1),Vector3(2.5,0.12,1.1),wood)
    _box("Bed frame",Vector3(7,0.38,-5.2),Vector3(4,0.45,4.5),wood)
    _box("Mattress",Vector3(7,0.72,-5.2),Vector3(3.8,0.35,4.3),Color(0.66,0.68,0.72),false)
    _box("Pillow",Vector3(7,0.97,-7),Vector3(1.5,0.16,0.7),Color(0.86,0.83,0.73),false)
    _box("Wardrobe",Vector3(10.3,1.5,-8.2),Vector3(2.3,3,1.1),wood)
    _box("Bathroom sink",Vector3(-7,0.85,4.2),Vector3(1.7,1.7,0.8),cream)
    _box("Mirror",Vector3(-7,2.2,3.75),Vector3(1.5,1.5,0.08),Color(0.28,0.42,0.48),false)
    _box("TV",Vector3(2,1.5,-2.2),Vector3(2.7,1.5,0.15),Color(0.015,0.025,0.035),false)
    _box("TV screen",Vector3(2,1.52,-2.1),Vector3(2.4,1.2,0.025),Color(0.05,0.16,0.22),false)
    _box("Plant pot",Vector3(9,0.38,2),Vector3(0.65,0.7,0.65),Color(0.45,0.19,0.12))

func _interactable(n: String,p: Vector3,s: Vector3,c: Color,k: String):
    var body = StaticBody3D.new()
    body.name = n
    body.position = p
    body.add_to_group("interactable")
    body.set_meta("kind",k)
    add_child(body)
    var mesh = MeshInstance3D.new()
    var bm = BoxMesh.new()
    bm.size = s
    mesh.mesh = bm
    mesh.material_override = _mat(c,0.35)
    body.add_child(mesh)
    var cs = CollisionShape3D.new()
    var bs = BoxShape3D.new()
    bs.size = s
    cs.shape = bs
    body.add_child(cs)
    if k == "loot":
        var light = OmniLight3D.new()
        light.light_color = c
        light.light_energy = 0.55
        light.omni_range = 1.8
        light.position.y = 0.5
        body.add_child(light)

func _collectibles():
    _interactable("Gold watch",Vector3(-8,0.95,-6.5),Vector3(0.55,0.18,0.38),Color(1,0.72,0.18),"loot")
    _interactable("Jewellery box",Vector3(-4,1.15,-2.1),Vector3(0.45,0.3,0.4),Color(0.8,0.18,0.35),"loot")
    _interactable("Rare console",Vector3(2,1.05,-2),Vector3(0.6,0.3,0.35),Color(0.22,0.75,0.95),"loot")
    _interactable("Gemstone",Vector3(9,1.8,-8),Vector3(0.28,0.35,0.28),Color(0.25,0.95,0.78),"loot")
    _interactable("Cash envelope",Vector3(2,0.75,3.1),Vector3(0.4,0.08,0.28),Color(0.25,0.85,0.35),"loot")
    var stains = [Vector3(-8,0.05,-1.5),Vector3(-4,0.05,0.5),Vector3(0,0.05,4.8),Vector3(5,0.05,4.5),Vector3(8,0.05,0.5),Vector3(-8,0.05,7),Vector3(4,0.05,-6)]
    for i in range(stains.size()):
        _interactable("Dust stain %d" % (i+1),stains[i],Vector3(0.8,0.06,0.55),Color(0.16,0.12,0.09),"dirt")

func _camera():
    var camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.position = Vector3(0,10,11)
    camera.rotation_degrees = Vector3(-42,0,0)
    camera.fov = 55
    camera.set_script(load("res://scripts/follow_camera.gd"))
    add_child(camera)
    camera.make_current()

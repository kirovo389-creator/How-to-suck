extends CharacterBody3D
@export var move_speed := 4.2
var mobile_direction := Vector2.ZERO
var anim_time := 0.0
var legs: Array[MeshInstance3D] = []

func _ready():
    _make_character()
    var col = CollisionShape3D.new()
    var shape = CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.65
    col.shape = shape
    col.position.y = 0.82
    add_child(col)

func set_mobile_direction(v: Vector2):
    mobile_direction = v

func _physics_process(delta):
    var keyboard = Vector2(Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left"),Input.get_action_strength("ui_down")-Input.get_action_strength("ui_up"))
    var d = keyboard if keyboard.length() > 0.1 else mobile_direction
    d = d.limit_length(1)
    velocity = Vector3(d.x*move_speed,0,d.y*move_speed)
    move_and_slide()
    if d.length() > 0.05:
        rotation.y = lerp_angle(rotation.y,atan2(d.x,d.y),delta*10)
    anim_time += delta*(8 if d.length()>0.05 else 2)
    for i in range(legs.size()):
        legs[i].rotation.x = sin(anim_time+i*PI)*(0.45 if d.length()>0.05 else 0.03)

func _mat(c: Color) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.78
    return m

func _box(pos: Vector3,size: Vector3,c: Color) -> MeshInstance3D:
    var n = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.position = pos
    n.material_override = _mat(c)
    add_child(n)
    return n

func _sphere(pos: Vector3,scale_v: Vector3,c: Color):
    var n = MeshInstance3D.new()
    var mesh = SphereMesh.new()
    mesh.radius = 0.5
    n.mesh = mesh
    n.position = pos
    n.scale = scale_v
    n.material_override = _mat(c)
    add_child(n)

func _make_character():
    var uniform = Color(0.07,0.27,0.34)
    var dark = Color(0.035,0.045,0.06)
    _box(Vector3(0,1.03,0),Vector3(0.58,0.7,0.34),uniform)
    _sphere(Vector3(0,1.57,0),Vector3(0.23,0.25,0.23),Color(0.72,0.48,0.32))
    _sphere(Vector3(0,1.73,-0.015),Vector3(0.235,0.13,0.235),Color(0.09,0.055,0.035))
    _box(Vector3(0,1.22,-0.01),Vector3(0.64,0.12,0.37),dark)
    for x in [-0.17,0.17]:
        var leg = _box(Vector3(x,0.42,0),Vector3(0.19,0.55,0.22),dark)
        legs.append(leg)
        _box(Vector3(x,0.13,-0.055),Vector3(0.23,0.14,0.36),Color(0.04,0.04,0.05))
    _box(Vector3(0.39,0.88,0),Vector3(0.15,0.48,0.16),uniform).rotation.z = -0.25
    _box(Vector3(0.48,0.38,-0.16),Vector3(0.055,0.75,0.055),Color(0.47,0.35,0.2))
    _box(Vector3(0.48,0.06,-0.16),Vector3(0.3,0.09,0.25),Color(0.25,0.62,0.76))

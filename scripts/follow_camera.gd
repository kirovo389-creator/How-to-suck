extends Camera3D
@export var follow_speed := 5.5
var target: Node3D
func _ready():
    target = get_tree().current_scene.get_node_or_null("Player")
func _process(delta):
    if not is_instance_valid(target):
        return
    var desired = target.global_position + Vector3(0,10,11)
    global_position = global_position.lerp(desired,clampf(delta*follow_speed,0,1))
    look_at(target.global_position+Vector3(0,0.5,0),Vector3.UP)

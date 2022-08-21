extends  Spatial

onready var ocean  = get_node("/root/Ocean/Water")

const gravity: float = 9.8

export var enabled = true

var depth_submerged = 1.0
var disp_amount = 2

var water_drag = 1.5
var water_angular_drag = 1.2

func get_position():
	return get_global_transform().origin

func _physics_process(_delta):
	if not enabled:
		return
		
	var world_coord_offset = get_position() - get_parent().translation
	
	# Gravity
	get_parent().add_force(Vector3.DOWN * 9.8 / 4, world_coord_offset)
	
	var wave = ocean.get_wave(get_position().x, get_position().z)
	var wave_height = wave.y / 2.0
	var height = get_position().y
	
	if height < wave_height:
		var buoyancy = clamp((wave_height - height) / depth_submerged, 0, 1) * disp_amount
		get_parent().add_force(Vector3(0, 9.8 * buoyancy / 4, 0), world_coord_offset)
		get_parent().add_central_force(buoyancy * -get_parent().linear_velocity * water_drag)
		get_parent().add_torque(buoyancy * -get_parent().angular_velocity * water_angular_drag)
	if $Marker: $Marker.translation.y = wave_height

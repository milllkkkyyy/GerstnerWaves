extends Spatial

const pi = 3.14159265359;

var wave_a_dir = Vector2(-1.0, 5.0)
var wave_a_prop = Vector2(0.4, 10.0)

var wave_b_dir = Vector2(-4.0, -2.0)
var wave_b_prop = Vector2(0.2, 70.0)

var wave_c_dir = Vector2(-1.0, 0.0)
var wave_c_prop = Vector2(0.1, 50.0)

var wave_d_dir = Vector2(5.0, -1.0)
var wave_d_prop = Vector2(0.2, 100.0)

var wave_e_dir = Vector2(1.0, 1.0)
var wave_e_prop = Vector2(0.1, 20.0)

var time = 0

func _process(delta):
	time += delta;
	self.mesh.material.set_shader_param("time", time);
	
func _gerstnerWave(wave_dir: Vector2, wave_prop: Vector2, pos: Vector2, delta):
	var steepness = wave_prop.x
	var wavelength = wave_prop.y
	
	var k = 2.0 * pi / wavelength
	var c = sqrt(9.8 / k)
	var d = wave_dir.normalized()
	var f = k * (d.dot(pos) - c * delta)
	var a = steepness / k
	
	return Vector3(
		d.x * a * cos(f),
		a * sin(f),
		d.y * a * cos(f)
	)
	
func _get_wave(x, z):
	var p = Vector3(x, 0, z)
	p += _gerstnerWave(wave_a_dir, wave_a_prop, Vector2(x, z), time)
	p += _gerstnerWave(wave_b_dir, wave_b_prop, Vector2(x, z), time)
	p += _gerstnerWave(wave_c_dir, wave_c_prop, Vector2(x, z), time)
	p += _gerstnerWave(wave_d_dir, wave_d_prop, Vector2(x, z), time)
	p += _gerstnerWave(wave_e_dir, wave_e_prop, Vector2(x, z), time)
	return p
	
func get_wave(x, z):
	var v0 = _get_wave(x, z)
	var offset = Vector2(x - v0.x, z - v0.z)
	var v1 = _get_wave(x+offset.x/4.0, z+offset.y/4.0)
	return v1
	

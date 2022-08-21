shader_type spatial;
render_mode blend_mix, specular_phong;

uniform float speed: hint_range(-1, 1) = 0.0;

const float PI = 3.14159265359;

uniform float time;
uniform vec4 wave_a = vec4(1,0,0.1,30);
uniform vec4 wave_b = vec4(0,1,0.2,20);
uniform vec4 wave_c = vec4(1,1,0.1,10);
uniform vec4 wave_d = vec4(0,1,0.2,30);
uniform vec4 wave_e = vec4(1,0,0.1,10);


uniform float foam_level = 0.4;
uniform sampler2D noise;

uniform vec4 peak_color : hint_color;
uniform vec4 water_color : hint_color;
uniform vec4 deep_water_color : hint_color;

//depth-fade var
uniform float beer_law_factor = 2.0;
uniform float _distance = 0.0;

//foam var
uniform vec4 edge_color: hint_color;
uniform float edge_scale = 0.25;
uniform float near = 0.1;
uniform float far = 100f;

vec3 GerstnerWave(vec4 wave, vec3 pos, inout vec3 tangent, inout vec3 binormal, float delta)
{
	float steepness = wave.z;
	float wavelength = wave.w;
	
	float k = 2.0 * PI / wavelength;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(wave.xy);
	float f = k * (dot(d, pos.xz) - c * delta);
	float a = steepness / k;
	
	tangent += vec3(
		-d.x * d.x * (steepness * sin(f)),
		d.x * (steepness * cos(f)),
		-d.x * d.y * (steepness * sin(f))
		);
	binormal += vec3(
		-d.x * d.y * (steepness * sin(f)),
		d.y * (steepness * cos(f)),
		-d.y * d.y * (steepness * sin(f))
		);
	return vec3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a * cos(f))
	);
}

void vertex() {
	
	vec3 gridpoint = VERTEX.xyz;
	vec3 tangent = vec3(1, 0, 0);
	vec3 binormal = vec3(0, 0, 1);
	vec3 p = gridpoint;
	
	p += GerstnerWave(wave_a, gridpoint, tangent, binormal, time);
	p += GerstnerWave(wave_b, gridpoint, tangent, binormal, time);
	p += GerstnerWave(wave_c, gridpoint, tangent, binormal, time);
	p += GerstnerWave(wave_d, gridpoint, tangent, binormal, time);
	p += GerstnerWave(wave_e, gridpoint, tangent, binormal, time);
	vec3 normal = normalize(cross(binormal, tangent));
	
	VERTEX.xyz = p;
	NORMAL = normal;
	BINORMAL = binormal;
	TANGENT = tangent;
}

float rim(float depth) {
	depth = 2f * depth - 1f;
	return near * far / (far + depth * (near - far));
}

float calc_depth_fade(float depth, mat4 projection_matrix, 
						float beer_factor, vec3 vertex) {
	
	float scene_depth = depth;

	scene_depth = scene_depth * 2.0 - 1.0;
	scene_depth = projection_matrix[3][2] / (scene_depth + projection_matrix[2][2]);
	scene_depth = scene_depth + vertex.z; // z is negative
	
	// application of beers law
	scene_depth = exp(-scene_depth * beer_factor);
	
	float depth_fade = clamp(1.0 - scene_depth, 0.0, 1.0);
	
	return depth_fade;
}


void fragment() {
	//foam levels
	float z_depth = rim(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = rim(FRAGCOORD.z);
	float diff = z_depth - z_pos;
	
	// depth-fade
	float z_depth_fade = calc_depth_fade(texture(DEPTH_TEXTURE, SCREEN_UV).x, PROJECTION_MATRIX, beer_law_factor, VERTEX);
	vec4 gradientcolor = mix(water_color, deep_water_color, z_depth_fade);
	
	// wave peaks
	vec4 local_space = inverse(WORLD_MATRIX) * CAMERA_MATRIX * vec4(VERTEX, 1.0);
	vec4 water_peak = mix(gradientcolor, peak_color, clamp(local_space.y / 20.0, 0.0, 1.0));
	
	vec4 albedo_output = mix(edge_color, water_peak, step(edge_scale, diff));
	
	float fog_factor = exp(-0.2 * z_depth_fade/20.0);
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	ALBEDO = mix(screen, albedo_output, fog_factor).xyz;
	vec2 direction = vec2(-1.0, 0.0);
	NORMALMAP = texture(noise, UV + direction * TIME * 0.05).xyz;
	NORMALMAP_DEPTH = 0.5;
	ROUGHNESS = 0.1;
}

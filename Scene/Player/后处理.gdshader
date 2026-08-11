shader_type spatial;
// 关闭光照、雾，不写入深度，关闭深度测试以确保总是画在最前面
render_mode unshaded, fog_disabled, depth_draw_never;

// 显式声明屏幕纹理（Godot 4.x 标准做法）
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
// 色散强度（偏移量），注意 0.005 在 1080p 下大约偏移 5 个像素
uniform float dispersion_strength : hint_range(0.0, 0.05) = 0.0025;

// 顶点着色器：强制覆盖整个屏幕
void vertex() {
	// VERTEX.xy 是 QuadMesh 的局部坐标（-1 到 1）
	// 在 Godot 4.3+ 反向 Z 中，近平面必须设为 1.0
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// 片段着色器：RGB 分别偏移
void fragment() {
	// 获取屏幕 UV（0-1 范围）
	vec2 uv = SCREEN_UV;
	
	// 水平色散：红色向左偏移，蓝色向右偏移
	vec2 offset_r = vec2(-dispersion_strength, 0.0);
	vec2 offset_b = vec2(dispersion_strength, 0.0);
	
	// 径向色散（从屏幕中心向外扩散）
	vec2 center_vec = uv - 0.5;
	float dist = length(center_vec);
	// 让边缘的色散更强
	vec2 offset = normalize(center_vec) * dist * dispersion_strength * 2.0;

	float r = texture(screen_texture, uv - offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv + offset).b;
	ALBEDO = vec3(r, g, b);
}
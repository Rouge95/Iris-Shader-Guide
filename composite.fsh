#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	vec4 tex = texture(colortex0, texcoord);
	vec2 uv = texcoord;

	if (uv.x < 0.5) {
		color.rgb = tex.rgb * vec3(0.8, 0.1, 0.1);
	} else {
		color.rgb = tex.rgb * vec3(0.1, 0.8, 0.1);
	}

	color.a = tex.a; // original pixel alpha
}
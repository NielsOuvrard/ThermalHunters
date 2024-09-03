shader_type canvas_item;

uniform float tolerance : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 texcolor = texture(TEXTURE, UV);
    
    float luminance = dot(texcolor.rgb, vec3(0.3, 0.59, 0.11)); // Calculate the luminance of the color
    texcolor.a = luminance; // Use the luminance as the alpha value
    
    COLOR = texcolor;
}
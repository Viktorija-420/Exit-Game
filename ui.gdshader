shader_type canvas_item;

// Grabs whatever is rendering on screen directly behind this item
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 mix_color : source_color = vec4(0.15, 0.15, 0.15, 0.35); // Dark grey tint

void fragment() {
    // Samples the screen texture with a lower level-of-detail to cause blurring
    vec4 blurred_bg = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
    // Mixes the blur with our dark grey color overlay tint
    COLOR = mix(blurred_bg, mix_color, mix_color.a);
}
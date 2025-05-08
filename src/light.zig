const rl = @import("raylib");
const std = @import("std");

pub const LightType = enum {
    Directional,
    Point,
};

pub const Light = struct {
    t: LightType,
    enabled: bool,
    position: rl.Vector3,
    target: rl.Vector3,
    color: rl.Color,
    intensity: f32,

    // shader locations
    enabledLoc: i32,
    positionLoc: i32,
    typeLoc: i32,
    targetLoc: i32,
    colorLoc: i32,
    intensityLoc: i32,

    pub fn create_light(t: LightType, pos: rl.Vector3, tar: rl.Vector3, color: rl.Color, shader: rl.Shader) Light {
        const light = Light{
            .t = t,
            .enabled = true,
            .position = pos,
            .target = tar,
            .color = color,
            .intensity = 0.0,

            // shader locations
            .enabledLoc = rl.getShaderLocation(shader, "lights[0].enabled"),
            .positionLoc = rl.getShaderLocation(shader, "lights[0].position"),
            .typeLoc = rl.getShaderLocation(shader, "lights[0].type"),
            .targetLoc = rl.getShaderLocation(shader, "lights[0].target"),
            .colorLoc = rl.getShaderLocation(shader, "lights[0].color"),
            .intensityLoc = rl.getShaderLocation(shader, "lights[0].intensity"),
        };

        update_light(shader, light);
        return light;
    }

    pub fn update_light(shader: rl.Shader, light: Light) void {
        const u = if (light.t == .Directional) 0 else 1;
        rl.setShaderValue(shader, light.enabledLoc, @intFromBool(light.enabled), rl.SHADER_UNIFORM_INT);
        rl.setShaderValue(shader, light.typeLoc, u, rl.SHADER_UNIFORM_INT);

        rl.setShaderValue(shader, light.positionLoc, light.position, rl.SHADER_UNIFORM_VEC3);
        rl.setShaderValue(shader, light.targetLoc, light.target, rl.SHADER_UNIFORM_VEC3);

        const color = rl.Vector3{
            .x = @as(f32, @floatFromInt(light.color.r)) / 255.0,
            .y = @as(f32, @floatFromInt(light.color.g)) / 255.0,
            .z = @as(f32, @floatFromInt(light.color.b)) / 255.0,
        };
        rl.setShaderValue(shader, light.colorLoc, color, rl.SHADER_UNIFORM_VEC3);
    }
};

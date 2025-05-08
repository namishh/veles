const rl = @import("raylib");
const std = @import("std");

const Player = @import("player.zig").Player;
const World = @import("world.zig").World;

pub const GameState = struct {
    player: Player,
    world: World,

    cursorEnabled: bool,
    lastEscapeState: bool,

    // lighting and shadow system
    shadowShader: rl.Shader,
    pbrShader: rl.Shader,

    pub fn init() !GameState {
        const player = try Player.init();
        const world = try World.init();

        const shadowShader = try rl.loadShader("assets/shaders/shadowmap.fs", "assets/shaders/shadowmap.fs");
        const pbrShader = try rl.loadShader("assets/shaders/pbr.fs", "assets/shaders/pbr.fs");

        return GameState{
            .cursorEnabled = false,
            .lastEscapeState = false,
            .player = player,
            .world = world,
            .shadowShader = shadowShader,
            .pbrShader = pbrShader,
        };
    }

    pub fn deinit(self: *GameState) void {
        self.player.deinit();
        rl.unloadShader(self.shadowShader);
        rl.unloadShader(self.pbrShader);
    }

    fn loadShadowMapRenderTexture(width: i32, height: i32) !rl.RenderTexture2D {
        const target = rl.RenderTexture{ .id = rl.gl.rlLoadFramebuffer(), .texture = rl.Texture{ .id = 0, .width = width, .height = height, .mipmaps = 1, .format = 0 }, .depth = rl.gl.rlLoadTextureDepth(width, height, false) };
        rl.gl.rlFramebufferAttach(target.id, target.depth.id, rl.gl.rlFramebufferAttachType.rl_attachment_depth, rl.gl.rlFramebufferAttachTextureType.rl_attachment_texture2d, 0);
        return target;
    }

    pub fn update(self: *GameState, deltaTime: f32) void {
        if (!self.cursorEnabled) {
            self.player.update(&self.world, deltaTime);
        }

        const currentEscapeState = rl.isKeyDown(.escape);
        if (currentEscapeState and !self.lastEscapeState) {
            self.cursorEnabled = !self.cursorEnabled;

            if (self.cursorEnabled) {
                rl.enableCursor();
            } else {
                rl.disableCursor();
            }
        }

        self.lastEscapeState = currentEscapeState;
    }

    pub fn draw(self: *GameState) void {
        rl.beginMode3D(self.player.camera);
        defer rl.endMode3D();

        self.world.draw();
        self.player.draw();
    }
};

const rl = @import("raylib");
const std = @import("std");

const Player = @import("player.zig").Player;
const World = @import("world.zig").World;

pub const GameState = struct {
    player: Player,
    world: World,

    cursorEnabled: bool,
    lastEscapeState: bool,

    pub fn init() !GameState {
        const player = try Player.init();
        return GameState{
            .cursorEnabled = false,
            .lastEscapeState = false,
            .player = player,
            .world = World.init(),
        };
    }

    pub fn deinit(self: *GameState) void {
        self.player.deinit();
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

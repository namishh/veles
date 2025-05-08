const rl = @import("raylib");
const std = @import("std");

const GameState = @import("game_state.zig").GameState;

pub fn main() anyerror!void {
    const screenWidth = 1600;
    const screenHeight = 900;

    rl.initWindow(screenWidth, screenHeight, "veles");
    defer rl.closeWindow();

    rl.setExitKey(.null);
    rl.disableCursor();

    var game_state = try GameState.init();
    defer game_state.deinit();

    var lastFrameTime: f64 = rl.getTime();
    var deltaTime: f32 = 0.0;

    rl.setTargetFPS(144);

    while (!rl.windowShouldClose()) {
        const currentTime = rl.getTime();
        deltaTime = @floatCast(currentTime - lastFrameTime);
        lastFrameTime = currentTime;

        if (deltaTime > 0.2) deltaTime = 0.2;

        game_state.update(deltaTime);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        {
            game_state.draw();
        }

        if (game_state.cursorEnabled) {
            rl.drawText("PAUSED - Press ESC to resume", 800 - 150, 450, 30, rl.Color.gray);
        } else {
            rl.drawText("Press ESC to pause", 1600 - 250, 900 - 30, 20, rl.Color.gray);
        }

        rl.drawFPS(10, 10);
    }
}

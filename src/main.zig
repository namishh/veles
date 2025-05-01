const rl = @import("raylib");
const std = @import("std");

pub const Player = struct {
    camera: rl.Camera3D,
    position: rl.Vector3,
    rotation: rl.Vector3,
    direction: rl.Vector3,
    speed: f32,
    sensitivity: f32,
    cameraDistance: f32,

    pub fn init() Player {
        const pos = rl.Vector3{ .x = 0.0, .y = 0.5, .z = 0.0 };
        const rot = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
        const dir = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 1.0 };
        const dist = 5.0;

        const cameraPos = rl.Vector3{
            .x = pos.x - dir.x * dist,
            .y = pos.y + 2.0,
            .z = pos.z - dir.z * dist,
        };

        const camera = rl.Camera3D{
            .position = cameraPos,
            .target = pos,
            .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
            .fovy = 45.0,
            .projection = .perspective,
        };

        return Player{
            .camera = camera,
            .position = pos,
            .rotation = rot,
            .direction = dir,
            .speed = 0.1,
            .sensitivity = 0.003,
            .cameraDistance = dist,
        };
    }

    pub fn draw(self: *Player) void {
        rl.drawSphere(self.position, 0.5, rl.Color.blue);
    }

    pub fn update(self: *Player) void {
        const mouseX = rl.getMouseDelta().x;
        const mouseY = rl.getMouseDelta().y;

        self.rotation.y -= mouseX * self.sensitivity;
        self.rotation.x -= mouseY * self.sensitivity;

        if (self.rotation.x > 0.8) self.rotation.x = 0.8;
        if (self.rotation.x < -0.8) self.rotation.x = -0.8;

        self.direction.x = @sin(self.rotation.y);
        self.direction.y = 0.0;
        self.direction.z = @cos(self.rotation.y);

        const length = @sqrt(self.direction.x * self.direction.x +
            self.direction.z * self.direction.z);
        self.direction.x /= length;
        self.direction.z /= length;

        var moveVec = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };

        if (rl.isKeyDown(.w)) {
            moveVec.x += self.direction.x;
            moveVec.z += self.direction.z;
        }
        if (rl.isKeyDown(.s)) {
            moveVec.x -= self.direction.x;
            moveVec.z -= self.direction.z;
        }

        if (rl.isKeyDown(.a)) {
            moveVec.x += @cos(self.rotation.y);
            moveVec.z -= @sin(self.rotation.y);
        }
        if (rl.isKeyDown(.d)) {
            moveVec.x -= @cos(self.rotation.y);
            moveVec.z += @sin(self.rotation.y);
        }

        const moveMagnitude = @sqrt(moveVec.x * moveVec.x + moveVec.z * moveVec.z);
        if (moveMagnitude > 0.0) {
            moveVec.x /= moveMagnitude;
            moveVec.z /= moveMagnitude;

            self.position.x += moveVec.x * self.speed;
            self.position.z += moveVec.z * self.speed;
        }

        const cameraOrbitX = @sin(self.rotation.y);
        const cameraOrbitZ = @cos(self.rotation.y);

        const heightOffset = 1.0 + @sin(self.rotation.x) * 2.0;

        self.camera.position.x = self.position.x - cameraOrbitX * self.cameraDistance;
        self.camera.position.y = self.position.y + heightOffset;
        self.camera.position.z = self.position.z - cameraOrbitZ * self.cameraDistance;

        self.camera.target = self.position;
    }
};

pub const World = struct {
    cubePosition: rl.Vector3,

    pub fn init() World {
        return World{
            .cubePosition = rl.Vector3{ .x = 3.0, .y = 1.0, .z = 3.0 },
        };
    }

    pub fn draw(self: *World) void {
        rl.drawGrid(20, 1.0);

        rl.drawCube(self.cubePosition, 2.0, 2.0, 2.0, rl.Color.red);

        rl.drawCube(rl.Vector3{ .x = -5.0, .y = 1.0, .z = -5.0 }, 1.0, 2.0, 1.0, rl.Color.purple);
        rl.drawCube(rl.Vector3{ .x = 4.0, .y = 0.5, .z = -7.0 }, 2.0, 1.0, 2.0, rl.Color.yellow);
    }
};

pub fn main() anyerror!void {
    const screenWidth = 1600;
    const screenHeight = 900;

    rl.initWindow(screenWidth, screenHeight, "veles");
    rl.setExitKey(.null);
    defer rl.closeWindow();

    rl.disableCursor();

    var player = Player.init();
    var world = World.init();
    var mouseCursorEnabled = false;
    var lastEscapeState = false;

    rl.setTargetFPS(144);

    while (!rl.windowShouldClose()) {
        const currentEscapeState = rl.isKeyDown(.escape);
        if (currentEscapeState and !lastEscapeState) {
            mouseCursorEnabled = !mouseCursorEnabled;

            if (mouseCursorEnabled) {
                rl.enableCursor();
            } else {
                rl.disableCursor();
            }
        }
        lastEscapeState = currentEscapeState;

        if (!mouseCursorEnabled) {
            player.update();
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        {
            rl.beginMode3D(player.camera);
            defer rl.endMode3D();

            world.draw();

            player.draw();
        }

        rl.drawFPS(10, 10);
    }
}

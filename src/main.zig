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

    model: rl.Model,
    animations: []rl.ModelAnimation,
    // animation names
    // [0] - death
    // [1] - gun shoot
    // [2] and [3] - hit receive
    // [4] - idle
    // [5] - idle with gun
    // [6] - idle gun point
    // [7] - idle gun shoot
    // [8] - idle neutral
    // [9] - idle melee
    // [10] - idle interact
    // [11], [12] - kick left, right
    // [13], [14] - punch left, right
    // [15] - roll
    // [16] - run back
    // [17] - run forward
    // [18] - run left
    // [19] - run right
    // [20] - run and gun
    // [21] - sword slash
    // [22] - walk

    currentAnimation: u32 = 4,
    currentFrame: f32 = 0.0,

    pub fn init() !Player {
        const pos = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
        const rot = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
        const dir = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 1.0 };
        const dist = 5.0;

        const cameraPos = rl.Vector3{
            .x = pos.x - dir.x * dist,
            .y = pos.y + 2.0,
            .z = pos.z - dir.z * dist,
        };

        const modelPath = "assets/models/main.m3d";
        const model = try rl.loadModel(modelPath);

        const animations = try rl.loadModelAnimations(modelPath);

        std.debug.print("Loaded model with {} animations\n", .{animations.len});

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
            .model = model,
            .animations = animations,
        };
    }

    pub fn draw(self: *Player) void {
        const dirX = self.camera.target.x - self.camera.position.x;
        const dirZ = self.camera.target.z - self.camera.position.z;

        const angle = std.math.atan2(dirX, dirZ);

        rl.drawModelEx(self.model, self.position, rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, angle * (180.0 / std.math.pi), // Convert radians to degrees
            rl.Vector3{ .x = 1.0, .y = 1.0, .z = 1.0 }, .white);
    }

    pub fn update(self: *Player) void {
        const anim = self.animations[self.currentAnimation];

        self.currentFrame = @mod(self.currentFrame + 0.5, @as(f32, @floatFromInt(anim.frameCount)));
        rl.updateModelAnimation(self.model, anim, @as(i32, @intFromFloat(self.currentFrame)));

        var animeName: []const u8 = "";
        if (anim.name[0] != 0) {
            var len: usize = 0;
            while (len < anim.name.len and anim.name[len] != 0) {
                len += 1;
            }
            animeName = anim.name[0..len];
        }

        rl.drawText(@ptrCast(animeName), 20, 40, 16, .blue);

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
        var isMoving = false;

        if (rl.isKeyDown(.w)) {
            self.currentAnimation = 17;
            moveVec.x += self.direction.x;
            moveVec.z += self.direction.z;
            isMoving = true;
        }
        if (rl.isKeyDown(.s)) {
            self.currentAnimation = 16;
            moveVec.x -= self.direction.x;
            moveVec.z -= self.direction.z;
            isMoving = true;
        }

        if (rl.isKeyDown(.a)) {
            self.currentAnimation = 18;
            moveVec.x += @cos(self.rotation.y);
            moveVec.z -= @sin(self.rotation.y);
            isMoving = true;
        }
        if (rl.isKeyDown(.d)) {
            self.currentAnimation = 19;
            moveVec.x -= @cos(self.rotation.y);
            moveVec.z += @sin(self.rotation.y);
            isMoving = true;
        }

        if (rl.isMouseButtonPressed(.left) and isMoving) {
            self.currentAnimation = 20;
        }

        if (rl.isMouseButtonPressed(.left) and !isMoving) {
            self.currentAnimation = 1;
        }

        if (!isMoving) {
            self.currentAnimation = 4;
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

    pub fn deinit(self: *Player) void {
        rl.unloadModel(self.model);
        for (self.animations) |anim| {
            rl.unloadModelAnimation(anim);
        }
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
    defer rl.closeWindow();

    rl.setExitKey(.null);
    rl.disableCursor();

    var player = try Player.init();
    defer player.deinit();
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

        if (mouseCursorEnabled) {
            rl.drawText("PAUSED - Press ESC to resume", screenWidth / 2 - 150, screenHeight / 2, 30, rl.Color.gray);
        } else {
            rl.drawText("Press ESC to pause", screenWidth - 250, screenHeight - 30, 20, rl.Color.gray);
        }
    }
}

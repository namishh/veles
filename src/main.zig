const rl = @import("raylib");
const std = @import("std");

const default = 17;

// Animation IDS
// 2 == Death
// 3 == Idle
// 4 == MeleeAttack1
// 5 == MeleeAttack2
// 6 == MeleeAttack3
// 7 == MeleeAttackCombo
// 8 == MeleeBack
// 9 == MeleeForward
// 10 == MeleeIdle
// 11 == MeleeLeft
// 12 == MeleeRight
// 13 == PistolLeft
// 14 == PistolRight
// 15 == PrimaryBack
// 16 == PrimaryForward
// 17 == PrimaryIdle
// 18 == SecondaryBack
// 19 == SecondaryForward
// 20 == SecondaryIdle
// 21 == SecondaryLeft
// 22 == SecondaryRight

pub const Player = struct {
    camera: rl.Camera3D,
    position: rl.Vector3,
    rotation: rl.Vector3,
    direction: rl.Vector3,
    speed: f32,
    sensitivity: f32,
    cameraDistance: f32,

    model: rl.Model,
    textture: rl.Texture,
    animations: []rl.ModelAnimation,
    currentAnimation: u32 = default,
    currentFrame: f32 = 0.0,
    animationSpeed: f32,

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

        const modelPath = "assets/models/mc.m3d";
        var model = try rl.loadModel(modelPath);

        const texturePath = "assets/textures/mc.png";
        const texture = try rl.loadTexture(texturePath);

        model.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = texture;

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
            .textture = texture,
            .position = pos,
            .rotation = rot,
            .direction = dir,
            .speed = 8.0,
            .sensitivity = 0.008,
            .cameraDistance = dist,
            .model = model,
            .animations = animations,
            .animationSpeed = 60.0,
        };
    }

    pub fn draw(self: *Player) void {
        const dirX = self.camera.target.x - self.camera.position.x;
        const dirZ = self.camera.target.z - self.camera.position.z;

        const angle = std.math.atan2(dirX, dirZ);

        rl.drawModelEx(self.model, self.position, rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, angle * (180.0 / std.math.pi), rl.Vector3{ .x = 1.0, .y = 1.0, .z = 1.0 }, .white);
    }

    pub fn update(self: *Player, world: *World, deltaTime: f32) void {
        const anim = self.animations[self.currentAnimation];

        self.currentFrame = @mod(self.currentFrame + (self.animationSpeed * deltaTime), @as(f32, @floatFromInt(anim.frameCount)));
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

        const deltaSensitivity = self.sensitivity * deltaTime * 60.0;
        self.rotation.y -= mouseX * deltaSensitivity;
        self.rotation.x -= mouseY * deltaSensitivity;

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
            self.currentAnimation = 16;
            moveVec.x += self.direction.x;
            moveVec.z += self.direction.z;
            isMoving = true;
        }
        if (rl.isKeyDown(.s)) {
            self.currentAnimation = 15;
            moveVec.x -= self.direction.x;
            moveVec.z -= self.direction.z;
            isMoving = true;
        }

        if (rl.isKeyDown(.a)) {
            self.currentAnimation = 13;
            moveVec.x += @cos(self.rotation.y);
            moveVec.z -= @sin(self.rotation.y);
            isMoving = true;
        }
        if (rl.isKeyDown(.d)) {
            self.currentAnimation = 14;
            moveVec.x -= @cos(self.rotation.y);
            moveVec.z += @sin(self.rotation.y);
            isMoving = true;
        }

        if (!isMoving) {
            self.currentAnimation = default;
        }

        const moveMagnitude = @sqrt(moveVec.x * moveVec.x + moveVec.z * moveVec.z);
        if (moveMagnitude > 0.0) {
            moveVec.x /= moveMagnitude;
            moveVec.z /= moveMagnitude;

            var newPos = self.position;
            newPos.x += moveVec.x * self.speed * deltaTime;
            newPos.z += moveVec.z * self.speed * deltaTime;

            newPos.x = std.math.clamp(newPos.x, world.roomMin.x, world.roomMax.x);
            newPos.z = std.math.clamp(newPos.z, world.roomMin.z, world.roomMax.z);

            self.position = newPos;
        }

        const cameraOrbitX = @sin(self.rotation.y);
        const cameraOrbitZ = @cos(self.rotation.y);

        const heightOffset = 1.0 + @sin(self.rotation.x) * 2.0;

        self.camera.position.x = self.position.x - cameraOrbitX * self.cameraDistance;
        self.camera.position.y = self.position.y + heightOffset;
        self.camera.position.z = self.position.z - cameraOrbitZ * self.cameraDistance;

        self.camera.position.x = std.math.clamp(self.camera.position.x, world.roomMin.x, world.roomMax.x);
        self.camera.position.y = std.math.clamp(self.camera.position.y, world.roomMin.y, world.roomMax.y);
        self.camera.position.z = std.math.clamp(self.camera.position.z, world.roomMin.z, world.roomMax.z);

        self.camera.target = self.position;
    }

    pub fn deinit(self: *Player) void {
        rl.unloadTexture(self.textture);
        rl.unloadModel(self.model);
        for (self.animations) |anim| {
            rl.unloadModelAnimation(anim);
        }
    }
};

pub const World = struct {
    cubePosition: rl.Vector3,
    roomMin: rl.Vector3,
    roomMax: rl.Vector3,

    pub fn init() World {
        const halfLength = 10.0;
        const halfWidth = 10.0;
        const height = 5.0;
        return World{
            .cubePosition = rl.Vector3{ .x = 3.0, .y = 1.0, .z = 3.0 },
            .roomMin = rl.Vector3{ .x = -halfLength, .y = 0.0, .z = -halfWidth },
            .roomMax = rl.Vector3{ .x = halfLength, .y = height, .z = halfWidth },
        };
    }

    pub fn draw(self: *World) void {
        rl.drawGrid(20, 1.0);

        rl.drawCube(self.cubePosition, 2.0, 2.0, 2.0, rl.Color.red);

        rl.drawCube(rl.Vector3{ .x = -5.0, .y = 1.0, .z = -5.0 }, 1.0, 2.0, 1.0, rl.Color.purple);
        rl.drawCube(rl.Vector3{ .x = 4.0, .y = 0.5, .z = -7.0 }, 2.0, 1.0, 2.0, rl.Color.yellow);

        const center = rl.Vector3{
            .x = (self.roomMin.x + self.roomMax.x) / 2.0,
            .y = (self.roomMin.y + self.roomMax.y) / 2.0,
            .z = (self.roomMin.z + self.roomMax.z) / 2.0,
        };
        const sizeX = self.roomMax.x - self.roomMin.x;
        const sizeY = self.roomMax.y - self.roomMin.y;
        const sizeZ = self.roomMax.z - self.roomMin.z;
        rl.drawCubeWires(center, sizeX, sizeY, sizeZ, rl.Color.gray);
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

    var lastFrameTime: f64 = rl.getTime();
    var deltaTime: f32 = 0.0;

    rl.setTargetFPS(144);

    while (!rl.windowShouldClose()) {
        const currentTime = rl.getTime();
        deltaTime = @floatCast(currentTime - lastFrameTime);
        lastFrameTime = currentTime;

        if (deltaTime > 0.2) deltaTime = 0.2;

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
            player.update(&world, deltaTime);
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

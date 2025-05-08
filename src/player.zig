const rl = @import("raylib");
const std = @import("std");

const World = @import("world.zig").World;

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

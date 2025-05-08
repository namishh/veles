const rl = @import("raylib");
const std = @import("std");

const default = 17;

pub const World = struct {
    cubePosition: rl.Vector3,
    roomMin: rl.Vector3,
    roomMax: rl.Vector3,

    pub fn init() !World {
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

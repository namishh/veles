// perlin noise implementation
const std = @import("std");

pub const Perlin = struct {
    const PERMUTATION = [256]u8{
        151, 160, 137, 91,  90,  15,  131, 13,  201, 95,  96,  53,  194, 233, 7,   225,
        140, 36,  103, 30,  69,  142, 8,   99,  37,  240, 21,  10,  23,  190, 6,   148,
        247, 120, 234, 75,  0,   26,  197, 62,  94,  252, 219, 203, 117, 35,  11,  32,
        57,  177, 33,  88,  237, 149, 56,  87,  174, 20,  125, 136, 171, 168, 68,  175,
        74,  165, 71,  134, 139, 48,  27,  166, 77,  146, 158, 231, 83,  111, 229, 122,
        60,  211, 133, 230, 220, 105, 92,  41,  55,  46,  245, 40,  244, 102, 143, 54,
        65,  25,  63,  161, 1,   216, 80,  73,  209, 76,  132, 187, 208, 89,  18,  169,
        200, 196, 135, 130, 116, 188, 159, 86,  164, 100, 109, 198, 173, 186, 3,   64,
        52,  217, 226, 250, 124, 123, 5,   202, 38,  147, 118, 126, 255, 82,  85,  212,
        207, 206, 59,  227, 47,  16,  58,  17,  182, 189, 28,  42,  223, 183, 170, 213,
        119, 248, 152, 2,   44,  154, 163, 70,  221, 153, 101, 155, 167, 43,  172, 9,
        129, 22,  39,  253, 19,  98,  108, 110, 79,  113, 224, 232, 178, 185, 112, 104,
        218, 246, 97,  228, 251, 34,  242, 193, 238, 210, 144, 12,  191, 179, 162, 241,
        81,  51,  145, 235, 249, 14,  239, 107, 49,  192, 214, 31,  181, 199, 106, 157,
        184, 84,  204, 176, 115, 121, 50,  45,  127, 4,   150, 254, 138, 236, 205, 93,
        222, 114, 67,  29,  24,  72,  243, 141, 128, 195, 78,  66,  215, 61,  156, 180,
    };

    p: [512]u8,

    pub fn init(seed: u64) Perlin {
        var pn = Perlin{ .p = undefined };
        var random = std.rand.DefaultPrng.init(seed);

        for (0..256) |i| {
            pn.p[i] = PERMUTATION[i];
            pn.p[i + 256] = pn.p[i];
        }

        for (0..255) |i| {
            const j = random.random().intRangeAtMost(u8, 0, 255 - @as(u8, @intCast(i)));
            const temp = pn.p[i];
            pn.p[i] = pn.p[j + i];
            pn.p[j + i] = temp;
            pn.p[i + 256] = pn.p[i];
        }

        return pn;
    }

    fn fade(t: f32) f32 {
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    }

    fn grad(hash: u8, x: f32, y: f32, z: f32) f32 {
        const h = hash & 15;
        const u = if (h < 8) x else y;
        const v = if (h < 4) y else (if (h == 12 or h == 14) x else z);
        return (if ((h & 1) == 0) u else -u) + (if ((h & 2) == 0) v else -v);
    }

    fn lerp(a: f32, b: f32, t: f32) f32 {
        return a + t * (b - a);
    }

    pub fn noise(self: *const Perlin, x: f32, y: f32, z: f32) f32 {
        const X = @as(u8, @intFromFloat(@floor(x))) & 255;
        const Y = @as(u8, @intFromFloat(@floor(y))) & 255;
        const Z = @as(u8, @intFromFloat(@floor(z))) & 255;

        const xf = x - @floor(x);
        const yf = y - @floor(y);
        const zf = z - @floor(z);

        const u = fade(xf);
        const v = fade(yf);
        const w = fade(zf);

        const A = self.p[X] + Y;
        const AA = self.p[A] + Z;
        const AB = self.p[A + 1] + Z;
        const B = self.p[X + 1] + Y;
        const BA = self.p[B] + Z;
        const BB = self.p[B + 1] + Z;

        const a1 = grad(self.p[AA], xf, yf, zf);
        const a2 = grad(self.p[BA], xf - 1, yf, zf);
        const a3 = grad(self.p[AB], xf, yf - 1, zf);
        const a4 = grad(self.p[BB], xf - 1, yf - 1, zf);
        const a5 = grad(self.p[AA + 1], xf, yf, zf - 1);
        const a6 = grad(self.p[BA + 1], xf - 1, yf, zf - 1);
        const a7 = grad(self.p[AB + 1], xf, yf - 1, zf - 1);
        const a8 = grad(self.p[BB + 1], xf - 1, yf - 1, zf - 1);

        const l1 = lerp(a1, a2, u);
        const l2 = lerp(a3, a4, u);
        const l3 = lerp(a5, a6, u);
        const l4 = lerp(a7, a8, u);

        const l5 = lerp(l1, l2, v);
        const l6 = lerp(l3, l4, v);

        // Return value between -1 and 1
        return lerp(l5, l6, w);
    }

    pub fn octaveNoise(self: *const Perlin, x: f32, y: f32, z: f32, octaves: u32, persistence: f32) f32 {
        var total: f32 = 0.0;
        var frequency: f32 = 1.0;
        var amplitude: f32 = 1.0;
        var max_value: f32 = 0.0;

        var i: u32 = 0;
        while (i < octaves) : (i += 1) {
            total += self.noise(x * frequency, y * frequency, z * frequency) * amplitude;
            max_value += amplitude;
            amplitude *= persistence;
            frequency *= 2.0;
        }

        return total / max_value;
    }
};

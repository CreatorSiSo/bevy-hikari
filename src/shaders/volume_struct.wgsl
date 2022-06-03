#define_import_path bevy_hikari::volume_struct

let VOXEL_RESOLUTION: u32 = 256u;
let VOXEL_LEVELS: u32 = 8u;

struct Volume {
    min: vec3<f32>;
    max: vec3<f32>;
};

struct Clusters {
    // A list of 8^3-sized blocks in the volume need updating.
    data: array<vec3<u32>>;
};

struct VoxelBuffer {
    data: array<atomic<u32>>;
};

let SAMPLE_INDICES = array<vec3<i32>, 8>(
    vec3<i32>(0, 0, 0),
    vec3<i32>(1, 0, 0),
    vec3<i32>(0, 1, 0),
    vec3<i32>(1, 1, 0),
    vec3<i32>(0, 0, 1),
    vec3<i32>(1, 0, 1),
    vec3<i32>(0, 1, 1),
    vec3<i32>(1, 1, 1),
);

struct Mipmap {
    direction: u32;
};
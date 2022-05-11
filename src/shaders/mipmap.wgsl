#import bevy_hikari::volume_struct

#ifdef VOXEL_BUFFER

[[group(0), binding(0)]]
var<storage, read_write> voxel_buffer: VoxelBuffer;
[[group(0), binding(1)]]
var texture_out: texture_storage_3d<rgba16float, write>;

fn linear_index(index: vec3<i32>) -> i32 {
    var spatial = vec3<u32>(index);
    var morton = 0u;
    for (var i = 0u; i < 8u; i = i + 1u) {
        let coord = (vec3<u32>(index) >> vec3<u32>(i)) & vec3<u32>(1u);
        let offset = 3u * i;

        morton = morton | (coord.x << offset);
        morton = morton | (coord.y << (offset + 1u));
        morton = morton | (coord.z << (offset + 2u));
    }

    return i32(morton);
}

fn unpack_color(voxel: u32) -> vec4<f32> {
    let unpacked = unpack4x8unorm(voxel);
    let multiplier = unpacked.a * 255.0;
    let alpha = min(1.0, multiplier);
    return vec4<f32>(multiplier * unpacked.rgb, alpha);
}

[[stage(compute), workgroup_size(8, 8, 8)]]
fn clear([[builtin(global_invocation_id)]] id: vec3<u32>) {
    let coords = vec3<i32>(id);
    if (all(coords < textureDimensions(texture_out))) {
        let index = linear_index(coords);
        let voxel = &voxel_buffer.data[index];
        atomicStore(voxel, 0u);
    }
}

[[stage(compute), workgroup_size(8, 8, 8)]]
fn fill([[builtin(global_invocation_id)]] id: vec3<u32>) {
    let coords = vec3<i32>(id);
    if (all(coords < textureDimensions(texture_out))) {
        let index = linear_index(coords);
        let voxel = &voxel_buffer.data[index];
        let color = unpack_color(atomicLoad(voxel));
        textureStore(texture_out, coords, color);
    }
}

#else   // VOXEL_BUFFER

#ifndef MIPMAP_ANISOTROPIC
[[group(0), binding(0)]]
var texture_out_0: texture_storage_3d<rgba16float, write>;
[[group(0), binding(1)]]
var texture_out_1: texture_storage_3d<rgba16float, write>;
[[group(0), binding(2)]]
var texture_out_2: texture_storage_3d<rgba16float, write>;
[[group(0), binding(3)]]
var texture_out_3: texture_storage_3d<rgba16float, write>;
[[group(0), binding(4)]]
var texture_out_4: texture_storage_3d<rgba16float, write>;
[[group(0), binding(5)]]
var texture_out_5: texture_storage_3d<rgba16float, write>;
[[group(0), binding(6)]]
var texture_in: texture_3d<f32>;

#else   // MIPMAP_ANISOTROPIC

[[group(0), binding(0)]]
var texture_out: texture_storage_3d<rgba16float, write>;
[[group(0), binding(1)]]
var texture_in: texture_3d<f32>;
[[group(0), binding(2)]]
var<uniform> mipmap_data: Mipmap;

#endif  // MIPMAP_ANISOTROPIC

fn sample_voxel(id: vec3<u32>, index: vec3<i32>) -> vec4<f32> {
    let location = vec3<i32>(id) * 2 + index;
    return textureLoad(texture_in, location, 0);
}

fn take_samples(id: vec3<u32>) -> array<vec4<f32>, 8> {
    var samples: array<vec4<f32>, 8>;
    samples[0] = sample_voxel(id, SAMPLE_INDICES[0]);
    samples[1] = sample_voxel(id, SAMPLE_INDICES[1]);
    samples[2] = sample_voxel(id, SAMPLE_INDICES[2]);
    samples[3] = sample_voxel(id, SAMPLE_INDICES[3]);
    samples[4] = sample_voxel(id, SAMPLE_INDICES[4]);
    samples[5] = sample_voxel(id, SAMPLE_INDICES[5]);
    samples[6] = sample_voxel(id, SAMPLE_INDICES[6]);
    samples[7] = sample_voxel(id, SAMPLE_INDICES[7]);
    return samples;
}

#ifndef MIPMAP_ANISOTROPIC

[[stage(compute), workgroup_size(8, 8, 6)]]
fn mipmap(
    [[builtin(global_invocation_id)]] global_invocation_id: vec3<u32>,
    [[builtin(local_invocation_id)]] local_invocation_id: vec3<u32>,
) {
    let id = vec3<u32>(global_invocation_id.xy, global_invocation_id.z / 6u);
    let direction = local_invocation_id.z;
    let samples = take_samples(id);

    var color = vec4<f32>(0.);
    if (direction == 0u) {
        // +X
        color = color + samples[0] + (1. - samples[0].a) * samples[1];
        color = color + samples[2] + (1. - samples[2].a) * samples[3];
        color = color + samples[4] + (1. - samples[4].a) * samples[5];
        color = color + samples[6] + (1. - samples[6].a) * samples[7];
        color = color * 0.25;
        textureStore(texture_out_0, vec3<i32>(id), color);
    } else if (direction == 1u) {
        // -X
        color = color + samples[1] + (1. - samples[1].a) * samples[0];
        color = color + samples[3] + (1. - samples[3].a) * samples[2];
        color = color + samples[5] + (1. - samples[5].a) * samples[4];
        color = color + samples[7] + (1. - samples[7].a) * samples[6];
        color = color * 0.25;
        textureStore(texture_out_1, vec3<i32>(id), color);
    } else if (direction == 2u) {
        // +Y
        color = color + samples[0] + (1. - samples[0].a) * samples[2];
        color = color + samples[1] + (1. - samples[1].a) * samples[3];
        color = color + samples[4] + (1. - samples[4].a) * samples[6];
        color = color + samples[5] + (1. - samples[5].a) * samples[7];
        color = color * 0.25;
        textureStore(texture_out_2, vec3<i32>(id), color);
    } else if (direction == 3u) {
        // -Y
        color = color + samples[2] + (1. - samples[2].a) * samples[0];
        color = color + samples[3] + (1. - samples[3].a) * samples[1];
        color = color + samples[6] + (1. - samples[6].a) * samples[4];
        color = color + samples[7] + (1. - samples[7].a) * samples[5];
        color = color * 0.25;
        textureStore(texture_out_3, vec3<i32>(id), color);
    } else if (direction == 4u) {
        // +Z
        color = color + samples[0] + (1. - samples[0].a) * samples[4];
        color = color + samples[1] + (1. - samples[1].a) * samples[5];
        color = color + samples[2] + (1. - samples[2].a) * samples[6];
        color = color + samples[3] + (1. - samples[3].a) * samples[7];
        color = color * 0.25;
        textureStore(texture_out_4, vec3<i32>(id), color);
    } else if (direction == 5u) {
        // -Z
        color = color + samples[4] + (1. - samples[4].a) * samples[0];
        color = color + samples[5] + (1. - samples[5].a) * samples[1];
        color = color + samples[6] + (1. - samples[6].a) * samples[2];
        color = color + samples[7] + (1. - samples[7].a) * samples[3];
        color = color * 0.25;
        textureStore(texture_out_5, vec3<i32>(id), color);
    }
}

#else   // MIPMAP_ANISOTROPIC

[[stage(compute), workgroup_size(8, 8, 8)]]
fn mipmap([[builtin(global_invocation_id)]] id: vec3<u32>) {
    if (any(vec3<i32>(id) > textureDimensions(texture_out))) {
        return;
    }

    let direction = mipmap_data.direction;
    let samples = take_samples(id);

    var color = vec4<f32>(0.0);
    if (direction == 0u) {
        // +X
        color = color + samples[0] + (1. - samples[0].a) * samples[1];
        color = color + samples[2] + (1. - samples[2].a) * samples[3];
        color = color + samples[4] + (1. - samples[4].a) * samples[5];
        color = color + samples[6] + (1. - samples[6].a) * samples[7];
    } else if (direction == 1u) {
        // -X
        color = color + samples[1] + (1. - samples[1].a) * samples[0];
        color = color + samples[3] + (1. - samples[3].a) * samples[2];
        color = color + samples[5] + (1. - samples[5].a) * samples[4];
        color = color + samples[7] + (1. - samples[7].a) * samples[6];
    } else if (direction == 2u) {
        // +Y
        color = color + samples[0] + (1. - samples[0].a) * samples[2];
        color = color + samples[1] + (1. - samples[1].a) * samples[3];
        color = color + samples[4] + (1. - samples[4].a) * samples[6];
        color = color + samples[5] + (1. - samples[5].a) * samples[7];
    } else if (direction == 3u) {
        // -Y
        color = color + samples[2] + (1. - samples[2].a) * samples[0];
        color = color + samples[3] + (1. - samples[3].a) * samples[1];
        color = color + samples[6] + (1. - samples[6].a) * samples[4];
        color = color + samples[7] + (1. - samples[7].a) * samples[5];
    } else if (direction == 4u) {
        // +Z
        color = color + samples[0] + (1. - samples[0].a) * samples[4];
        color = color + samples[1] + (1. - samples[1].a) * samples[5];
        color = color + samples[2] + (1. - samples[2].a) * samples[6];
        color = color + samples[3] + (1. - samples[3].a) * samples[7];
    } else if (direction == 5u) {
        // -Z
        color = color + samples[4] + (1. - samples[4].a) * samples[0];
        color = color + samples[5] + (1. - samples[5].a) * samples[1];
        color = color + samples[6] + (1. - samples[6].a) * samples[2];
        color = color + samples[7] + (1. - samples[7].a) * samples[3];
    }

    color = color * 0.25;
    textureStore(texture_out, vec3<i32>(id), color);
}

#endif  // MIPMAP_ANISOTROPIC

#endif  // VOXEL_BUFFER
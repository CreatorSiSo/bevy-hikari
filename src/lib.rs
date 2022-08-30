use bevy::{
    asset::load_internal_asset,
    core_pipeline::core_3d::MainPass3dNode,
    prelude::*,
    reflect::TypeUuid,
    render::{
        render_graph::{RenderGraph, SlotInfo, SlotType},
        RenderApp,
    },
};
use mesh::BindlessMeshPlugin;
use prepass::PrepassPlugin;

use crate::prepass::PrepassNode;

pub mod mesh;
pub mod prelude;
pub mod prepass;

pub mod graph {
    pub const NAME: &str = "hikari";
    pub mod input {
        pub const VIEW_ENTITY: &str = "view_entity";
    }
    pub mod node {
        pub const PREPASS: &str = "prepass";
    }
}

pub const PREPASS_SHADER_HANDLE: HandleUntyped =
    HandleUntyped::weak_from_u64(Shader::TYPE_UUID, 4693612430004931427);

pub struct HikariPlugin;
impl Plugin for HikariPlugin {
    fn build(&self, app: &mut App) {
        load_internal_asset!(
            app,
            PREPASS_SHADER_HANDLE,
            "shaders/prepass.wgsl",
            Shader::from_wgsl
        );

        app.add_plugin(BindlessMeshPlugin).add_plugin(PrepassPlugin);

        if let Ok(render_app) = app.get_sub_app_mut(RenderApp) {
            let prepass_node = PrepassNode::new(&mut render_app.world);
            let pass_node_3d = MainPass3dNode::new(&mut render_app.world);
            let mut graph = render_app.world.resource_mut::<RenderGraph>();

            let mut hikari_graph = RenderGraph::default();
            hikari_graph.add_node(graph::node::PREPASS, prepass_node);
            hikari_graph.add_node(
                bevy::core_pipeline::core_3d::graph::node::MAIN_PASS,
                pass_node_3d,
            );
            let input_node_id = hikari_graph.set_input(vec![SlotInfo::new(
                graph::input::VIEW_ENTITY,
                SlotType::Entity,
            )]);
            hikari_graph
                .add_slot_edge(
                    input_node_id,
                    graph::input::VIEW_ENTITY,
                    graph::node::PREPASS,
                    PrepassNode::IN_VIEW,
                )
                .unwrap();
            hikari_graph
                .add_slot_edge(
                    input_node_id,
                    graph::input::VIEW_ENTITY,
                    bevy::core_pipeline::core_3d::graph::node::MAIN_PASS,
                    MainPass3dNode::IN_VIEW,
                )
                .unwrap();
            graph.add_sub_graph(graph::NAME, hikari_graph);
        }
    }
}

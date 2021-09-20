





function draw!(scene::Scene, h::OpticSim.ParaxialAnalysis.HeadEye.Head; draw_head=true, kwargs...) where {T<:Real}

    # axes_mat = OpticSimVis.Material(color=RGBA(0.7, 0.2, 0.1, 1.0))
    # axes = OpticSimVis.Axes(tr=Transform(Vec3(3.0, 3.0, 3.0)), material=axes_mat, name="My Axes")
    # OpticSimVis.parent!(axes , OpticSimVis.root(scene))

    name = "HeadEye" #-$(UUIDs.uuid1())"
    mat = Material(;kwargs...)
    # head_root = EmptySceneObject(material=mat, name=name)
    head_root = Axes(
        tr=transform(OpticSim.ParaxialAnalysis.HeadEye.tr(h)), 
        material=mat, 
        shaft_scale=0.4,
        axes_scale=10.0,
        name=name)
    OpticSimVis.parent!(head_root , OpticSimVis.root(scene))

    if (draw_head)
        scale_factor = 60.0;
        # face = ParaxialAnalysis.HeadEye.transform_mesh(ParaxialAnalysis.HeadEye.get_face_model(), ParaxialAnalysis.HeadEye.tr(h)*Geometry.scale(scale_factor, scale_factor, scale_factor))
        face_mat = Material(color=RGBA(1.0,0.2,0.2, 0.3))
        face = ParaxialAnalysis.HeadEye.transform_mesh(ParaxialAnalysis.HeadEye.get_face_model(), Geometry.scale(scale_factor, scale_factor, scale_factor))
        face_mesh = Mesh(mesh=face, material=face_mat, name="Face")
        OpticSimVis.parent!(face_mesh , head_root)
    end

    # ParaxialAnalysis.HeadEye.draw_local_frame(scene, ParaxialAnalysis.HeadEye.tr(h), "Head Transform")

    # eyes
    for eye in ParaxialAnalysis.HeadEye.eyes(h)
        # Vis.draw!(scene, e, parent_transform = ParaxialAnalysis.HeadEye.tr(h))
        local name = ParaxialAnalysis.HeadEye.text(eye)
        eye_so = Axes(
            tr=transform(OpticSim.ParaxialAnalysis.HeadEye.tr(eye)), 
            material=mat, 
            shaft_scale=0.2,
            axes_scale=5.0,
            name=name)
        OpticSimVis.parent!(eye_so , head_root)

        pupil = ParaxialAnalysis.HeadEye.pupil(eye)
        name = "Pupil"
        pupil_so = Axes(
            tr=transform(OpticSim.ParaxialAnalysis.HeadEye.tr(pupil)), 
            material=mat, 
            shaft_scale=0.1,
            axes_scale=2.0,
            name=name)
        OpticSimVis.parent!(pupil_so , eye_so)


    end

    return Dict{Symbol, Any}(
        :scene => scene,
        :scene_object => head_root,
    )

end

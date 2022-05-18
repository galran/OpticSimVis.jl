

module EmittersConsts
    ARRROW_LENGTH = 0.3
    ARRROW_SIZE = 0.01
    MARKER_SIZE = 1
end


#-------------------------------------
# draw debug information - local axes and positions
#-------------------------------------
function maybe_draw_debug_info(scene::Scene, so::AbstractSceneObject, o::Origins.AbstractOriginDistribution; transform::Geometry.Transform = Transform(), debug::Bool=false, kwargs...) where {T<:Real}

    dir = forward(transform)
    uv = SVector{3}(right(transform))
    vv = SVector{3}(up(transform))
    pos = origin(transform)

    if (debug)

        debug_so = EmptySceneObject(name="Debug Info")
        OpticSimVis.parent!(debug_so , so)

        # # this is a stupid hack to force makie to render in 3d - for some scenes, makie decide with no apperent reason to show in 2d instead of 3d
        # Makie.scatter!(scene, [pos[1], pos[1]+0.1], [pos[2], pos[2]+0.1], [pos[3], pos[3]+0.1], color=:red, markersize=0)

        # draw the origin and normal of the surface
        # Makie.scatter!(scene, pos, color=:blue, markersize = MARKER_SIZE * visual_size(o))
        # draw!(scene, [pos], size=0.02, color=:blue)

        # draw a point in the origin as a point cloud
        pc_mat = OpticSimVis.Material(color=RGBA(0.1, 0.1, 9.1, 1.0), size=0.05)
        pc = OpticSimVis.PointCloud(points=[pos], material=pc_mat, name="Origin Point")
        OpticSimVis.parent!(pc , debug_so)

        x_axis = uv * 0.5 * EmittersConsts.ARRROW_LENGTH * visual_size(o)
        y_axis = vv * 0.5 * EmittersConsts.ARRROW_LENGTH * visual_size(o)
        z_axis = dir * EmittersConsts.ARRROW_LENGTH * visual_size(o)
        axes = OpticSimVis.Axes(
            tr=Glimmer.transform(Transform(pos)), 
            x_axis=x_axis,
            y_axis=y_axis,
            z_axis=z_axis,
            # material=axes_mat, 
            name="Local Axes")
        OpticSimVis.parent!(axes , debug_so)

    end

end


#-------------------------------------
# draw point origin
#-------------------------------------
function draw!(scene::Scene, o::Origins.Point; parent_so::AbstractSceneObject = root(scene), kwargs...) where {T<:Real}
    transform = local_tr(parent_so)

    pos = origin(transform)
    obj = draw!(scene, [pos]; size=0.01, kwargs...)

    maybe_draw_debug_info(scene, obj[:scene_object], o; transform=transform, kwargs...)
    return obj
end

#-------------------------------------
# draw RectGrid and RectUniform origins
#-------------------------------------
function draw!(scene::Scene, o::Union{Origins.RectGrid, Origins.RectUniform, Origins.RectJitterGrid}; parent_so::AbstractSceneObject = root(scene), kwargs...) where {T<:Real}
    transform = Transform() # toTransform(local_tr(parent_so))
    dir = forward(transform)
    uv = SVector{3}(right(transform))
    vv = SVector{3}(up(transform))
    pos = origin(transform)

    plane = OpticSim.Plane(dir, pos)
    rect = OpticSim.Rectangle(plane, o.width / 2, o.height / 2, uv, vv)
    
    obj = draw!(scene, rect;  parent_so=parent_so, kwargs...)

    maybe_draw_debug_info(scene, obj[:scene_object], o; transform=transform, kwargs...)
    return obj
end


#-------------------------------------
# draw hexapolar origin
#-------------------------------------
function draw!(scene::Scene, o::Origins.Hexapolar{T}; parent_so::AbstractSceneObject = root(scene), kwargs...) where {T<:Real}
    transform = Transform() # local_tr(parent_so)
    dir = forward(transform)
    uv = SVector{3}(right(transform))
    vv = SVector{3}(up(transform))
    pos = origin(transform)

    plane = OpticSim.Plane(dir, pos)
    ellipse = OpticSim.Ellipse(plane, o.halfsizeu, o.halfsizev, uv, vv)
    obj = draw!(scene, ellipse;  kwargs...)

    maybe_draw_debug_info(scene, obj[:scene_object], o; transform=transform, kwargs...)
    return obj
end



#-------------------------------------
# draw source
#-------------------------------------
function draw!(scene::Scene, s::Sources.Source{T}; parent_so::AbstractSceneObject = root(scene), debug::Bool=false, kwargs...) where {T<:Real}

    name = "Source-$(UUIDs.uuid1())"
    t = s.transform;        
    root_so = EmptySceneObject(tr=transform(t), name=name)
    OpticSimVis.parent!(root_so , parent_so)
    
    obj = draw!(scene, s.origins;  color=RGBA(1.0, 1.0, 0.0, 0.5), parent_so=root_so, debug=debug, kwargs...)

    if (debug)
        parent_transform = toTransform(local_tr(parent_so))

        m = zeros(T, length(s), 7)
        for (index, optical_ray) in enumerate(s)
            ray = OpticSim.ray(optical_ray)
            ray = parent_transform * ray
            # @info ray.origin, ray.direction
            m[index, 1:7] = [ray.origin... ray.direction... OpticSim.power(optical_ray)]
        end
        
        m[:, 4:6] .*= m[:, 7] * EmittersConsts.ARRROW_LENGTH * visual_size(s.origins)  

        base_so = obj[:scene_object]

        points = Vector{SVector{3, Float64}}(undef, size(m)[1] * 2)
        for i in 1:size(m)[1]
            point = SVector(m[i,1], m[i, 2], m[i, 3])
            dir = SVector(m[i,4], m[i, 5], m[i, 6])
            point2 = point + dir
            index = (i-1) * 2 + 1
            points[index] = point
            points[index+1] = point2
        end

        # @info typeof(points)
        segments_mat = OpticSimVis.Material(color=RGBA(0.9, 0.9, 0.1, 0.5))
        segments = OpticSimVis.LineSegments(
            points=points, 
            tr=transform(inv(parent_transform * t)), #transform(Transform(Vec3(0.0, 0.0, 0.0))), 
            material=segments_mat, 
            name="Debug Rays")
        OpticSimVis.parent!(segments, base_so)
    

        # debug_so = EmptySceneObject(name="Debug")
        # OpticSimVis.set_parent!(debug_so , base_so)

        # arrow_mat = OpticSimVis.Material(color=RGBA(0.7, 0.7, 0.1, 0.5))
        # for i in 1:size(m)[1]
        #     point = SVector(m[i,1], m[i, 2], m[i, 3])
        #     dir = SVector(m[i,4], m[i, 5], m[i, 6])
        #     point2 = point + dir
        #     arrow = OpticSimVis.Arrow(point, point2; material=arrow_mat, name="Arrow_$i")
        #     OpticSimVis.set_parent!(arrow , debug_so)
        # end

        # Makie.arrows!(scene, [Makie.Point3f0(origin(ray))], [Makie.Point3f0(rayscale * direction(ray))]; kwargs..., arrowsize = min(0.05, rayscale * 0.05), arrowcolor = color, linecolor = color, linewidth = 2)
        # color = :yellow
        # arrow_size = ARRROW_SIZE * visual_size(s.origins)
        # Makie.arrows!(scene, m[:,1], m[:,2], m[:,3], m[:,4], m[:,5], m[:,6]; kwargs...,  arrowcolor=color, linecolor=color, arrowsize=arrow_size, linewidth=arrow_size*0.5)
    end

    return obj
end


#-------------------------------------
# draw composite source
#-------------------------------------
function draw!(scene::Scene, s::Sources.CompositeSource{T}; parent_so::AbstractSceneObject = root(scene), kwargs...) where {T<:Real}

    name = "Composite Source-$(UUIDs.uuid1())"
    t = s.transform;        
    root_so = EmptySceneObject(tr=transform(t), name=name)
    OpticSimVis.parent!(root_so , parent_so)

    # axes = OpticSimVis.Axes(
    #     # tr=Transform(pos), 
    #     axes_scale=20,
    #     shaft_scale=5,
    #     name="Debug Axes")
    # OpticSimVis.parent!(axes , root_so)

    for source in s.sources
        draw!(scene, source; parent_so=root_so, kwargs...)
    end
end

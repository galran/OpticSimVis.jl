


#############################################################################

function λtoRGB(λ::T, gamma::T = 0.8) where {T<:Real}
    wavelength = λ * 1000 # λ is in um, need in nm
    if (wavelength >= 380 && wavelength <= 440)
        attenuation = 0.3 + 0.7 * (wavelength - 380) / (440 - 380)
        R = ((-(wavelength - 440) / (440 - 380)) * attenuation)^gamma
        G = 0.0
        B = (1.0 * attenuation)^gamma
    elseif (wavelength >= 440 && wavelength <= 490)
        R = 0.0
        G = ((wavelength - 440) / (490 - 440))^gamma
        B = 1.0
    elseif (wavelength >= 490 && wavelength <= 510)
        R = 0.0
        G = 1.0
        B = (-(wavelength - 510) / (510 - 490))^gamma
    elseif (wavelength >= 510 && wavelength <= 580)
        R = ((wavelength - 510) / (580 - 510))^gamma
        G = 1.0
        B = 0.0
    elseif (wavelength >= 580 && wavelength <= 645)
        R = 1.0
        G = (-(wavelength - 645) / (645 - 580))^gamma
        B = 0.0
    elseif (wavelength >= 645 && wavelength <= 750)
        attenuation = 0.3 + 0.7 * (750 - wavelength) / (750 - 645)
        R = (1.0 * attenuation)^gamma
        G = 0.0
        B = 0.0
    else
        R = 0.0
        G = 0.0
        B = 0.0
    end
    return RGB(R, G, B)
end

indexedcolor(i::Int) = ColorSchemes.hsv[rem(i / (2.1 * π), 1.0)]
indexedcolor2(i::Int) = ColorSchemes.hsv[1.0 - rem(i / (2.1 * π), 1.0)] .* 0.5

#############################################################################



# main draw function
# function draw(obj; kwargs...)
#     scene, lscene = Vis.scene(resolution)
#     draw!(lscene, ob; kwargs...)
#     display(scene)

#     if (get_current_mode() == :pluto || get_current_mode() == :docs)
#         return scene
#     end
# end


# function draw!(ob; kwargs...)
#     if current_3d_scene === nothing
#         scene, lscene = Vis.scene()
#     else
#         scene = current_main_scene
#         lscene = current_3d_scene
#     end
#     draw!(lscene, ob; kwargs...)
#     display(scene)

#     if (get_current_mode() == :pluto || get_current_mode() == :docs)
#         return scene
#     end
# end




"""
    draw!(scene::Makie.LScene, csg::Union{CSGTree,CSGGenerator}; numdivisions::Int = 20, kwargs...)

Convert a CSG object ([`CSGTree`](@ref) or [`CSGGenerator`](@ref)) to a mesh using [`makemesh`](@ref) with resolution set by `numdivisions` and draw the resulting [`TriangleMesh`](@ref).
"""
draw!(scene::Scene, csg::CSGTree{T}; numdivisions::Int = 30, kwargs...) where {T<:Real} = draw!(scene, makemesh(csg, numdivisions); kwargs...)
draw!(scene::Scene, csg::CSGGenerator{T}; kwargs...) where {T<:Real} = draw!(scene, csg(); kwargs...)


#-----------------------------------------------------------------------------------------------
#   MESH from FILE
#-----------------------------------------------------------------------------------------------
function draw!(scene::Scene, ob::AbstractString; kwargs...)
    if any(endswith(lowercase(ob), x) for x in [".obj", "ply", ".2dm", ".off", ".stl"])
        meshdata = FileIO.load(ob)
        return draw!(scene, meshdata; kwargs...)
    else
        @error "Unsupported file type"
    end
end

#-----------------------------------------------------------------------------------------------
#   MESH
#-----------------------------------------------------------------------------------------------
function draw!(scene::Scene, mesh::GeometryBasics.AbstractMesh; parent_so::AbstractSceneObject = root(scene), kwargs...)
    name = "Mesh-$(UUIDs.uuid1())"
    mat = Material(;kwargs...)
    # @show typeof(mesh)
    # @show name
    scene_mesh = Mesh(mesh=mesh, material=mat, name=name)

    OpticSimVis.parent!(scene_mesh , parent_so)

    return Dict{Symbol, Any}(
        :scene => scene,
        :scene_object => scene_mesh,
    )
end

#-----------------------------------------------------------------------------------------------
#   Points
#-----------------------------------------------------------------------------------------------
function draw!(scene::Scene, points::Vector{SVector{3, T}}; parent_so::AbstractSceneObject = root(scene), kwargs...) where {T<:Real}

    name = "PointCloud-$(UUIDs.uuid1())"
    mat = Material(;kwargs...)
    pc = PointCloud(points=points, material=mat, name=name)

    OpticSimVis.parent!(pc , parent_so)

    return Dict{Symbol, Any}(
        :scene => scene,
        :scene_object => pc,
    )


    # if normals
    #     @warn "Normals being drawn from triangulated mesh, precision may be low"
    #     norigins = [Makie.Point3f0(centroid(t)) for t in tmesh.triangles[1:10:end]]
    #     ndirs = [Makie.Point3f0(normal(t)) for t in tmesh.triangles[1:10:end]]
    #     if length(norigins) > 0
    #         Makie.arrows!(scene, norigins, ndirs, arrowsize = 0.2, arrowcolor = normalcolor, linecolor = normalcolor, linewidth = 2)
    #     end
    # end
end



#-----------------------------------------------------------------------------------------------
#   TriangleMesh (OpticSim type)
#-----------------------------------------------------------------------------------------------
function draw!(scene::Scene, tmesh::TriangleMesh{T}; color=:orange, overrideAlpha = 1.0, kwargs...) where {T<:Real}
    if (overrideAlpha != 1.0)
        color = Glimmer.to_color(color)
        color = RGBA(color.r, color.g, color.b, color.alpha * overrideAlpha)
    end
    mesh = to_mesh(tmesh)
    return draw!(scene, mesh; color=color, kwargs...)
    # if normals
    #     @warn "Normals being drawn from triangulated mesh, precision may be low"
    #     norigins = [Makie.Point3f0(centroid(t)) for t in tmesh.triangles[1:10:end]]
    #     ndirs = [Makie.Point3f0(normal(t)) for t in tmesh.triangles[1:10:end]]
    #     if length(norigins) > 0
    #         Makie.arrows!(scene, norigins, ndirs, arrowsize = 0.2, arrowcolor = normalcolor, linecolor = normalcolor, linewidth = 2)
    #     end
    # end
end


#-----------------------------------------------------------------------------------------------
#   Surface{T}
#-----------------------------------------------------------------------------------------------
function draw!(scene::Scene, surf::Surface{T}; numdivisions::Int = 30, kwargs...) where {T<:Real}
    tmesh = makemesh(surf, numdivisions)
    if nothing === tmesh
        return
    end
    return draw!(scene, tmesh; kwargs...)
    # if normals
    #     ndirs = Makie.Point3f0.(samplesurface(surf, normal, numdivisions ÷ 10))
    #     norigins = Makie.Point3f0.(samplesurface(surf, point, numdivisions ÷ 10))
    #     Makie.arrows!(scene, norigins, ndirs, arrowsize = 0.2, arrowcolor = normalcolor, linecolor = normalcolor, linewidth = 2)
    # end
end


#-----------------------------------------------------------------------------------------------
# LensAssembly
#-----------------------------------------------------------------------------------------------
function draw!(scene::Scene, ass::LensAssembly{T}; drawStops = true, kwargs...) where {T<:Real}
    # @info "Draw LensAssembly"
    for (i, e) in enumerate(elements(ass))
        if (e isa OpticSim.StopSurface && drawStops || !(e isa OpticSim.StopSurface))
            draw!(scene, e; kwargs..., color = indexedcolor2(i))
        end
    end
end

#-----------------------------------------------------------------------------------------------
# sys::AbstractOpticalSystem  
#-----------------------------------------------------------------------------------------------

function draw!(scene::Scene, sys::CSGOpticalSystem{T}; kwargs...) where {T<:Real}
    # @info "Draw CSGOpticalSystem"
    draw!(scene, sys.assembly; kwargs...)
    draw!(scene, sys.detector; kwargs...)
end

draw!(scene::Scene, sys::AxisymmetricOpticalSystem{T}; kwargs...) where {T<:Real} = draw!(scene, sys.system; kwargs...)


#-----------------------------------------------------------------------------------------------
#   
#-----------------------------------------------------------------------------------------------
onlydetectorrays(system::Q, tracevalue::LensTrace{T,3}) where {T<:Real,Q<:AbstractOpticalSystem{T}} = onsurface(OpticSim.detector(system), point(tracevalue))

function drawtracerays!(
    scene::Scene, 
    system::Q; 
    raygenerator::S = Source(
        transform = translation(0.0,0.0,10.0), 
        origins = Origins.RectGrid(10.0,10.0,25,25),
        directions = Constant(0.0,0.0,-1.0)
    ), 
    test::Bool = false, 
    trackallrays::Bool = false, 
    colorbysourcenum::Bool = false, 
    colorbynhits::Bool = false, 
    rayfilter::Union{Nothing,Function} = onlydetectorrays, 
    verbose::Bool = false, 
    drawsys::Bool = false, 
    drawgen::Bool = false, 
    drawrays::Bool = true, 
    kwargs...
) where {T<:Real,Q<:AbstractOpticalSystem{T},S<:AbstractRayGenerator{T}}

    raylines = Vector{LensTrace{T,3}}(undef, 0)

    # @info "drawtracerays!"

    if (drawgen || drawsys || drawrays)
        trace_rays_so = EmptySceneObject(name="TraceRays-$(UUIDs.uuid1())")
        OpticSimVis.parent!(trace_rays_so , root(scene))
    end

    drawgen && draw!(scene, raygenerator, norays = true, parent_so=trace_rays_so; kwargs...)
    drawsys && draw!(scene, system, parent_so=trace_rays_so; kwargs...)

    verbose && println("Tracing...")
    for (i, r) in enumerate(raygenerator)
        if i % 1000 == 0 && verbose
            print("\r $i / $(length(raygenerator))")
        end
        allrays = Vector{LensTrace{T,3}}(undef, 0)
        if trackallrays
            res = trace(system, r, trackrays = allrays, test = test)
        else
            res = trace(system, r, test = test)
        end

        if (drawrays)
            if trackallrays && !isempty(allrays)
                if rayfilter === nothing || rayfilter(system, allrays[end])
                    # filter on the trace that is hitting the detector
                    for r in allrays
                        push!(raylines, r)
                    end
                end
            elseif res !== nothing
                if rayfilter === nothing || rayfilter(system, res)
                    push!(raylines, res)
                end
            end
        end
    end
    verbose && print("\r")
    # @info "Ray Lines", length(raylines)

    if (drawrays)
        verbose && println("Drawing Rays...")
        draw!(
            scene, 
            raylines, 
            parent_so = trace_rays_so,
            colorbysourcenum = colorbysourcenum, 
            colorbynhits = colorbynhits; 
            kwargs...
        )
    end

    return raylines
end


function draw!(
    scene::Scene, 
    traces::AbstractVector{LensTrace{T,N}}; 
    colorbysourcenum::Bool = false, 
    colorbynhits::Bool = false, 
    parent_so::AbstractSceneObject = root(scene),
    kwargs...
) where {T<:Real,N}
    # @info "Draw Vector of LensTrace"
    traces_by_colors = Dict()
    for trace in traces
        # draw!(scene, t; kwargs...)

        if colorbysourcenum
            color = indexedcolor(sourcenum(trace))
        elseif colorbynhits
            color = indexedcolor(OpticSim.nhits(trace))
        else
            color = λtoRGB(wavelength(trace))
        end

        final_color = RGBA(color.r, color.g, color.b, sqrt(power(trace)))

        if (!haskey(traces_by_colors, final_color))
            traces_by_colors[final_color] = [trace]
        else
            push!(traces_by_colors[final_color], trace)
        end
        # draw!(scene, (origin(ray(trace)), point(intersection(trace))); kwargs..., color = RGBA(color.r, color.g, color.b, sqrt(power(trace))), transparency = true)
    end
    
    # draw the lines of the rays_by_colors
    for (color, traces) in traces_by_colors
        points = Vector{SVector{3, Float64}}(undef, length(traces) * 2)
        index = 1
        for trace in traces
            p1 = origin(ray(trace))
            p2 = point(intersection(trace))
            points[index+0] = p1
            points[index+1] = p2
            index += 2
        end

        # @info typeof(points)
        segments_mat = OpticSimVis.Material(color=color)
        segments = OpticSimVis.LineSegments(
            points=points, 
            material=segments_mat, 
            name="Traced-$(UUIDs.uuid1())")
        OpticSimVis.parent!(segments, parent_so)        

    end    
end

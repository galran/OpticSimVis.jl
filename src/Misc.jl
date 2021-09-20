


#---------------------------------------------------------------
#   Transform to AffineMat that can be used in the renderer
#---------------------------------------------------------------
function Glimmer.transform(t::OpticSim.Transform{T}) where {T<:Real}
    rot = SMatrix{3, 3, T}(
        t[1, 1], t[2, 1], t[3, 1], 
        t[1, 2], t[2, 2], t[3, 2],
        t[1, 3], t[2, 3], t[3, 3])

    translation = SVector(t[1, 4], t[2, 4], t[3, 4])
    return AffineMap(rot, translation)
end

function toTransform(tr::CoordinateTransformations.AffineMap)
    return OpticSim.Transform(tr.linear, tr.translation)
end



#---------------------------------------------------------------
#   TriangleMesh to GeometryBasics.Mesh that can be rendered
#---------------------------------------------------------------
function to_mesh(tm::OpticSim.TriangleMesh{T}) where {T<:Real}
    len = length(tm.triangles)
    points = Vector{GeometryBasics.Point3{Float64}}(undef, len * 3)
    indices = Vector{GeometryBasics.TriangleFace{Int64}}(undef, len)
    @inbounds @simd for i in 0:(len - 1)
        t = tm.triangles[i + 1]
        points[i * 3 + 1] = OpticSim.vertex(t, 1)
        points[i * 3 + 2] = OpticSim.vertex(t, 2)
        points[i * 3 + 3] = OpticSim.vertex(t, 3)
        indices[i + 1] = GeometryBasics.TriangleFace{Int64}(i * 3 + 1, i * 3 + 2, i * 3 + 3)
    end

    # create the mesh
    mesh = GeometryBasics.Mesh(points, indices)
    return mesh
end


#---------------------------------------------------------------
#   Examples Utilities
#---------------------------------------------------------------
fixFolderSeperator(fn::String) = replace(fn, '\\' => '/')

"""
    rootFolder()

return the root folder for this package.
"""
function rootFolder()
    return fixFolderSeperator(abspath(joinpath(dirname(@__FILE__), "..")))
end


"""
    examplesFolder()

return the examples folder (~/examples) for this package.
"""
function examplesFolder()
    return fixFolderSeperator(abspath(joinpath(rootFolder(), "examples")))
end

"""
    examplesList()

Display a list of avalable examples.
"""
function examplesList()
    folder = examplesFolder();

    files = readdir(folder, join=false)

    all_jl_files = [fn for fn in files if splitext(basename(fn))[2] == ".jl"]

    println("-"^60)
    println("Examples List for OpticSimVis  [$(folder)]")
    println("-"^60)
    for f in all_jl_files
        len = length(f)
        if (len < 20)
            spaces = " "^(20 - len)
        else
            spaces = ""
        end
        println("    $(f)$(spaces)       to run:  julia> OpticSimVis.runExample(\"$(splitext(f)[1])\")")
    end

end

"""
    runExample(example::String)

Run the specific example. [example] is given without extension.
For example, if we have an example file named "Emitters.jl" the command to run it is:
OpticSimVis.runExample("Emitters")
"""
function runExample(example::String)
    fn = fixFolderSeperator(joinpath(examplesFolder(), "$(splitext(example)[1]).jl"))

    @show fn
    code = "include(\"$fn\")"
    @show code
    exp = Meta.parse(code)
    return eval(exp)
end
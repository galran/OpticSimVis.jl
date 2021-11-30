
using OpticSim
using OpticSimVis
using Test

@testset "general tests" begin
    t = OpticSim.identitytransform()
    tt = transform(t)
    @info typeof(tt)
end
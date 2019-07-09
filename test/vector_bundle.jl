include("utils.jl")

@testset "Tangent space" begin
    M = Sphere(2)

    types = [Vector{Float64},
             SizedVector{3, Float64},
             MVector{3, Float64},
             Vector{Float32},
             SizedVector{3, Float32},
             MVector{3, Float32},
             Vector{Double64},
             MVector{3, Double64},
             SizedVector{3, Double64}]
    for T in types
        x = convert(T, [1.0, 0.0, 0.0])
        TB = TangentBundle(M)
        MT = VectorSpaceManifold(Manifolds.TangentSpace, M, x)
        @testset "Type $T" begin
            pts_ts = [convert(T, [0.0, -1.0, -1.0]),
                      convert(T, [0.0, 1.0, 0.0]),
                      convert(T, [0.0, 0.0, 1.0])]
            pts_tb = [ProductRepr(convert(T, [1.0, 0.0, 0.0]), convert(T, [0.0, -1.0, -1.0])),
                      ProductRepr(convert(T, [0.0, 1.0, 0.0]), convert(T, [2.0, 0.0, 1.0])),
                      ProductRepr(convert(T, [1.0, 0.0, 0.0]), convert(T, [0.0, 2.0, -1.0]))]
            @inferred ProductRepr(convert(T, [1.0, 0.0, 0.0]), convert(T, [0.0, -1.0, -1.0]))
            for pt ∈ pts_tb
                @test bundle_projection(TB, pt) ≈ pt.parts[1]
            end
            test_manifold(MT,
                          pts_ts,
                          test_reverse_diff = isa(T, Vector),
                          test_project_tangent = true)
            test_manifold(TB,
                          pts_tb,
                          test_reverse_diff = isa(T, Vector),
                          test_tangent_vector_broadcasting = false)
        end
    end

end

m = [
 0  0  0  0  0
 0  1  0  0  0
 0  1  1  1  0
 0  1  1  1  0
 0  0  0  1  1
]

hg = EcologicalHypergraph(m, ["s1", "s2", "s3", "s4", "s5"])

@testset "Matrix constructor" begin

    @test length(interactions(hg)) == 10
    @test species(hg) == ["s1", "s2", "s3", "s4", "s5"]
    @test hg.roles == [:subject, :object]
    @test hg.t isa Num
    @test length(vars(hg)) == 5
end

web = UnipartiteNetwork(convert(Matrix{Bool}, m))
hg = EcologicalHypergraph(web)

@testset "EcologicalNetworks constructor" begin

    @test length(interactions(web)) == length(interactions(hg)) - 1 

    @test species(web) == species(hg)

    @test hg.roles == [:subject, :object]
    @test hg.t isa Num
    @test length(vars(hg)) == 5
end
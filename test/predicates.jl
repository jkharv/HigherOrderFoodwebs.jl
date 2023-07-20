m = [
 0  0  0  0  0
 0  1  0  0  0
 0  1  1  1  0
 0  1  1  1  0
 0  0  0  1  1
]

hg = EcologicalHypergraph(m, ["s1", "s2", "s3", "s4", "s5"])

@testset "isloop" begin

    @test isloop(interactions(hg)[1]) == true
    @test isloop(interactions(hg)[3]) == false 
end

# I'm not sure about the trophic level calculation in EcologicalNetworks, it seems to be
# wrong. It says it's supposed to be calculated with loops removed, but the values I get
# are sensitive to wheter I have loops in the argument or not
@testset "isproducer" begin

    @test_skip 1==1
end

@testset "isconsumer" begin
    
    @test_skip 1==1
end

@testset "subject_is_producer" begin

    @test_skip 1==1
end

@testset "subject_is_consumer" begin

    @test_skip 1==1
end

@testset "contains_species" begin

    @test_skip 1==1
# function contains_species(e::Edge, spp::Vector{String}, r::Vector{Symbol})
# function contains_species(e::Edge, sp::String, r::Symbol)::Bool
end
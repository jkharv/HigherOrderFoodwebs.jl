using Test
using EcologicalNetworks
using EcologicalHypergraphs
using ModelingToolkit
using Distributions

@testset verbose = true "EcologicalHypergraphs" begin 

    @testset "EcologicalHypergraph constructors" begin
        include("hypergraph_constructors.jl") 
    end

    @testset "CommunityMatrix constructors" begin
        include("communitymatrix_constuctors.jl")
    end

    @testset "Function templates" begin
        include("function_templates.jl") 
    end

    @testset "Predicates" begin
        include("predicates.jl") 
    end
end;
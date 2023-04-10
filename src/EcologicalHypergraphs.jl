module EcologicalHypergraphs

using MacroTools: prewalk, postwalk, unblock, rmlines
using EcologicalNetworks
using ModelingToolkit
using Symbolics
using LinearAlgebra

include(joinpath(".", "types", "declarations.jl"))
export EcologicalHypergraph, Node, Edge, 
       species, role, nodes, subject, 
       object, modifiers, add_modifier!

include(joinpath(".", "types", "conversions.jl"))

include(joinpath(".", "predicates.jl"))
export isloop, contains

include(joinpath(".", "functional_form.jl"))
export @functional_form

include(joinpath(".", "build_system.jl"))
export community_matrix, build_system

end
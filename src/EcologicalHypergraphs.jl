module EcologicalHypergraphs

using MacroTools: prewalk, postwalk, unblock, rmlines
using EcologicalNetworks
using ModelingToolkit
using Symbolics
using LinearAlgebra
using Distributions

include(joinpath(".", "types", "distribution_option.jl"))
include(joinpath(".", "types", "ecological_hypergraph.jl"))
export EcologicalHypergraph, Node, Edge

include(joinpath(".", "types", "conversions.jl"))

include(joinpath(".", "utilities", "predicates.jl"))
export isloop, contains, isproducer, isconsumer,
       subject_is_consumer, subject_is_producer

include(joinpath(".", "utilities", "getters_setters.jl"))
export species, role, nodes, subject, object, modifiers, add_modifier!

include(joinpath(".", "utilities", "utilities.jl"))
include(joinpath(".", "utilities", "overloads.jl"))

include(joinpath(".", "NTE_models", "optimal_foraging.jl"))
export add_optimal_foraging_modifiers!

include(joinpath(".", "functional_form.jl"))
export @functional_form

include(joinpath(".", "build_system.jl"))
export community_matrix, build_symbolic_system, build_numerical_system

end
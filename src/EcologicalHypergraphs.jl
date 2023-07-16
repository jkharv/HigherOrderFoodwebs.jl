module EcologicalHypergraphs

using MacroTools: prewalk, postwalk, unblock, rmlines
using EcologicalNetworks
using ModelingToolkit
using Symbolics
using Distributions

include(joinpath(".", "types", "distribution_option.jl"))
include(joinpath(".", "types", "ecological_hypergraph.jl"))
export EcologicalHypergraph, Node, Edge, DistributionOption

include(joinpath(".", "types", "community_matrix.jl"))
export CommunityMatrix

include(joinpath(".", "types", "conversions.jl"))

include(joinpath(".", "utilities", "predicates.jl"))
export isloop, contains_species, isproducer, isconsumer, subject_is_consumer, 
       subject_is_producer

include(joinpath(".", "utilities", "getters_setters.jl"))
export species, interactions, role, nodes, subject, object, modifiers, add_modifier!,
       forwards_function, set_forwards_function!, backwards_function, 
       set_backwards_function!, vars, set_vars!, params, set_param!, 
       set_initial_condition!

include(joinpath(".", "utilities", "utilities.jl"))
include(joinpath(".", "utilities", "overloads.jl"))

include(joinpath(".", "NTE_models", "optimal_foraging.jl"))
export optimal_foraging!

module FunctionTemplates

       using ..EcologicalHypergraphs
       using ModelingToolkit

       include(joinpath("function_templates", "FunctionTemplates.jl"))

end

include(joinpath(".", "function_templates", "FunctionTemplates.jl"))
using .FunctionTemplates
export @functional_form

include(joinpath(".", "build_system.jl"))
export community_matrix, get_var_dict, get_param_dict

end
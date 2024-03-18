module EcologicalHypergraphs

using MacroTools: prewalk, postwalk, unblock, rmlines
using EcologicalNetworks
using AnnotatedHypergraphs
using ModelingToolkit
using Symbolics
using Distributions
using LinearAlgebra
using SparseArrays

include(joinpath(".", "types", "types.jl"))
export CommunityMatrix, DynamicalHypergraphModel
export species, interactions, role, nodes, subject, object, modifiers,
       add_modifier!, forwards_function, set_forwards_function!, backwards_function, 
       set_backwards_function!, vars, set_vars!, params, set_param!, 
       set_initial_condition!, remove!

include(joinpath(".", "types", "conversions.jl"))

include(joinpath(".", "utilities", "predicates.jl"))
export isloop, contains_species, isproducer, isconsumer, subject_is_consumer, 
       subject_is_producer

include(joinpath(".", "utilities", "utilities.jl"))
include(joinpath(".", "utilities", "overloads.jl"))

include(joinpath(".", "NTE_models", "optimal_foraging.jl"))
export optimal_foraging!

# In a world where Julia'as module system was nicer, I'd have this as an actual module.
# We'll just pretend it is for now.
include(joinpath("function_templates", "FunctionTemplates.jl"))
export @functional_form

include(joinpath(".", "build_system.jl"))
export community_matrix, get_var_dict, get_param_dict

end
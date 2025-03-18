module HigherOrderFoodwebs

using MacroTools: prewalk, postwalk, @capture, unblock, rmlines, prettify
using SpeciesInteractionNetworks
using ModelingToolkit
using Symbolics
using Distributions
using LinearAlgebra
using SparseArrays
using SciMLBase
using OrdinaryDiffEq
using SymbolicIndexingInterface

include("./types/foodweb_variables.jl")
include("./types/dynamic_rule.jl")
include("./types/community_matrix.jl")
include("./types/foodweb_model.jl")
include("./types/extra_constructors.jl")
export FoodwebModel, DynamicRule
export CommunityMatrix
export FoodwebVariables, variables
export get_variable, get_symbol, get_index, get_value, set_value!
export SPECIES_VARIABLE, ENVIRONMENT_VARIABLE, TRAIT_VARIABLE, PARAMETER

include("./symbolic_utils/utils.jl")
export new_param, new_var, add_param!, add_var!

include("./core_interfaces/foodweb_interface.jl")
include("./core_interfaces/dynamic_rule.jl")
include("./core_interfaces/community_matrix.jl")
include("./core_interfaces/sciml_ext.jl")
export species, richness, interactions, role, roles, has_role
export isproducer, isconsumer, set_u0!
export ODESystem, ODEProblem

include("./solver_callbacks/extinction_sequence_callback.jl")
include("./solver_callbacks/extinction_threshold_callback.jl")
include("./solver_callbacks/richness_termination_callback.jl")
export ExtinctionSequenceCallback, ExtinctionThresholdCallback
export RichnessTerminationCallback

include("./foodweb_assembly.jl")
export assemble_foodweb

include("./utilities/trophic_ordering.jl")
export trophic_ordering

include("./structural_models/types.jl")
include("./structural_models/optimal_foraging.jl")
include("./structural_models/nichemodel.jl")
export nichemodel, optimal_foraging

include("./registered_symbolics/holling_2.jl")
include("./registered_symbolics/logistic.jl")
export holling2, logistic

include("numerical_tools/realized_network_sampling.jl")
export trophic_flux

#Reexports from SpeciesInteractionNetworks.jl
export Partiteness, Bipartite, Unipartite
export Interaction, Directed, Undirected, Hyperedge, AnnotatedHyperedge
export SpeciesInteractionNetwork

end

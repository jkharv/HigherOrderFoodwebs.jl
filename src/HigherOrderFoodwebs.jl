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
include("./types/community_matrix.jl")
include("./types/foodweb_model.jl")
include("./types/extra_constructors.jl")
include("./types/conversions.jl")
export FoodwebModel, DynamicRule
export CommunityMatrix
export FoodwebVariables, variables
export var_to_sym, sym_to_var
export SPECIES_VARIABLE, ENVIRONMENT_VARIABLE, TRAIT_VARIABLE

include("./symbolic_utils/utils.jl")
export new_param, new_var, add_param!, add_var!

include("./interfaces/foodweb_interface.jl")
export species, richness, interactions, role, roles, has_role
export isproducer, isconsumer, set_u0!

include("./interfaces/sciml_ext.jl")
export ODESystem, ODEProblem

include("./solver_callbacks/extinction_sequence_callback.jl")
include("./solver_callbacks/extinction_threshold_callback.jl")
include("./solver_callbacks/richness_termination_callback.jl")
export ExtinctionSequenceCallback, ExtinctionThresholdCallback
export RichnessTerminationCallback

include("./foodweb_assembly.jl")
export assemble_foodweb

include("./utilities/utilities.jl")
include("./utilities/overloads.jl")
include("./utilities/pretty_printing.jl")
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

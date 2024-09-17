module HigherOrderFoodwebs

__precompile__(false) 

using MacroTools: prewalk, postwalk, @capture, unblock, rmlines, prettify
using MacroTools
using SpeciesInteractionNetworks
using ModelingToolkit
using Symbolics
using Distributions
using LinearAlgebra
using SparseArrays
using CommonSolve
using DifferentialEquations

const TermValue = Union{Missing, Expr, T, W} where {T<:Real, W<:UnivariateDistribution}

include("./types/community_matrix.jl")
include("./types/foodweb_model.jl")
include("./types/extra_constructors.jl")
include("./types/conversions.jl")
export FoodwebModel, DynamicRule
export CommunityMatrix

include("./symbolic_utils/utils.jl")
export new_param, new_var, add_param!, add_var!

include("./interfaces/foodweb_interface.jl")
export species, richness, interactions, role, roles, has_role
export isproducer, isconsumer
export set_initial_condition!

include("./interfaces/common_solve.jl")

include("./solver_callbacks/extinction_sequence_callback.jl")
include("./solver_callbacks/extinction_limit_callback.jl")
export ExtinctionSequenceCallback, ExtinctionThresholdCallback

include("./build_system.jl")
export build_ode_system

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

#Reexports from SpeciesInteractionNetworks.jl
export Partiteness, Bipartite, Unipartite
export Interaction, Directed, Undirected, Hyperedge, AnnotatedHyperedge
export SpeciesInteractionNetwork

end
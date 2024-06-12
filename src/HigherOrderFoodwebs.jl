module HigherOrderFoodwebs

using MacroTools: prewalk, postwalk, @capture, unblock, rmlines, prettify
using AnnotatedHypergraphs
using ModelingToolkit
using Symbolics
using Distributions
using LinearAlgebra
using SparseArrays
using CommonSolve
using DifferentialEquations

const TermValue = Union{Missing, T, W} where {T<:Real, W<:UnivariateDistribution}

include("./types/community_matrix.jl")
include("./types/foodweb_model.jl")
include("./types/extra_constructors.jl")
include("./types/conversions.jl")
export FoodwebModel
export CommunityMatrix
export AnnotatedHypergraph

include("./interfaces/foodweb_interface.jl")
export species, richness, interactions, role, roles, has_role
export set_initial_condition!

include("./interfaces/common_solve.jl")
export solve


include("./build_system.jl")
export build_ode_system

include("./utilities/utilities.jl")
include("./utilities/overloads.jl")
include("./utilities/pretty_printing.jl")


#include(joinpath(".", "NTE_models", "optimal_foraging.jl"))
#export optimal_foraging!

# In a world where Julia's module system was nicer, I'd have this as an actual module.
# We'll just pretend it is for now.
include("./function_templates/FunctionTemplates.jl")
export @group, @set_rule


#Here for dev, remove later
include("NTE_models/nichemodel.jl")
export nichemodel
export Partiteness, Bipartite, Unipartite
export Interaction, Directed, Undirected, Hyperedge, AnnotatedHyperedge
export SpeciesInteractionNetwork

export species, richness, interactions, role, roles, has_role


end
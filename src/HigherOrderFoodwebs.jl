module HigherOrderFoodwebs

using MacroTools: prewalk, postwalk, unblock, rmlines
using AnnotatedHypergraphs
using ModelingToolkit
using Symbolics
using Distributions
using LinearAlgebra
using SparseArrays

include(joinpath(".", "types", "types.jl"))
include(joinpath(".", "types", "conversions.jl"))
export FoodwebModel
export AnnotatedHypergraph

include(joinpath(".", "types", "foodweb_interface.jl"))
export species, richness, interactions, role, roles, has_role

include(joinpath(".", "utilities", "utilities.jl"))
include(joinpath(".", "utilities", "overloads.jl"))
include(joinpath(".", "utilities", "pretty_printing.jl"))


#include(joinpath(".", "NTE_models", "optimal_foraging.jl"))
#export optimal_foraging!

# In a world where Julia's module system was nicer, I'd have this as an actual module.
# We'll just pretend it is for now.
include(joinpath("function_templates", "FunctionTemplates.jl"))

#Here for dev, remove later
include("NTE_models/nichemodel.jl")
export nichemodel
export Partiteness, Bipartite, Unipartite
export Interaction, Directed, Undirected, Hyperedge, AnnotatedHyperedge
export SpeciesInteractionNetwork

export species, richness, interactions, role, roles, has_role


end
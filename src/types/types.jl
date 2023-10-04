abstract type EcologicalHypergraph end

# The allowable types for giving values to parameters and variables.
const TermValue = Union{Missing, T, W} where {T<:Real, W<:UnivariateDistribution}

include("dynamical_hypergraph.jl")
include("statistical_hypergraph.jl")
include("community_matrix.jl")
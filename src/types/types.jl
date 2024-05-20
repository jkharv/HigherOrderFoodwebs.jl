# The allowable types for giving values to parameters and variables.
const TermValue = Union{Missing, T, W} where {T<:Real, W<:UnivariateDistribution}

include("foodweb_model.jl")
include("community_matrix.jl")
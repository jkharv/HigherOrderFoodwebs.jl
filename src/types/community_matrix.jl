mutable struct CommunityMatrix{T} <: AbstractMatrix{T}

    m::Matrix{T}
    spp::Vector{String}

    vars::Dict{Num, DistributionOption}
    params::Dict{Num, DistributionOption}

    function CommunityMatrix(m::Matrix{T}, 
                             spp::Vector{String}, 
                             vars::Dict{Num, DistributionOption},
                             params::Dict{Num, DistributionOption}) where T

        new{T}(m, spp, vars, params)
    end
end

"""
    CommunityMatrix(hg::EcologicalHypergraph)::CommunityMatrix{Num}

Creates a community matrix out of an `EcologicalHypergraph`. The elements of the matrix
are `Num` allowing symbolic manipulations of the matrix using `Symbolics.jl`.
"""
function CommunityMatrix(hg::EcologicalHypergraph)::CommunityMatrix{Num}

    s = length(species(hg))
    cm = zeros(Num, s, s)

    indices = Dict(hg.species .=> 1:s)

    # This orders the matrix in the same way as the species vec in hg
    for e ∈ interactions(hg) 

        r = indices[species(subject(e))[1]]
        c = indices[species(object(e))[1]]

        cm[r,c] = forwards_function(e)
        cm[c,r] = backwards_function(e)
    end

    return CommunityMatrix(cm, species(hg), vars(hg), params(hg))
end

function Base.size(cm::CommunityMatrix)

    return size(cm.m)
end

# Integer-based indexing
function Base.getindex(cm::CommunityMatrix, i::Int, j::Int)

    return cm.m[i,j]
end

function Base.setindex!(cm::CommunityMatrix, v, i::Int, j::Int)

    cm.m[i, j] = v
end

# String-based indexing
function Base.getindex(cm::CommunityMatrix, i::String, j::String)

    i = findfirst(x -> x == i, cm.spp)
    j = findfirst(x -> x == j, cm.spp)

    return cm.m[i,j]
end

function Base.setindex!(cm::CommunityMatrix, v, i::String, j::String)

    i = findfirst(x -> x == i, cm.spp)
    j = findfirst(x -> x == j, cm.spp)

    cm.m[i, j] = v
end
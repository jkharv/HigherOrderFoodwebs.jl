mutable struct CommunityMatrix{T} <: AbstractMatrix{T}

    m::Matrix{T}
    spp::Vector{String}

    vars::Dict{Num, TermValue}
    params::Dict{Num, TermValue}

    function CommunityMatrix(m::Matrix{T}, 
                             spp::Vector{String}, 
                             vars::Dict{Num, TermValue},
                             params::Dict{Num, TermValue}) where T

        new{T}(m, spp, vars, params)
    end
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
struct CommunityMatrix{T, U} <: AbstractMatrix{T}

    m::Matrix{T}
    spp::FoodwebVariables{U}

    function CommunityMatrix(m::Matrix{T}, spp::FoodwebVariables{U}) where {T, U}

        new{T, U}(m, spp)
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

# Species identifier-based indexing
function Base.getindex(cm::CommunityMatrix{T, U}, i::U, j::U) where {T, U}

    i = cm.spp.idxs[i]
    j = cm.spp.idxs[j]

    return cm.m[i,j]
end

function Base.setindex!(cm::CommunityMatrix{T, U}, v, i::U, j::U) where {T, U}

    i = cm.spp.idxs[i]
    j = cm.spp.idxs[j]

    cm.m[i, j] = v
end
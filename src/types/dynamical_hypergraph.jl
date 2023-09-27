mutable struct Node

    species::Vector{String}
    role::Symbol
       
    function Node(species::Vector{String}, role::Symbol)

        new(species, role)
    end
end

function Node(species::String, role::Symbol)

    Node([species], role)
end

mutable struct Edge

    nodes::Vector{Node}

    function Edge(nodes::Vector{Node})

        new(nodes)
    end
end

Base.zero(Edge) = Edge(Vector{Node}())
Base.iszero(e::Edge) = isempty(e.nodes)

mutable struct DynamicalHypergraph <: AbstractMatrix{Edge}

    m::SparseMatrixCSC{Edge}
    spp::Vector{String}

    function DynamicalHypergraph(m::SparseMatrixCSC{Edge}, 
                             spp::Vector{String})

        new(m, spp)
    end
end

function Base.size(am::DynamicalHypergraph)

    return size(am.m)
end

# Integer-based indexing
function Base.getindex(am::DynamicalHypergraph, i::Int, j::Int)

    return am.m[i,j]
end

function Base.setindex!(am::DynamicalHypergraph, v, i::Int, j::Int)

    am.m[i, j] = v
end

# String-based indexing
function Base.getindex(am::DynamicalHypergraph, i::String, j::String)

    i = findfirst(x -> x == i, am.spp)
    j = findfirst(x -> x == j, am.spp)

    return am.m[i,j]
end

function Base.setindex!(am::DynamicalHypergraph, v, i::String, j::String)

    i = findfirst(x -> x == i, am.spp)
    j = findfirst(x -> x == j, am.spp)

    am.m[i, j] = v
end

function DynamicalHypergraph(adjm::AbstractMatrix, spp::Vector{String}, addself = true)

    adjm = copy(adjm)
    s = length(spp)

    if(size(adjm)[1] != size(adjm)[2])

        throw(ArgumentError("An adjacency matrix must be square."))
    end

    if addself

        adjm[diagind(adjm)] .= true
    end
   
    am = SparseMatrixCSC(zeros(Edge, s, s))

    for I ∈ eachindex(IndexCartesian(), adjm)

        if adjm[I] 

            am[I] = Edge([Node(spp[I[1]], :subject),
                          Node(spp[I[2]], :object)])
        end
    end

    return DynamicalHypergraph(am, spp)
end

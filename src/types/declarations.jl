"""
Represents a node in the annotated hypergraph. Stores the species and the role
it plays in it's edge.
"""
mutable struct Node

    # See https://github.com/JuliaLang/julia/issues/269 Hopefully in the future 
    # circularly defined types will be possible.
    edge::Any

    species::String
    role::Symbol

    func_forwards::Num
    func_backwards::Num
    params::Vector{Num}
    var::Num
    
    function Node(edge, species::String, role::Symbol, forwards_func::Num, 
                  backwards_func::Num, params::Vector{Num})


        if edge isa WeakRef
            edge = edge.value
        end

        var_name = Symbol(species)
        var = @variables $var_name(edge.hypergraph.t)

        new(edge, species, role, forwards_func, backwards_func, params, var[1])
    end
end

function Node(edge, species::String, role::Symbol)

    Node(edge, species, role, Num(1), Num(1), Vector{Num}())
end

"""
    species(n::Node)

Returns the species represented by a node.
"""
function EcologicalNetworks.species(n::Node)
    # TODO Move out of declarations file.
    return n.species
end

"""
    role(n::Node)

Returns the role played by a node.
"""
function role(n::Node)
    # TODO Move out of declarations file.
    return n.role
end

"""
Represents a hyperedge in EcologicalHypergraph.

"""
mutable struct Edge

    hypergraph::Any
    nodes::Vector{Node}

    function Edge(hypergraph, nodes::Vector{Node})
        new(hypergraph, nodes)
    end
end

"""
    nodes(e::Edge)

Returns a `vector` of the `Node`s in an `Edge`.
"""
function nodes(e::Edge)
    # TODO Move out of declarations file.   
    return e.nodes
end

"""
   subject(e::Edge)::Node 

Returns the `Node` playing the role of `:subject` in an `Edge`
"""
function subject(e::Edge)
    # TODO Move out of declarations file.   
    return filter(x-> x.role == :subject, nodes(e))[1]
end

"""
   object(e::Edge)::Node 

Returns the `Node` playing the role of `:object` in an `Edge`
"""
function object(e::Edge)
    # TODO Move out of declarations file.
    return filter(x-> x.role == :object, nodes(e))[1]
end

"""
    modifiers(e::Edge)::Vector{Node}

Returns a vector of all the modifier nodes in an edge.
"""
function modifiers(e::Edge)
    # TODO Move out of declarations file.
    return filter(x -> x.role != :subject && x.role != :object, nodes(e))
end

"""
Type represeting an EcologicalHypergraph hypergraph.

Implements an Annotated Hypergraph as described in Chodrow and Mellow (2020)
"""
mutable struct EcologicalHypergraph

    edges::Vector{Edge}
    species::Vector{String}
    roles::Vector{Symbol}
    t::Num # Single time_var for representing t w/ ModelingToolkit.

    function EcologicalHypergraph(edges::Vector{Edge}, 
                                  species::Vector{String}, 
                                  roles::Vector{Symbol})

        roles = append!(roles, [:subject, :object]) 

        time_var = :t 
        time_var = @variables $time_var

        new(edges, species, roles, time_var[1])
    end
end

function EcologicalHypergraph(adjm::AbstractMatrix, spp::Vector{String})

    if(size(adjm[1]) != size(adjm[2]))

        throw(ArgumentError("An adjacency matrix must be square."))
    end

    non_zero_indices = findall(x -> !iszero(x), adjm)
    L = length(non_zero_indices)

    edges = Vector{Edge}(undef, L)
    H = EcologicalHypergraph(edges, spp, Vector{Symbol}())

    for l in 1:L
        
        sub, obj = Tuple(non_zero_indices[l])

        edges[l] = Edge(H, Vector{Node}(undef, 2))
        edges[l].nodes = [Node(edges[l], spp[sub], :subject), 
                          Node(edges[l], spp[obj], :object)] 
    end

    return H
end

"""
    add_modifier!(h::EcologicalHypergraph, e::Edge, n::Node)

Adds a modifier node `n` to an edge `e` in hypergraph `h`
"""
function add_modifier!(e::Edge, sp::String, role::Symbol = :modifier)
    # TODO Move out of declarations file.
    # TODO add checks to keep the state of the hg consistent.
    # All spp in hg spp set and so on.

    n = Node(WeakRef(e), sp, role)

    append!(e.nodes, [n]) 

    return e
end

"""
    EcologicalHypergraph(network::UnipartiteNetwork{Bool, String})

Constructor for `EcologicalHypergraph`
Convert a network from `EcologicalNetworks.jl` into an EcologicalHypergraph.
"""
function EcologicalHypergraph(network::UnipartiteNetwork{Bool, String}, 
    add_self = true)

    edges = Matrix(network.edges)

    if add_self

        for i in 1:length(species(network))
            
            if !edges[i, i]

                edges[i, i] = true
            end
        end
    end

    return EcologicalHypergraph(edges, species(network))
end

"""
    species(hg::EcologicalHypergraph)::Vector{String}

Returns a vector of all the species represented in an EcologicalHypergraph.
"""
function EcologicalNetworks.species(hg::EcologicalHypergraph)
    # TODO Move out of declarations file.
    return hg.species
end

"""
    interactions(hg::EcologicalHypergraph)::Vector{Edge}

Returns a vector of all the edges represented in an `EcologicalHypergraph`
"""
function EcologicalNetworks.interactions(hg::EcologicalHypergraph)
    # TODO Move out of declarations file.
    return hg.edges
end

# Pretty printing overides for EcologicalHypergraphs.jl types
function Base.show(io::IO, hg::EcologicalHypergraph)
    # TODO Move out of declarations file.   
    print(io, "EcologicalHypergraph
    • Species: $(length(species(hg))) 
    • Interactions: $(length(interactions(hg)))"
    )
end

function Base.show(io::IO, e::Edge)
    # TODO Move out of declarations file.
    sub = subject(e)  
    obj = object(e)
    mods = modifiers(e)
    mods = map(x -> x.species, mods)

    print(io, "Edge \
    $(obj.species) → $(sub.species); Modified by: $(join(mods, ", "))" 
    )
end

function Base.show(io::IO, n::Node)
    # TODO Move out of declarations file.
    print(io, "Node • $(n.species) as a $(n.role)")
end
"""
    species(hg::EcologicalHypergraph)::Vector{String}

Returns a vector of all the species represented in an EcologicalHypergraph.
"""
function EcologicalNetworks.species(hg::EcologicalHypergraph)
    # TODO Move out of declarations file.
    return hg.species
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
    interactions(hg::EcologicalHypergraph)::Vector{Edge}

Returns a vector of all the edges represented in an `EcologicalHypergraph`
"""
function EcologicalNetworks.interactions(hg::EcologicalHypergraph)
    # TODO Move out of declarations file.
    return hg.edges
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
    role(n::Node)

Returns the role played by a node.
"""
function role(n::Node)
    # TODO Move out of declarations file.
    return n.role
end
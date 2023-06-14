"""
    species(hg::EcologicalHypergraph)::Vector{String}

Returns a vector of all the species represented in an EcologicalHypergraph.
"""
function EcologicalNetworks.species(hg::EcologicalHypergraph)::Vector{String}
    
    return hg.species
end

"""
    species(hg::EcologicalHypergraph)::Vector{String}

Returns a vector of all the species represented in an edge.
"""
function EcologicalNetworks.species(e::Edge)::Vector{String}
    
    return e.species
end

"""
    species(n::Node)

Returns the species represented by a node.
"""
function EcologicalNetworks.species(n::Node)::Vector{String}

    return n.species
end

"""
    interactions(hg::EcologicalHypergraph)::Vector{Edge}

Returns a vector of all the edges represented in an `EcologicalHypergraph`
"""
function EcologicalNetworks.interactions(hg::EcologicalHypergraph)

    return hg.edges
end

"""
    add_modifier!(e::Edge, n::Node, role::Symbol = :modifier)::Node

Add a modifier to `e` representing species `spp`. The optional role argument defaults to
`:modifier`. Once finished, this function also returns a reference to the node that was
added.
"""
function add_modifier!(e::Edge, spp::Vector{String}, role::Symbol = :modifier)::Node

    # TODO add checks to keep the state of the hg consistent.
    # All spp in hg spp set and so on.

    n = Node(e, spp, role)

    push!(e.nodes, n) 

    return n
end

"""
    nodes(e::Edge)

Returns a `vector` of the `Node`s in an `Edge`.
"""
function nodes(e::Edge)::Vector{Node}
  
    return e.nodes
end

"""
   subject(e::Edge)::Node 

Returns the `Node` playing the role of `:subject` in an `Edge`
"""
function subject(e::Edge)::Node

    return filter(x-> x.role == :subject, nodes(e))[1]
end

"""
   object(e::Edge)::Node 

Returns the `Node` playing the role of `:object` in an `Edge`
"""
function object(e::Edge)::Node

    return filter(x-> x.role == :object, nodes(e))[1]
end

"""
    modifiers(e::Edge)::Vector{Node}

Returns a vector of all the modifier nodes in an edge.
"""
function modifiers(e::Edge)::Vector{Node}

    return filter(x -> x.role != :subject && x.role != :object, nodes(e))
end

"""
    role(n::Node)::Symbol

Returns the role played by a node in it's edge.
"""
function role(n::Node)::Symbol

    return n.role
end

#----------------------------------------------------------------------------
#   Functions for getting/setting functions / vars / params and their vals
#----------------------------------------------------------------------------

function forwards_function(node::Node)

    return node.func.func_forwards
end

function set_forwards_function!(node::Node, f::Num)

    node.func.func_forwards = f
end

function backwards_function(node::Node)

    return node.func.func_backwards
end

function set_backwards_function!(node::Node, f::Num)

    node.func.func_backwards = f
end

function vars(node::Node)

    return node.func.vars
end

function set_vars!(node::Node, vars::Vector{Node})

    node.func.vars = vars
end

function params(node::Node)

    return node.func.params
end

function set_params!(node::Node, params::Vector{Union{Num, Vector{Num}}})

    node.func.params = params
end

function var_vals(node::Node)

    return node.func.var_vals
end

function set_var_vals!(node::Node, vals)

    node.func.var_vals = vals
end

function param_vals(node::Node)

    return node.func.param_vals
end

function set_param_vals!(node::Node, vals)

    node.func.param_vals = vals
end
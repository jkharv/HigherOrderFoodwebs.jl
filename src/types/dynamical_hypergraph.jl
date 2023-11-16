#-----------------------------------------------------------------------------------------
#   Types and Constructors 
#-----------------------------------------------------------------------------------------

mutable struct DynamicFunction
    
    func_forwards::Num
    func_backwards::Num

    params::Vector{Num}
    vars::Vector{Num}

    function DynamicFunction(t, spp::Vector{String})

        varnames = Symbol.(spp)
        
        vars = Vector{Num}()
        sizehint!(vars, length(varnames))

        for v in varnames

            var = @variables $v(t)
            append!(vars, var)
        end
       
        new(Num(1), Num(1), Vector{Num}(), vars) 
    end
end

mutable struct Node

    spp::Vector{String}
    role::Symbol

    edge::Any # WeakRef{Edge}

    func::DynamicFunction
       
    function Node(edge, species::Vector{String}, role::Symbol)

        # lol WeakRef chain ugly
        e = edge.value
        hg = e.hg.value
        func = DynamicFunction(hg.t, species)

        for v in func.vars
            
            hg.vars[v] = missing
        end

        new(species, role, edge, func)
    end
end

function Node(edge, species::String, role::Symbol)

    Node(edge, [species], role)
end

mutable struct Edge

    nodes::Vector{Node}
    hg::Any # WeakRef{DynamicalHypergraph}

    function Edge(hg, nodes::Vector{Node})

        new(nodes, WeakRef(hg))
    end
end

Base.zero(::Type{Edge}) = Edge(missing, Vector{Node}())
Base.iszero(e::Edge) = isempty(e.nodes)

mutable struct DynamicalHypergraph <: EcologicalHypergraph

    m::SparseMatrixCSC{Edge}
    spp::Vector{String}
    roles::Vector{Symbol}

    # Indep var for the system
    t::Num

    vars::Dict{Num, TermValue}
    params::Dict{Num, TermValue}

    function DynamicalHypergraph(m::SparseMatrixCSC{Edge}, 
                                 spp::Vector{String},
                                 roles::Vector{Symbol},
                                 t::Num)

        new(copy(m), copy(spp), copy(roles), t, Dict(), Dict())

    end
end

function DynamicalHypergraph(m::AbstractMatrix{Bool}, 
                            spp::Vector{String};
                            roles::Vector{Symbol} = Vector{Symbol}(),
                            addself = true)

    if(size(m)[1] != size(m)[2])

        throw(ArgumentError("Adjacency matrices must be square."))
    end

    roles = append!(roles, [:subject, :object]) 

    s = length(spp)
    am = SparseMatrixCSC(zeros(Edge, s, s))
    hg = DynamicalHypergraph(am, spp, roles, Num(1))

    timevar = :t 
    timevar = @variables $timevar
    hg.t = timevar[1]

    if addself
        
        m = copy(m)
        m[diagind(m)] .= true
    end

    for I ∈ eachindex(IndexCartesian(), m)

        if m[I] 
            
            # I should maybe wrap this fiddly bootstrapping stuff in a
            # constructor of it's own.
            am[I] = Edge(hg, Vector{Node}())
            am[I].nodes = [Node(WeakRef(am[I]), spp[I[1]], :subject), 
                           Node(WeakRef(am[I]), spp[I[2]], :object)]
        end
    end
    
    hg.m = am

    return hg
end

function DynamicalHypergraph(network::UnipartiteNetwork{Bool, String}; addself = true)

    return DynamicalHypergraph(copy(adjacency(network)), 
                               copy(species(network));
                               roles = Vector{Symbol}(),
                               addself = addself)
end

#-----------------------------------------------------------------------------------------
#   AbstractArrays Interface
#-----------------------------------------------------------------------------------------

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

#-----------------------------------------------------------------------------------------
#   Graph Structure Accessors
#-----------------------------------------------------------------------------------------

"""
    species(hg::EcologicalHypergraph)::Vector{String}

Returns a vector of all the species represented in an EcologicalHypergraph.
"""
function EcologicalNetworks.species(hg::EcologicalHypergraph)::Vector{String}
    
    return hg.spp
end

"""
    species(hg::EcologicalHypergraph)::Vector{String}

Returns a vector of all the species represented in an EcologicalHypergraph.
"""
function EcologicalNetworks.species(edge::Edge)::Vector{String}

    spp = []

    for n ∈ nodes(edge)

        append!(spp, species(n))
    end

    return unique!(spp)
end

"""
    species(n::Node)

Returns the species represented by a node.
"""
function EcologicalNetworks.species(n::Node)::Vector{String}

    return n.spp
end

"""
    interactions(hg::EcologicalHypergraph)::Vector{Edge}

Returns a vector of all the edges represented in an `EcologicalHypergraph`
"""
function EcologicalNetworks.interactions(hg::EcologicalHypergraph)::Vector{Edge}

    nzi = findall(!iszero, hg.m)

    return [hg.m[i] for i ∈ nzi]
end

"""
    add_modifier!(e::Edge, spp::Vector{String}, role::Symbol = :modifier)::Node

Add a modifier to `e` representing species `spp`. The optional role argument defaults to
`:modifier`. Once finished, this function also returns a reference to the node that was
added.
"""
function add_modifier!(e::Edge, spp::Vector{String}, role::Symbol = :modifier)::Node

    # TODO add checks to keep the state of the hg consistent.
    # All spp in hg spp set and so on.

    n = Node(WeakRef(e), spp, role)

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
    nodes(hg::EcologicalHypergraph)

Returns a `vector` of the `Node`s in an `EcologicalHypergraph`.
"""
function nodes(hg::EcologicalHypergraph)::Vector{Node}
  
    
    return collect(Iterators.flatten([nodes(e) for e ∈ interactions(hg)]))

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

# function remove!(hg::EcologicalHypergraph, sp::String)

#     if hg isa DynamicalHypergraph

#         # Identify var to delete
#         old_var = sp_to_var(hg, sp)

#         # Identify params to delete
#         old_params = []
#         for n in nodes(hg)

#             # I'm not sure I can reliably remove all the no longer needed params
#             # from the list.
#         end

#         # Delete them from the global list.
#         filter!(e -> first(e) ≠ old_var, hg.vars)
        
#         # Make those same changes at the node level  
#         for n ∈ nodes(hg)

#             filter!(x -> x ≠ old_var, n.func.vars)

#             sub = Dict(old_var => 0)

#             n.func.func_forwards = ModelingToolkit.simplify(substitute(n.func.func_forwards, sub))
#             n.func.func_forwards = ModelingToolkit.simplify(substitute(n.func.func_backwards, sub))
#         end
#     end

#     # Create new adjacency matrix.
#     s = length(species(hg)) - 1
#     am = SparseMatrixCSC(zeros(Edge, s, s))

#     # Create new species list
#     new_spp = copy(species(hg))
#     filter!(x -> x ≠ sp, new_spp)

#     # Copy data over.
#     for (j, obj) ∈ enumerate(new_spp)
#         for (i, sub) ∈ enumerate(new_spp)

#             am[i, j] = hg[sub, obj]
#         end
#     end

#     # Replace old with new
#     hg.m = am
#     hg.spp = new_spp
    
#     return hg
# end

#-----------------------------------------------------------------------------------------
#   Dynamics/Function Accessors
#-----------------------------------------------------------------------------------------

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

function set_initial_condition!(hg::EcologicalHypergraph, sp::String, val::TermValue)
    
    var = sp_to_var(hg, sp) 
    hg.vars[var] = val
end

function vars(node::Node)::Dict{Num, TermValue}

    vs = node.func.vars
    hg = node.edge.value.hg.value

    return filter(k -> k[1] ∈ vs , hg.vars)
end

function vars(edge::Edge)::Dict{Num, TermValue}

    v = Dict{Num, TermValue}()

    for n ∈ nodes(edge)

        merge!(v, vars(n))
    end

    return v
end

function vars(hg::EcologicalHypergraph)::Dict{Num, TermValue}

    return hg.vars
end

function set_vars!(node::Node, var)
    
    # var should be ::Pair{Num, TermValue} For some reason Julia won't type
    # match into pairs. So this needs to be ::Any until this gets fixed

    if var[1] ∉ node.func.var

        error("You can only set the value of existing variables with set_vars!")
    end

    hg = node.edge.value.hg.value
    hg.vars[var[1]] = var[2]
end

function params(node::Node)::Dict{Num, TermValue}

    ps = node.func.params
    hg = node.edge.value.hg.value

    return filter(k -> k[1] ∈ ps , hg.params)
end

function params(edge::Edge)::Dict{Num, TermValue}

    p = Dict{Num, TermValue}()

    for n ∈ nodes(edge)

        merge!(p, params(n))
    end

    return p
end

function params(hg::EcologicalHypergraph)::Dict{Num, TermValue}

    return hg.params
end

function set_param!(node::Node, param)

    # param should be ::Pair{Num, TermValue} For some reason Julia won't type
    # match into pairs. So this needs to be ::Any until this gets fixed

    # if param[1] ∉ node.func.params

    #     error("You can only set the value of existing parameters with set_param!")
    # end
    # The code rn relies on _creating_ parameters with this function, but that makes
    # the behaviour of this function inconssistent with set_vars!. I should think more
    # about this.

    hg = node.edge.value.hg.value
    hg.params[param[1]] = param[2]
    push!(node.func.params, param[1])
end

function set_params!(node::Node, params)

    for p in params

        set_param!(node, p)
    end
end
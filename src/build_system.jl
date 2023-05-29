"""
    community_matrix(hg::EcologicalHypergraph)::Matrix{Num}

Creates a community matrix out of an `EcologicalHypergraph`. The elements of the matrix
are `Num` allowing symbolic manipulations of the matrix using `Symbolics.jl`.
"""
function community_matrix(hg::EcologicalHypergraph)::Matrix{Num}

    s = length(hg.species)
    cm = zeros(Num, s, s)

    indices = Dict(hg.species .=> 1:s)

    for e in hg.edges

        r = indices[species(subject(e))]
        c = indices[species(object(e))]

        cm[r,c] = forwards_function(e)
        cm[c,r] = backwards_function(e)
    end

    return cm
end

function forwards_function(e::Edge)

    f = Num(1)

    for n in e.nodes

        f = f * forwards_function(n)
    end

    return f
end

function backwards_function(e::Edge)

    f = Num(1)

    for n in e.nodes

        f = f * backwards_function(n)
    end

    return f
end

"""
Returns a list with exactly one node for each species.

p much just used to eliminate code duplication in the implemenation
of `get_hypergraph_variables` and `get_hypergraph_variable_dict`.
"""
function get_minimal_node_vec(hg::EcologicalHypergraph)::Vector{Node}

    spp = species(hg)
    nodes = [] 

    for (i, sp) in enumerate(spp)

        e_ind = findfirst(x -> species(subject(x)) == sp, interactions(hg))
        node = subject(interactions(hg)[e_ind])
        
        push!(nodes, node)
    end
    
    return nodes
end

function get_hypergraph_variables(hg::EcologicalHypergraph)::Vector{Num}

    nodes = get_minimal_node_vec(hg)
    f(x) = vars(x)[1]
    return f.(nodes)
end

function get_hypergraph_variable_dict(hg::EcologicalHypergraph)::Dict{Num, Float64}

    nodes = get_minimal_node_vec(hg)

    var(x) = vars(x)[1]
    #var0(x) = x.var_val.val
    var0(x) = rand() # TEMP until I make @functional_form set u0.     

    return Dict(var.(nodes) .=> var0.(nodes))
end

function get_hypergraph_parameter_dict(hg::EcologicalHypergraph)::Dict{Num, Float64}

    params = Dict{Num, Float64}()

    for e in interactions(hg)
        for n in nodes(e)

            syms = params(n)
            vals = reify.(param_vals(n))

            pairs = syms .=> vals
            
            for p in pairs

                push!(params, p)
            end
        end
    end

    return(params)
end

"""
    build_symbolic_system(hg::EcologicalHypergraph)::ODESystem

Takes an `EcologicalHypergraph` and returns an `ODESystem` object from `Symbolics.jl`.
The equations in this object all remain in symbolic form.

TODO: function to substitute in the params defined in the hg.
"""
function build_symbolic_system(hg::EcologicalHypergraph)::ODESystem

    cm = community_matrix(hg)
    vars = get_hypergraph_variables(hg)
    funcs = mapslices(sum, cm; dims = 2)

    D = Differential(hg.t)
    dbs = D.(vars) 
    eqs = Equation.(dbs, funcs)

    return ODESystem(eqs, name = :Hypergraph)
end

function build_numerical_system(hg::EcologicalHypergraph, tspan)::ODEProblem

    sym_sys = build_symbolic_system(hg)
    
    var_dict = get_hypergraph_variable_dict(hg)
    param_dict = get_hypergraph_parameter_dict(hg)

    return ODEProblem(sym_sys, var_dict, tspan, param_dict)
end
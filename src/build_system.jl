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

        r = indices[species(subject(e))[1]]
        c = indices[species(object(e))[1]]

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

    for sp ∈ spp

        e_ind = findfirst(x -> species(subject(x))[1] == sp, interactions(hg))
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

    parameters = Dict{Num, Float64}()

    for e in interactions(hg)
        for n in nodes(e)

            if length(params(n)) != length(param_vals(n))
                error("params and param vals differ in length")
            end

            syms = params(n)
            if length(syms) > 0

                syms = reduce(vcat, syms)
                # reduce(vcat, x) will return a scalar if x contains only a single.
                # scalar. This should be avoided.
                if syms isa Num
                    syms = [syms]
                end
            end

            vals = param_vals(n)
            if length(vals) > 0

                vals = reduce(vcat, vals)
                
                if vals isa DistributionOption 
                    vals = [vals]
                end
            end 
            vals = reify.(vals)

            pairs = syms .=> vals

            for p in pairs

                push!(parameters, p)
            end
        end
    end

    return(parameters)
end

# These functions are here temporarilly until I rework the Hypergraph type to use a Dict
# directly, get rid of most of the code in this file, and lose most of the accessors that
# will no longer be necessary.
function get_var_dict(hg)::Dict{Num, Float64}

    return get_hypergraph_variable_dict(hg)
end

function get_param_dict(hg)::Dict{Num, Float64}

    return get_hypergraph_parameter_dict(hg);
end

"""
    ODESystem(hg::EcologicalHypergraph)

Constructor for an ODESystem from `ModelingToolkit.jl` which takes an
`EcologicalHypergraph`. This can be passed to `DifferentialEquations.jl` for numerical
solving.
"""
function ModelingToolkit.ODESystem(hg::EcologicalHypergraph)::ODESystem

    cm = community_matrix(hg)
    vars = get_hypergraph_variables(hg)
    funcs = mapslices(sum, cm; dims = 2)

    D = Differential(hg.t)
    dbs = D.(vars) 
    eqs = Equation.(dbs, funcs)

    return ODESystem(eqs, name = :Hypergraph)
end
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

        f = f * n.func_forwards
    end

    return f
end

function backwards_function(e::Edge)

    f = Num(1)

    for n in e.nodes

        f = f * n.func_backwards
    end

    return f
end

"""
    get_hypergraph_variables(hg::EcologicalHypergraph)

Returns a `Vector{Num}` containing references to all species variables in the same order
as the species were defined when the hypergraph was created.
"""
function get_hypergraph_variables(hg::EcologicalHypergraph)::Vector{Num}

    spp = species(hg)
    vars = zeros(Num ,length(spp))

    for (i, sp) in enumerate(spp)

        e_ind = findfirst(x -> species(subject(x)) == sp, hg.edges)
        var = subject(hg.edges[e_ind]).var
        vars[i] = var
    end
    
    return vars
end

"""
    build_system(hg::EcologicalHypergraph)::ODESystem

Takes an `EcologicalHypergraph` and returns an `ODESystem` object from `Symbolics.jl`.
This object can then be given to the `ODEProblem` constructor supplied by `Symbolics.jl`
which creates a numeric system which can be integrated using `solve` from
`DifferentialEquations.jl`
"""
function build_system(hg::EcologicalHypergraph)::ODESystem

    cm = community_matrix(hg)
    
    funcs = mapslices(sum, cm; dims = 2)
    vars = get_hypergraph_variables(hg)
    
    D = Differential(hg.t)
    dbs = D.(vars) 
    eqs = Equation.(dbs, funcs)

    return ODESystem(eqs, name = :Hypergraph)
end
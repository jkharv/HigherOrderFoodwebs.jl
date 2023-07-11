"""
    community_matrix(hg::EcologicalHypergraph)::Matrix{Num}

Creates a community matrix out of an `EcologicalHypergraph`. The elements of the matrix
are `Num` allowing symbolic manipulations of the matrix using `Symbolics.jl`.
"""
function community_matrix(hg::EcologicalHypergraph)::Matrix{Num}

    s = length(hg.species)
    cm = zeros(Num, s, s)

    indices = Dict(hg.species .=> 1:s)

    # This orders the matrix in the same way as the species vec in hg
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

function reify!(d::Dict{Num, DistributionOption})::Dict{Num, Real}

    k = collect(keys(d))
    v = values(d)
    v = reify.(v)

    return Dict(k .=> v)
end

function string_to_var(hg::EcologicalHypergraph, s::String)

    x = findfirst(x -> subject(x).species[1] == s, interactions(hg))
    spp = subject(interactions(hg)[x])
    var = collect(keys(vars(spp)))[1]

    return var
end

"""
    ODESystem(hg::EcologicalHypergraph)

Constructor for an ODESystem from `ModelingToolkit.jl` which takes an
`EcologicalHypergraph`. This can be passed to `DifferentialEquations.jl` for numerical
solving.
"""
function ModelingToolkit.ODESystem(hg::EcologicalHypergraph)

    cm = community_matrix(hg)
    funcs = mapslices(sum, cm; dims = 2)

    p = reify!(params(hg))
    vals = rand(Uniform(0,1), length(vars(hg)))
    v = collect(keys(vars(hg)))
    v = Dict(v .=> vals)

    D = Differential(hg.t)
    dbs = D.(string_to_var.(Ref(hg), species(hg))) 
    eqs = Equation.(dbs, funcs)
    
    return ODESystem(eqs, name = :Hypergraph, defaults=merge(p, v))
end
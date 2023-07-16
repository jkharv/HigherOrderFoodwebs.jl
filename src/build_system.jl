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

"""
    ODESystem(hg::EcologicalHypergraph)

Constructor for an ODESystem from `ModelingToolkit.jl` which takes an
`EcologicalHypergraph`. This can be passed to `DifferentialEquations.jl` for numerical
solving.
"""
function ModelingToolkit.ODESystem(hg::EcologicalHypergraph)

    cm = CommunityMatrix(hg)
    funcs = mapslices(sum, cm; dims = 2)

    p = reify!(params(hg))
    v = reify!(vars(hg)) 

    D = Differential(hg.t)
    dbs = D.(string_to_var.(Ref(hg), species(hg))) 
    eqs = Equation.(dbs, funcs)
    
    return ODESystem(eqs, name = :Hypergraph, defaults=merge(p, v))
end
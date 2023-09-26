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

function reify(d::Dict{Num, TermValue})

    rd = Dict{Num, Float64}()

    for k in keys(d)

        if d[k] isa Distribution

            rd[k] = rand(d[k])
            continue
        elseif d[k] isa Real

            rd[k] = float(d[k])
            continue 
        elseif d[k] isa Missing

            error("You must completely specify the initial conditions.")
        end
    end

    return rd
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

    p = reify(params(hg))
    v = reify(vars(hg)) 

    D = Differential(hg.t)
    dbs = D.(sp_to_var.(Ref(hg), species(hg))) 
    eqs = Equation.(dbs, funcs)
    
    return ODESystem(eqs, name = :Hypergraph, defaults=merge(p, v))
end
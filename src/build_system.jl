function Base.show(io::IO, ::MIME"text/plain", cm::CommunityMatrix)

    for r ∈ eachrow(cm) 
        for e ∈ r
       
            iszero(e) ? print(io, "⬜") : print(io, "⬛")
        end
        println(io, "")
    end
end

function build_ode_system(fwm::FoodwebModel)::FoodwebModel

    D = Differential(fwm.t)
    f(x) = map(x -> fwm.vars[x], x)
    d(x) = map(x -> D(x), x)

    cm = CommunityMatrix(fwm)

    lhs = (d ∘ f ∘ species)(fwm)
    rhs = map(sum, eachrow(cm))
    eqs = lhs .~ rhs

    p = fwm.params
    v = (collect ∘ values)(fwm.vars)
    t = fwm.t
    u0 = fwm.u0
    p_vals = fwm.param_vals

    sys = ODESystem(eqs, t, v, p; name = :Foodweb)
    prob = ODEProblem(complete(sys), u0, (0,1000), p_vals)

    return FoodwebModel(
        fwm.hg,
        fwm.dynamic_rules,
        fwm.t,
        fwm.vars,
        fwm.u0,
        fwm.params,
        fwm.param_vals,
        prob,
        cm
    )
end
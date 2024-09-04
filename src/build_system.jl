function build_ode_system(fwm::FoodwebModel)::FoodwebModel

    # If u0 is missing we will set them all to zero.
    # Only the species though.

    for sp ∈ species(fwm) 

        v = fwm.vars[sp]

        if v ∈ keys(fwm.u0)

            break
        else
            
            fwm.u0[v] = 0.0
        end
    end

    vars = merge(fwm.vars, fwm.aux_vars)

    D = Differential(fwm.t)
    f(x) = map(x -> vars[x], x)
    d(x) = map(x -> D(x), x)

    cm = CommunityMatrix(fwm)

    var_syms = cm.spp

    lhs = (d ∘ f)(var_syms)
    rhs = map(sum, eachrow(cm))
    eqs = lhs .~ rhs

    p = fwm.params
    v = (collect ∘ values)(vars)
    t = fwm.t
    u0 = fwm.u0
    p_vals = fwm.param_vals

    sys = ODESystem(eqs, t, v, p; name = :Foodweb)
    prob = ODEProblem(structural_simplify(sys), u0, (0,1000), p_vals)

    return FoodwebModel(
        fwm.hg,
        fwm.dynamic_rules,
        fwm.t,
        fwm.vars,
        fwm.u0,
        fwm.params,
        fwm.param_vals,
        fwm.aux_dynamic_rules,
        fwm.aux_vars,
        prob,
        cm
    )
end
mutable struct FoodwebModelSolver

    fwm::FoodwebModel
    integrator::OrdinaryDiffEq.ODEIntegrator
end

function CommonSolve.init(fwm::FoodwebModel, args...; kwargs...)

    if ismissing(fwm.odes)

        # I should probably inline this definition
        fwm = build_ode_system(fwm)
    end

    return FoodwebModelSolver(
        fwm, 
        init(fwm.odes, args...; kwargs...)
    )
end

function CommonSolve.step!(fwm::FoodwebModelSolver, args...; kwargs...)

    step!(fwm.integrator, args...; kwargs...)
end

function CommonSolve.solve!(fwm::FoodwebModelSolver)

    solve!(fwm.integrator)
end

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

    sys = ODESystem(eqs, 
        fwm.t, 
        (collect ∘ values)(vars), 
        fwm.params; 
        name = :Foodweb
    )
    prob = ODEProblem(
        structural_simplify(sys), 
        fwm.u0, 
        (0,1000), 
        fwm.param_vals
    )

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
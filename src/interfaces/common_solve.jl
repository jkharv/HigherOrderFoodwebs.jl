mutable struct FoodwebModelSolver

    fwm::FoodwebModel
    integrator::OrdinaryDiffEq.ODEIntegrator
end

function CommonSolve.init(fwm::FoodwebModel, args...; kwargs...)

    if ismissing(fwm.odes)

        # I should probably inline this definition
        build_ode_system!(fwm)
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

function build_ode_system!(fwm::FoodwebModel)

    vars = merge(fwm.vars, fwm.aux_vars)
    cm = CommunityMatrix(fwm);

    D = Differential(fwm.t)
    lhs = [D(vars[x]) for x in cm.spp]
    rhs = [sum(x) for x in eachrow(cm)]
    eqs = lhs .~ rhs

    default_u0 = Dict((collect ∘ values)(vars) .=> zeros(length(vars)))
    for x in keys(fwm.u0)

        # Make sure that user supplied values take precedence over
        # setting everything to zero.
        default_u0[x] = fwm.u0[x]
    end
    default_p  = fwm.param_vals

    sys = ODESystem(
        eqs, 
        fwm.t, 
        (collect ∘ values)(vars), 
        fwm.params; 
        name = :Foodweb,
        defaults = merge(default_u0, default_p)
    )

    ModelingToolkit.calculate_jacobian(sys)

    prob = ODEProblem(structural_simplify(sys))

    fwm.odes = prob
    fwm.community_matrix = cm

    return 
end
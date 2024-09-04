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

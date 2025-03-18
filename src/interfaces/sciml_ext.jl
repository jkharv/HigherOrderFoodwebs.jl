function SciMLBase.ODEProblem{iip, specialization}(fwm::FoodwebModel; kwargs...) where {iip, specialization}

    s = ODESystem(fwm)
    s = structural_simplify(s)
    # kwargs on ODEProblem just get handed off to the solver.
    s = ODEProblem{iip, specialization}(s; kwargs...)

    return s 
end

function SciMLBase.ODEProblem(fwm::FoodwebModel; kwargs...)

    # Same defaults for iip and specialize as in DiffEqBase
    return ODEProblem{true, SciMLBase.AutoSpecialize}(fwm; kwargs...)
end

function ModelingToolkit.ODESystem(fwm::FoodwebModel)

    vars = variables(fwm)
    cm = CommunityMatrix(fwm)

    D = ModelingToolkit.D_nounits
    lhs = D.(vars)
    rhs = [sum(x) for x in eachrow(cm)]
    eqs = lhs .~ rhs

    p0 = Dict([x => get_value(fwm.params, x) for x in fwm.params.vars])
    u0 = Dict([x => get_value(fwm.vars, x) for x in fwm.vars.vars])

    sys = ODESystem(
        eqs, 
        ModelingToolkit.t_nounits, 
        vars, 
        variables(fwm.params); 
        name = :Foodweb,
        defaults = merge(p0, u0)
    )

    # Despite the lack of !, this is a mutating function.
    # This is insanely bottlenecking performance.
    # calculate_jacobian(sys)

    return sys 
end
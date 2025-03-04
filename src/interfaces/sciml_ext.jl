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

    vars = vcat(fwm.vars, fwm.aux_vars)
    cm = CommunityMatrix(fwm);

    D = Differential(fwm.t)
    lhs = D.(vars)
    rhs = [sum(x) for x in eachrow(cm)]
    eqs = lhs .~ rhs

    default_p  = fwm.param_vals 
    default_u0 = Dict((collect ∘ values)(vars) .=> zeros(length(vars)))

    for x in keys(fwm.u0)

        # Make sure that user supplied values take precedence over setting
        # everything to zero.
        default_u0[x] = fwm.u0[x]
    end

    sys = ODESystem(
        eqs, 
        fwm.t, 
        (collect ∘ values)(vars), 
        fwm.params; 
        name = :Foodweb,
        defaults = merge(default_u0, default_p)
    )

    # Despite the lack of !, this is a mutating function.
    # This is insanely bottlenecking performance.
    # calculate_jacobian(sys)

    return sys 
end
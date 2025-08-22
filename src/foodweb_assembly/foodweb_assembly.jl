function assemble_foodweb(prob::ODEProblem; 
    solver = AutoTsit5(Rosenbrock23()), 
    extra_transient_time = 0,
    time_between_invasions = 100,
    invader_density = 0.1,
    extinction_threshold = 1e-20,
    extra_callbacks = [], 
)

    if !(prob.f.sys isa FoodwebModel)

        error("ODEProblem must be created with HigherOrderFoodwebs.jl")
    end

    fwm = prob.f.sys

    invasion_sequence = trophic_ordering(fwm);

    n_invasions = length(invasion_sequence)
    tend_invasions = time_between_invasions * n_invasions
    tend = tend_invasions + extra_transient_time
    invasion_times = collect(1:time_between_invasions:tend_invasions)
    tspan = (1, tend)

    is = InvasionSequenceCallback(fwm, invasion_sequence, invasion_times;
        invader_density = invader_density,
    )
    et = ExtinctionThresholdCallback(fwm, extinction_threshold)

    sol = solve(prob, solver, 
        callback = CallbackSet(is, et, extra_callbacks...),
        tspan = tspan,
        tstops = invasion_times,
        saveat = tend 
    )

    return remake(prob, u0 = sol[end])
end
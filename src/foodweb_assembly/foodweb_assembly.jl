const LOW_DENSITY = 0.1;

function assemble_foodweb(fwm::FoodwebModel, solver = AutoTsit5(Rosenbrock23()); 
    extra_transient_time = 0,
    kwargs...
)

    defaults = (
        maxiters = 1e7,
        force_dtmin = true,
        save_on = false,
        reltol = 1e-3,
        abstol = 1e-3,
        tspan = (1, 100 * richness(fwm) + 200)
    )

    kwargs = merge(defaults, kwargs) 

    integrator, sys = introduce_species(fwm, solver; extra_transient_time, kwargs...)
    return reinitialize(fwm, integrator, sys)
end

function introduce_species(fwm::FoodwebModel, solver; extra_transient_time, kwargs...)

    invasion_sequence = trophic_ordering(fwm)

    sys = structural_simplify(ODESystem(fwm))
    prob = ODEProblem(sys)
    cb = ExtinctionThresholdCallback(fwm, 1e-20)
   
    integrator = init(prob, solver;
        callback = cb, 
        kwargs...
    );   

    while !isempty(invasion_sequence)

        sp = popfirst!(invasion_sequence)
        v = get_variable(fwm, sp)
        integrator[v] = LOW_DENSITY
        step!(integrator, 100)
    end

    if extra_transient_time > 0

        step!(integrator, extra_transient_time)
    end

    return (integrator, sys)
end

function reinitialize(fwm::FoodwebModel, integrator, sys)

    u0 = Dict{Num, Float64}()

    for v in variables(fwm)

        val = integrator[v][end]
        push!(u0, v => val) 
    end

    return ODEProblem(sys, u0)
end

function merge_args(defaults, user)

    # I need to deal with Callbacks seperately
    # I'll do that later tho. (maybe)
    return merge(user, defaults)
end
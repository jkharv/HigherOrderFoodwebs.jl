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

    integrator = introduce_species(fwm, solver; extra_transient_time, kwargs...)
    return reinitialize(fwm, integrator)
end

function introduce_species(fwm::FoodwebModel, solver; extra_transient_time, kwargs...)

    invasion_sequence = trophic_ordering(fwm)

    prob = ODEProblem(fwm)
    cb = ExtinctionThresholdCallback(fwm, 1e-20)
   
    integrator = init(prob, solver;
        callback = cb, 
        kwargs...
    );   

    while !isempty(invasion_sequence)

        sp = popfirst!(invasion_sequence)
        v = sym_to_var(fwm, sp)
        integrator[v] = LOW_DENSITY
        step!(integrator, 100)
    end

    if extra_transient_time > 0

        step!(integrator, extra_transient_time)
    end

    return integrator
end

function reinitialize(fwm::FoodwebModel, integrator)

    u0 = Dict{Num, Number}()

    for v in variables(fwm)

        u0[v] = integrator[v][end]
    end

    return FoodwebModel(
        fwm.hg,
        fwm.t,
        fwm.dynamic_rules,
        fwm.aux_dynamic_rules,
        fwm.vars,
        fwm.params,
        fwm.param_vals,
        u0,
    )
end

function merge_args(defaults, user)

    # I need to deal with Callbacks seperately
    # I'll do that later tho. (maybe)
    return merge(user, defaults)
end
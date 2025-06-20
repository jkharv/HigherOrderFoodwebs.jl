const LOW_DENSITY = 0.1;

function assemble_foodweb(fwm::FoodwebModel, solver = AutoTsit5(Rosenbrock23()); 
    extra_transient_time = 0,
    compile_symbolics = true,
    compile_jacobian = false,
    kwargs...
)

    defaults = (
        maxiters = 1e7,
        force_dtmin = true,
        save_on = false,
        reltol = 1e-3,
        abstol = 1e-3
    )
    kwargs = merge(defaults, kwargs) 
    
    prob = ODEProblem(
        fwm, 
        (1, 100 * richness(fwm) + 200); 
        compile_symbolics,
        compile_jacobian
    )

    u0 = introduce_species(fwm, prob, solver; extra_transient_time, kwargs...)

    return remake(prob; u0 = u0)
end

function assemble_stochastic_foodweb(fwm::FoodwebModel, solver = SOSRA(); 
    extra_transient_time = 0,
    compile_symbolics = true,
    compile_jacobian = false,
    kwargs...
)

    defaults = (
        maxiters = 1e7,
        force_dtmin = true,
        save_on = false,
        reltol = 1e-3,
        abstol = 1e-3
    )
    kwargs = merge(defaults, kwargs) 
    
    prob = SDEProblem(
        fwm, 
        default_noise(fwm, 0.01), 
        (1, 100 * richness(fwm) + 200); 
        compile_symbolics,
        compile_jacobian
    )

    u0 = introduce_species(fwm, prob, solver; extra_transient_time, kwargs...)

    return remake(prob; u0 = u0)
end


function introduce_species(fwm, prob, solver; extra_transient_time, kwargs...)

    invasion_sequence = trophic_ordering(fwm)
    cb = ExtinctionThresholdCallback(fwm, 1e-20)

    integrator = init(prob, solver;
        callback = cb, 
        kwargs...
    );   

    while !isempty(invasion_sequence)

        sp = popfirst!(invasion_sequence)
        integrator[sp] = LOW_DENSITY

        # Recalculate the derivatives to account for discontinuity.
        u_modified!(integrator, true)
        step!(integrator, 100)
    end

    step!(integrator, extra_transient_time)

    return integrator.u
end

function merge_args(defaults, user)

    # I need to deal with Callbacks seperately
    # I'll do that later tho. (maybe)
    return merge(user, defaults)
end
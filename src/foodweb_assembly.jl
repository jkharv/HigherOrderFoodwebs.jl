const LOW_DENSITY = 0.01;

function assemble_foodweb(fwm::FoodwebModel, solver = Rosenbrock23(); kwargs...)

    defaults = (
        maxiters = 1e7,
        force_dtmin = true,
        save_on = false,
        tspan = (1, 100*length(species(fwm)))
    )

    args = merge(defaults, kwargs) 

    integrator = introduce_species(fwm, solver; kwargs...)
    return reinitialize(fwm, integrator)
end

function introduce_species(fwm::FoodwebModel, solver; kwargs...)

    invasion_sequence = trophic_ordering(fwm)

    prob = ODEProblem(fwm)
    cb = ExtinctionThresholdCallback(fwm, 1e-20)
    tspan = (1, 100 * richness(fwm) + 200)
   
    integrator = init(prob, solver;
        tspan = tspan, 
        save_on = false,
        callback = cb, 
        kwargs...
    );   

    while !isempty(invasion_sequence)

        spp = popfirst!(invasion_sequence)
        integrator[fwm.conversion_dict[spp]] = LOW_DENSITY
        step!(integrator, 100)
    end

    step!(integrator, 100)

    return integrator
end

function reinitialize(fwm::FoodwebModel, integrator)

    u0 = Dict{Num, Number}()

    # Species
    for v in fwm.vars

        u0[v] = integrator[v][end]
    end

    # Aux vars
    for v in fwm.aux_vars

        u0[v] = integrator[v][end]
    end

    return FoodwebModel(
        fwm.hg,
        fwm.t,
        fwm.dynamic_rules,
        fwm.aux_dynamic_rules,
        fwm.params,
        fwm.vars,
        fwm.aux_vars,
        fwm.conversion_dict,
        fwm.param_vals,
        u0,
    )
end

function merge_args(defaults, user)

    # I need to deal with Callbacks seperately
    # I'll do that later tho. (maybe)
    return merge(user, defaults)
end

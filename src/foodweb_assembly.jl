const LOW_DENSITY = 0.0001;

function assemble_foodweb(fwm::FoodwebModel, solver = Rosenbrock23(); args...)

    defaults = (
        maxiters = 1e7,
        force_dtmin = true,
        save_on = false,
        tspan = (1, 100*length(species(fwm)))
    )

    args = merge(defaults, args) 

    integrator = introduce_species(fwm, solver; args...)
    return reinitialize(integrator)
end

function introduce_species(fwm::FoodwebModel, solver; args...)

    invasion_sequence = trophic_ordering(fwm)

    cb = ExtinctionThresholdCallback(fwm, 1e-20)

    integrator = init(fwm, solver; callback = cb, args...);

    while !isempty(invasion_sequence)

        spp = popfirst!(invasion_sequence)
        integrator.integrator[fwm.conversion_dict[spp]] = 100*LOW_DENSITY
        step!(integrator, 100)
    end

    return integrator
end

function reinitialize(s::FoodwebModelSolver)

    fwm = s.fwm
    integrator = s.integrator

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
        nothing, # These will be lazily generated anew when
        nothing  # someone tries to simulate this model later.
    )
end

function merge_args(defaults, user)

    # I need to deal with Callbacks seperately
    # I'll do that later tho. (maybe)
    return merge(user, defaults)
end
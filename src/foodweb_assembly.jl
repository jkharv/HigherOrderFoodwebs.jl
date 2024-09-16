const LOW_DENSITY = 0.0001;

function assemble_foodweb(fwm::FoodwebModel)

    invasion_sequence = trophic_ordering(fwm)

    cb = ExtinctionThresholdCallback(fwm, 1e-20)

    integrator = init(
        fwm, RK4();
        callback = cb,
        abstol = 1e-6, 
        reltol = 1e-3, 
        tspan = (1, 1000)
        );

    while !isempty(invasion_sequence)

        spp = popfirst!(invasion_sequence)
        integrator.integrator[fwm.vars[spp]] = 10*LOW_DENSITY
        step!(integrator, 100.0)
    end

    u0 = Dict{Num, Number}()

    # Species
    for (s, v) in fwm.vars

        u0[v] = integrator.integrator.sol[v][end]
    end

    # Aux vars
    for (s, v) in fwm.aux_vars

        u0[v] = integrator.integrator.sol[s][end]
    end

    return FoodwebModel(
        fwm.hg,
        fwm.dynamic_rules,
        fwm.t,
        fwm.vars,
        u0,
        fwm.params,
        fwm.param_vals,
        fwm.aux_dynamic_rules,
        fwm.aux_vars,
        fwm.odes,
        fwm.community_matrix
    )
end

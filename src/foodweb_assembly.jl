const LOW_DENSITY = 0.0001;

function assemble_foodweb!(fwm::FoodwebModel)

    fwm = HigherOrderFoodwebs.build_ode_system(fwm)
    cm = fwm.community_matrix

    producers = filter(x -> isproducer(fwm, x), species(fwm))
    consumers = setdiff(species(fwm), producers)

    cb = ExtinctionThresholdCallback(1e-10)

    integrator = init(
        fwm, Tsit5();
        callback = cb,
        abstol = 1e-6, 
        reltol = 1e-3, 
        save_everystep = true,
        tspan = (1, 1000)
        );

    # Start by adding the producers to the community.
    # Initially all at their carrying capacity.
    for p ∈ producers

        pnum = fwm.vars[p]
        integrator.integrator[pnum] = 1.0 
        u_modified!(integrator.integrator, true)
    end

    # Let them grow just a little bit.
    step!(integrator, 10.0)

    established_spp = producers
    unestablished_spp = consumers
    invasion_count = 0
    potential_invaders = length(consumers)

    while !isempty(unestablished_spp)         && 
           invasion_count < 2 * richness(fwm) && 
           potential_invaders > 0
        
        # Find which species should be next to invade
        rates = Dict([x => low_density_growth_rate(x, integrator) for x ∈ unestablished_spp])
        max_rate = findmax(rates)
      
        # Add that species at low density to the community.
        new_sp_num = fwm.vars[max_rate[2]]
        integrator.integrator[new_sp_num] = LOW_DENSITY
        u_modified!(integrator.integrator, true)

        # Give it time to grow
        step!(integrator, 50.0)

        # Get an up-to-date list of all the species established in the community.
        established_spp = []
        for sp ∈ species(fwm)

            if integrator.integrator[sp] > 0
                push!(established_spp, sp)
            end
        end
        
        # Put the one we just tried on the list no matter if it established or not.
        # We don't want to try it again next round.
        push!(established_spp, max_rate[2])        

        unestablished_spp = setdiff(species(fwm), established_spp) 
        invasion_count += 1
        potential_invaders = length(filter(x -> x[2] > 0, rates))
        println(potential_invaders)
    end

    return integrator
end

function low_density_growth_rate(sp::Symbol, integrator::FoodwebModelSolver)::Float64

    fwm = integrator.fwm
    cm = fwm.community_matrix

    # Get the equation of state for the focal species.
    cm_row = [cm[sp, x] for x ∈ cm.spp]
    sp_eq  = sum(cm_row)
   
    # Get the current state of the foodweb together.
    v = (collect ∘ values)(fwm.vars)
    av = (collect ∘ values)(fwm.aux_vars)
    
    u = Dict{Num, Float64}()
    for n ∈ vcat(v, av)

        u[n] = integrator.integrator[n]
    end

    # Set the species of interest to low density.
    sp = fwm.vars[sp]
    u[sp] = LOW_DENSITY

    rate = substitute(sp_eq, merge(fwm.param_vals, u))

    return rate.val
end
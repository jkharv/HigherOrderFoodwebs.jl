mutable struct RichnessTerminationCallbackCondition

    init_richness::Int64
    critical_richness::Float64
    fwm::FoodwebModel

    function RichnessTerminationCallbackCondition(fwm, critical_richness)

        new(richness(fwm), critical_richness, fwm)
    end
end

function (cond::RichnessTerminationCallbackCondition)(u, t, integrator)

    idxs = variable_index.(Ref(integrator), species(cond.fwm))

    return current_richness(u, idxs) < (cond.critical_richness * cond.init_richness)
end

function current_richness(u, idxs)

    u_spp = getindex.(Ref(u), idxs)

    count = 0
    for i in u_spp

        if i > 0.0
            count += 1
        end
    end

    return count
end

function richness_termination_affect!(integrator)

    terminate!(integrator)
end

# Initialize the callback by setting what species richness was at the begining
# of the simulation.
function initialize_richness_cb!(c, u, t, integrator, fwm, cond)

    idxs = variable_index.(Ref(integrator), species(cond.fwm))
    cond.init_richness = current_richness(u, idxs)

    return
end

function RichnessTerminationCallback(fwm, critical_richness)

    cond = RichnessTerminationCallbackCondition(fwm, critical_richness)
    init_cb!(w, x, y, z) = initialize_richness_cb!(w, x, y, z, fwm, cond)

    return DiscreteCallback(cond, richness_termination_affect!;
        initialize = init_cb!
    )
end
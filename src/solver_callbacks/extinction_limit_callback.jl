function extinction_threshold_affect(fwm, threshold, integrator, extinctions)
           
    for sp ∈ species(fwm)        

        i = variable_index(integrator, sp)
        # integrator.u[i] ≠ 0 avoids double counting
        if (integrator.u[i] < threshold) & (integrator.u[i] ≠ 0)
            
            integrator.u[i] = 0.0
            push!(extinctions, (integrator.t, sp))
        end 
    end
end

function extinction_threshold_condition(u,t,integrator)

    # Runs at every step
    return true
end

function ExtinctionThresholdCallback(
    fwm::FoodwebModel{T}, 
    extinction_threshold::Float64; 
    extinction_history = Vector{Tuple{Float64, T}}()) where T

    f(x) = extinction_threshold_affect(fwm, extinction_threshold, x, extinction_history)

    return DiscreteCallback(extinction_threshold_condition, f)
end
function extinction_threshold_affect(fwm, threshold, integrator, extinctions)
           
    indices_num = integrator.f.sys.index_cache.unknown_idx
    indices_sym = integrator.f.sys.index_cache.symbol_to_variable

    indices(x) = indices_num[indices_sym[x]]


    for sp ∈ species(fwm)        

        if 0.0 < integrator.u[indices(sp)] < threshold
            
            integrator.u[indices(sp)] = 0.0
            push!(extinctions, (integrator.t, sp))
        else

            # no change
        end
    end
end

function extinction_threshold_condition(u,t,integrator)

    # Run at every step
    return true
end

function ExtinctionThresholdCallback(
    fwm::FoodwebModel{T}, 
    extinction_threshold::Float64; 
    extinction_history = Vector{Tuple{Float64, T}}()) where T

    f(x) = extinction_threshold_affect(fwm, extinction_threshold, x, extinction_history)

    return DiscreteCallback(extinction_threshold_condition, f)
end
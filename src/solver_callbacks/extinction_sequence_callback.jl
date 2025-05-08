mutable struct ExtinctionSequenceCallbackAffect{T}

    foodwebmodel::FoodwebModel{T}
    extinction_sequence::Vector{T}
    cursor::Int64
    
    extinction_times::Vector{Float64} 
    extinctions::Vector{Tuple{Float64, T}}
    
    function ExtinctionSequenceCallbackAffect(
        fwm::FoodwebModel{T}, 
        extinction_sequence::Vector{T},
        extinction_times::Vector{Float64},
        extinctions::Vector{Tuple{Float64, T}}) where T

        @assert extinction_sequence ⊆ species(fwm)

        new{T}(fwm, extinction_sequence, 1, extinction_times, extinctions)
    end
end

# affect! function
function (escb::ExtinctionSequenceCallbackAffect)(integrator)

    s = length(escb.extinction_sequence) 

    while escb.cursor ≤ s

        target = escb.extinction_sequence[escb.cursor]

        # Skip to the next species in the sequence if spp is already extinct.
        if integrator[target] == 0.0
 
            escb.cursor += 1
            continue
        else

            integrator[target] = 0.0

            u_modified!(integrator, true)

            push!(escb.extinctions, (integrator.t, target))

            escb.cursor += 1
            break
        end
    end

    return
end

function extinction_condition(es, u, t, integrator)

    return t ∈ es.extinction_times
end

function ExtinctionSequenceCallback(
    fwm::FoodwebModel{T}, 
    extinction_sequence::Vector{T},
    extinction_times::Vector{Float64};
    extinction_history = Vector{Tuple{Float64, T}}()
    ) where T

    es = ExtinctionSequenceCallbackAffect(
        fwm, extinction_sequence, extinction_times, extinction_history
    )
    c(u, t, integrator) = extinction_condition(es, u, t, integrator)
    
    return DiscreteCallback(c, es)
end
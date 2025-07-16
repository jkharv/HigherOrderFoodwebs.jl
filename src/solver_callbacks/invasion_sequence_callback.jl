mutable struct InvasionSequenceCallbackAffect{T}

    foodwebmodel::FoodwebModel{T}
    invasion_sequence::Vector{T}
    cursor::Int64
    
    invasion_times::Vector{Int64} 
    invasions::Vector{Tuple{Float64, T}}
    invader_density::Float64
    
    function InvasionSequenceCallbackAffect(
        fwm::FoodwebModel{T}, 
        invasion_sequence::Vector{T},
        invasion_times::Vector{Int64},
        invasions::Vector{Tuple{Float64, T}},
        invader_density::Float64 
        ) where T

        @assert invasion_sequence ⊆ species(fwm)

        new{T}(fwm, invasion_sequence, 1, invasion_times, invasions, invader_density)
    end
end

# affect! function
function (iscb::InvasionSequenceCallbackAffect)(integrator)

    s = length(iscb.invasion_sequence) 

    while iscb.cursor ≤ s

        invader = iscb.invasion_sequence[iscb.cursor]

        # Skip to the next species in the sequence if spp is already present.
        if integrator[invader] > 0.0
 
            iscb.cursor += 1
            continue
        else

            integrator[invader] = iscb.invader_density 
            u_modified!(integrator, true)
            push!(iscb.invasions, (integrator.t, invader))
            iscb.cursor += 1 
        end
    end

    return
end

function invasion_condition(is, u, t, integrator)

    return t ∈ is.invasion_times
end

function InvasionSequenceCallback(
    fwm::FoodwebModel{T}, 
    invasion_sequence::Vector{T},
    invasion_times::Vector{Int64};
    invader_density::Float64 = 0.1,
    invasion_history = Vector{Tuple{Float64, T}}()
    ) where T

    is = InvasionSequenceCallbackAffect(
        fwm, invasion_sequence, invasion_times, invasion_history, invader_density
    )
    c(u, t, integrator) = invasion_condition(is, u, t, integrator)
    
    return DiscreteCallback(c, is)
end
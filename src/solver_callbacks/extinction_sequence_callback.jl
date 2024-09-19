const EXTINCTION_THRESHOLD = 1E-20
const STABILITY_THRESHOLD = 1E-4

mutable struct ExtinctionSequenceCallbackAffect{T}

    foodwebmodel::FoodwebModel{T}
    extinction_sequence::Vector{T}
    cursor::Int64
    t_elapsed::Float64 # Elapsed since last extinction
    t_limit::Float64   # Time limit before we force an extinction
    extinctions::Vector{Tuple{Float64, T}}
    
    function ExtinctionSequenceCallbackAffect(
        fwm::FoodwebModel{T}, 
        extinction_sequence::Vector{T},
        t_limit::Float64,
        extinctions::Vector{Tuple{Float64, T}}) where T

        @assert extinction_sequence ⊆ species(fwm)

        new{T}(fwm, extinction_sequence, 1, 0, t_limit, extinctions)
    end
end

# affect! function
function (escb::ExtinctionSequenceCallbackAffect)(integrator)

    s = length(escb.extinction_sequence) 

    # This should be in the same order as the indexing 
    # in integrator.u. 
    spp = (collect ∘ keys)(escb.foodwebmodel.vars)
    
    while escb.cursor ≤ s

        target = escb.extinction_sequence[escb.cursor]

        index = variable_index(integrator, target)

        # Skip to the next species in the sequence if spp is already extinct.
        if integrator.u[index] ≤ EXTINCTION_THRESHOLD
 
            escb.cursor += 1
            continue

        else

            integrator.u[index] = 0

            push!(escb.extinctions, (integrator.t, target))

            escb.cursor += 1
            escb.t_elapsed = 0
            break
        end

    end
end

function extinction_condition(es, u,t,integrator)

    s = size(integrator.u)[1]
    du = get_du(integrator)
   
    # Species alive and stable are fluctuating by less than 1% 
    # of their standing stock.
    prop_du = du ./ u
    stable = map(x -> abs(x) < STABILITY_THRESHOLD, prop_du)
 
    # Extinct species have a standing stock of less than EXTINCTION_THRESHOLD
    extinct = map(x -> x < EXTINCTION_THRESHOLD, u)
    
    n = sum(stable .| extinct)

    es.t_elapsed += (t - integrator.tprev)

    # All the species are varying by less then 1% of their standing stock.
    # Or, it's time to force an extinction.
    return ((n == s) | (es.t_elapsed > es.t_limit)) & (es.t_elapsed > es.t_limit/2)
end

function ExtinctionSequenceCallback(
    fwm::FoodwebModel{T}, 
    extinction_sequence::Vector{T},
    time_limit::Float64;
    extinction_history = Vector{Tuple{Float64, T}}()
    ) where T

    es = ExtinctionSequenceCallbackAffect(
        fwm, extinction_sequence, time_limit, extinction_history)
    c(u, t, integrator) = extinction_condition(es, u, t, integrator)
    
    return DiscreteCallback(c, es)
end
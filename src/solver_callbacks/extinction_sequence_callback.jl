mutable struct ExtinctionSequenceCallbackAffect{T}

    foodwebmodel::FoodwebModel{T}
    extinction_sequence::Vector{T}
    cursor::Int64
   
    # Use of a persistent cursor is questionable cause if I do simulations with
    # invasions and extinctions, then re-extinctions of species that were made
    # extinct in the past would not play nicely with the "only once" extinction
    # model enforced by this. Maybe cursor should be modulo
    # length(extinction_sequence).

    extinction_times::Vector{Float64} 
    n_extinctions::Int64
    extinctions::Vector{Tuple{Float64, Vector{T}}}
    
    function ExtinctionSequenceCallbackAffect(
        fwm::FoodwebModel{T}, 
        extinction_sequence::Vector{T},
        extinction_times::Vector{Float64},
        n_extinctions::Int64,
        extinctions::Vector{Tuple{Float64, Vector{T}}}
    ) where T

        @assert extinction_sequence ⊆ species(fwm)
       
        new{T}(
            fwm, extinction_sequence, 1, 
            extinction_times, n_extinctions, extinctions
        )
    end
end

# affect! function
function (escb::ExtinctionSequenceCallbackAffect{T})(integrator) where T

    s = length(escb.extinction_sequence) 
    target_species = Vector{T}();

    while (escb.cursor ≤ s) & (length(target_species) < escb.n_extinctions)

        prospective_target = escb.extinction_sequence[escb.cursor]

        # Skip to the next species in the sequence if spp is already extinct.
        if integrator[prospective_target] == 0.0
 
            escb.cursor += 1
            continue
        else

            push!(target_species, prospective_target)
            escb.cursor += 1
        end
    end

    if isempty(target_species)

        return
    end

    # TODO: integrator[] = 0 should use zero(eltype(integrator)) instead to be
    # more generic. I need to check the fields of integrator and implement this
    # later.

    for t in target_species

        integrator[t] = 0.0
    end

    u_modified!(integrator, true)

    push!(escb.extinctions, (integrator.t, (target_species)))

    return
end

function extinction_condition(es, u, t, integrator)

    return t ∈ es.extinction_times
end

"""
    ExtinctionSequenceCallback(
    fwm::FoodwebModel{T},
    extinction_sequence::Vector{T},
    extinction_times::Vector{Float64};
    n_extinction = 1,
    extinction_history = Vector{Tuple{Float64, T}}()
    ) where T

Solver callback that makes species periodically go extinct. Everytime the
callback is run it selects the next `n_extinctions` number of species from
`extinction_sequence` (that have positive biomass) and sets them to zero.

You should also pass the extinction times to the solver through `tstops`. If
the solver doesn't stop precisely at an extinction time, the extinction will not
occur.
## Keyword variables

`extinction_history` : Accepts an optional `Vector{Tuple{Float64, T}}` in which
    it will save the time and target of all the extinctions inflicted by this
    callback.

`n_extinctions` : The number of extinctions from `extinction_sequence` that
    should be inflicted each time the callback is run.
"""
function ExtinctionSequenceCallback(
    fwm::FoodwebModel{T},
    extinction_sequence::Vector{T},
    extinction_times::Vector{Float64};
    n_extinctions = 1,
    extinction_history = Vector{Tuple{Float64, Vector{T}}}()
    ) where T

    @assert n_extinctions <= length(extinction_sequence)

    es = ExtinctionSequenceCallbackAffect(fwm,
        extinction_sequence,
        extinction_times,
        n_extinctions,
        extinction_history
    )
    c(u, t, integrator) = extinction_condition(es, u, t, integrator)

    return DiscreteCallback(c, es)
end


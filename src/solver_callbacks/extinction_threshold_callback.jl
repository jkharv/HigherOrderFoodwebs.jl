mutable struct ExtinctionThresholdAffect{T}

    fwm::FoodwebModel{T}
    extinctions::Vector{Tuple{Float64, T}}
    invasions::Vector{Tuple{Float64, T}}
    id_dict::Dict{Union{T, Int64}, Union{T, Int64}}

    function ExtinctionThresholdAffect(
        fwm::FoodwebModel{T}; 
        extinctions = Vector{Tuple{Float64, T}}(),
        invasions = Vector{Tuple{Float64, T}}()
    ) where T

        new{T}(fwm, extinctions, invasions, Dict{Union{T, Int64}, Union{T, Int64}}())
    end
end

function condition!(out, u, t, integrator, threshold)

    for i ∈ eachindex(out)

        out[i] = u[i] - threshold
    end

end

function (etca::ExtinctionThresholdAffect)(
    integrator, 
    event_index, 
    isextinction, # Is this a downcrossing
    invasions_allowed # Controls what happens with upcrossings
    # Are invasions allowed? Or are they set to zero?
    )

    if isextinction

        push!(etca.extinctions, (integrator.t, etca.id_dict[event_index]))
        integrator.u[event_index] = 0.0
        return
    end 
    
    if invasions_allowed
        
        push!(etca.invasions, (integrator.t, etca.id_dict[event_index]))
        return
    else

        integrator.u[event_index] = 0.0
        return
    end
end

# Initialize the callback by setting the components of the model that actually
# represent a species, and as such should be potentially subject to extinction.
function initialize_cb!(c, u, t, integrator, spp, etca)

    idxs = variable_index.(Ref(integrator), spp)
    append!(c.idxs, idxs)    

    # Initialize the id dict in etca.
    for (i, sp) ∈ tuple.(idxs, spp)

        etca.id_dict[i] = sp
        etca.id_dict[sp] = i
    end

    return
end

function ExtinctionThresholdCallback(
    fwm::FoodwebModel{T}, 
    threshold = 10E-20;
    extinction_history = Vector{Tuple{Float64, T}}(),
    invasion_history = Vector{Tuple{Float64, T}}()
    ) where T

    etca = ExtinctionThresholdAffect(
        fwm;
        extinctions = extinction_history,
        invasions = invasion_history
    )

    return VectorContinuousCallback(
        (w, x, y, z) -> condition!(w, x, y, z, threshold),
        (x, y) -> etca(x, y, false, false), # affect!
        (x, y) -> etca(x, y, true, false),  # affect_neg!
        richness(fwm);
        initialize = (w, x, y, z) -> initialize_cb!(w, x, y, z, species(fwm), etca),
        idxs = []
    )
end
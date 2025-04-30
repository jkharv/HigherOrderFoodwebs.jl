mutable struct ExtinctionThresholdAffect{T}

    fwm::FoodwebModel{T}
    extinctions::Vector{Tuple{Float64, T}}
    invasions::Vector{Tuple{Float64, T}}

    function ExtinctionThresholdAffect(
        fwm::FoodwebModel{T}; 
        extinctions = Vector{Tuple{Float64, T}}(),
        invasions = Vector{Tuple{Float64, T}}()
    ) where T

        new{T}(fwm, extinctions, invasions)
    end
end

function condition!(out, u, t, integrator, threshold)

    for i ∈ eachindex(out)

        out[i] = u[i] - threshold
    end

end

function (etca::ExtinctionThresholdAffect)(
    integrator, 
    index, 
    isextinction, # Is this a downcrossing
    invasions_allowed # Controls what happens with upcrossings
    # Are invasions allowed? Or are they set to zero?
    )

    # The code from DifferentialEquationsCallbacks.jl doesn't seem to support
    # symbolic indexing in callback definitions. So we have to convert from the
    # indices it gives us back to the species symbol.
    fwm = integrator.f.sys
    sp = get_symbol(fwm.vars, index)

    if isextinction

        push!(etca.extinctions, (integrator.t, sp))
        integrator[sp] = 0.0
        return
    end 
    
    if invasions_allowed
        
        push!(etca.invasions, (integrator.t, sp))
        return
    else

        integrator[sp] = 0.0
        return
    end
end

# Initialize the callback by setting the components of the model that actually
# represent a species, and as such should be potentially subject to extinction.
function initialize_cb!(c, u, t, integrator, spp, etca)

    # This aspect of the callbacks seem to not allows symbolic indexing.
    # So we have to get integer indices here. We also have to deal with
    # recieving integer indices in the affect! code.
    fwm = integrator.sol.prob.f.sys
    idxs = get_index.(Ref(fwm.vars), spp)

    append!(c.idxs, idxs)    

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
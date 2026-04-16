mutable struct ExtinctionThresholdAffect{T}

    fwm::FoodwebModel{T}
    extinctions::Vector{Tuple{Float64, Vector{T}}}
    invasions::Vector{Tuple{Float64, Vector{T}}}

    # The way VectorContinuousCallback works shouldn't ever allow for two
    # species to go extinct at *exactly* the same time, so the `Vector{T}` is
    # technically not needed here. Although, I feel that not using the
    # `Vector{T}` would be an easily overlooked API difference between this and 
    # `ExtinctionSequenceCallback` that would trip people up.

    function ExtinctionThresholdAffect{T}(
        fwm::FoodwebModel{T}; 
        extinctions = Vector{Tuple{Float64, Vector{T}}}(),
        invasions = Vector{Tuple{Float64, Vector{T}}}()
    ) where T

        new{T}(fwm, extinctions, invasions)
    end
end

function condition!(out, u, t, integrator, threshold)

    for i ∈ eachindex(out)

        out[i] = u[i] - threshold
    end

end

function (etca::ExtinctionThresholdAffect{T})(
    integrator, 
    index, 
    isextinction, # Is this a downcrossing
    invasions_allowed # Controls what happens with upcrossings
    # Are invasions allowed? Or are they set to zero?
    ) where T

    # The code from DifferentialEquationsCallbacks.jl doesn't seem to support
    # symbolic indexing in callback definitions. So we have to convert from the
    # indices it gives us back to the species symbol.
    fwm = integrator.f.sys
    sp = get_symbol(fwm.vars, index)

    if isextinction

        push!(etca.extinctions, (integrator.t, [sp]))
        integrator[sp] = 0.0
        u_modified!(integrator, true)
        return
    end 
    
    if invasions_allowed
        
        push!(etca.invasions, (integrator.t, [sp]))
        return
    else

        integrator[sp] = 0.0
        u_modified!(integrator, true)
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

"""
    ExtinctionThresholdCallback(
        fwm::FoodwebModel{T}, 
        threshold = 1E-10;
        extinction_history = Vector{Tuple{Float64, Vector{T}}}(),
        invasion_history = Vector{Tuple{Float64, Vector{T}}}()
    ) where T

    Forces any species that fall below the threshold to zero.  When a species is
    set to zero, it's recorded in the vector passed to `extinction_history` 
"""
function ExtinctionThresholdCallback(
    fwm::FoodwebModel{T}, 
    threshold = 1E-10;
    extinction_history = Vector{Tuple{Float64, Vector{T}}}(),
    invasion_history = Vector{Tuple{Float64, Vector{T}}}()
    ) where T

    etca = ExtinctionThresholdAffect{T}(
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
        idxs = [],
        save_positions = (true, true),
        abstol = threshold * 1e-1, # set the tolerance to be lower than the threshold.
        reltol = 0.0
    )
end
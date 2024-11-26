SpeciesInteractionNetworks.species(fwm::FoodwebModel) = species(fwm.hg)
SpeciesInteractionNetworks.richness(fwm::FoodwebModel) = richness(fwm.hg) 
SpeciesInteractionNetworks.interactions(fwm::FoodwebModel) = interactions(fwm.hg) 

function set_u0!(fwm::FoodwebModel{T}, k::Union{T, Num}, val::Float64) where T
 
    fwm.u0[k] = val 
end

function set_u0!(fwm::FoodwebModel{T}, u0::Dict{T, Float64}) where T

    for (k, v) ∈ u0

        set_u0!(fwm, k, v)
    end
end

function set_u0!(fwm::FoodwebModel, u0::Dict{Num, Float64})

    for (k, v) ∈ u0

        set_u0!(fwm, k, v)
    end
end

function isproducer(fwm::FoodwebModel, sp)::Bool

    @assert sp ∈ species(fwm)

    for intx ∈ interactions(fwm)

        if isloop(intx)

            continue
        elseif subject(intx) == sp

            return false
        end
    end

    return true
end

function isconsumer(fwm::FoodwebModel, sp)::Bool

    return !isproducer(fwm, sp)
end
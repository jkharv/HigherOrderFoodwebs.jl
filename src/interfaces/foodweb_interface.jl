AnnotatedHypergraphs.species(fwm::FoodwebModel) = species(fwm.hg)
AnnotatedHypergraphs.richness(fwm::FoodwebModel) = richness(fwm.hg) 

AnnotatedHypergraphs.interactions(fwm::FoodwebModel) = interactions(fwm.hg) 

function set_initial_condition!(fwm::FoodwebModel{T}, u0::Dict{T, Float64}) where T

    for k ∈ keys(u0)

        b = fwm.vars[k]
        fwm.u0[b] = u0[k]
    end
end
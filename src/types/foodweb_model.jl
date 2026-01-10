"""
    FoodwebModel{T}

Centerpiece of `HigherOrderFoodwebs` brings together all the components of a
foodweb model into a single struct.
"""
mutable struct FoodwebModel{T}

    """
    `AnnotatedHypergraph` representing trophic/non-trophic relationship between
    species in the foodweb.
    """
    hg::AnnotatedHypergraph{T}

    """
    Stores the `DynamicRule` associated with each `AnnotatedHyperedge`.
    """
    dynamic_rules::Dict{AnnotatedHyperedge, DynamicRule}
    """
    `DynamicRules` representing variables that don't appear in the
    `AnnotatedHypergraph` such as `TRAIT_VARIABLE`s and `ENVIRONMENT_VARIABLE`s.
    """
    aux_dynamic_rules::Dict{T, DynamicRule}
   
    """
    The model's variables.
    """
    vars::FoodwebVariables{T}    
    """
    The model's parameters.
    """
    params::FoodwebVariables{T}
end

function FoodwebModel(
    hg::AnnotatedHypergraph{T};
    add_self_interactions = true) where T

    hg = deepcopy(hg)

    if add_self_interactions

        for sp ∈ species(hg)

            # Check if the loop is already there
            z = findfirst(x -> isloop(x) & has_role(sp, x, :subject) , interactions(hg))

            # create the loop if it's not there already
            if isnothing(z)

                new_int = AnnotatedHyperedge([sp, sp], [:subject, :object])
                push!(hg.edges, new_int)
            end
        end
    end
    
    return FoodwebModel{T}(
        hg,
        Dict{AnnotatedHyperedge, DynamicRule}(), # dynamic_rules
        Dict{T, DynamicRule}(), # aux_dynamic_rules
        FoodwebVariables(species(hg)), # vars
        FoodwebVariables{T}(), # params 
    )
end
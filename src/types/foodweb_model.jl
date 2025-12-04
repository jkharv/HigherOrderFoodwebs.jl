mutable struct FoodwebModel{T}

    hg::AnnotatedHypergraph{T}

    dynamic_rules::Dict{AnnotatedHyperedge, DynamicRule}
    aux_dynamic_rules::Dict{T, DynamicRule}
   
    vars::FoodwebVariables{T}    
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
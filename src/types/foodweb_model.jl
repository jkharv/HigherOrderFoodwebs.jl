const time = Symbolics.variable(:t; T = Real)

mutable struct FoodwebModel{T}

    hg::SpeciesInteractionNetwork{<:Partiteness, <:AnnotatedHyperedge}

    dynamic_rules::Dict{AnnotatedHyperedge, DynamicRule}
    aux_dynamic_rules::Dict{Num, DynamicRule}
   
    vars::FoodwebVariables{T}    
    params::FoodwebVariables{T}
end

function FoodwebModel(
    hg::SpeciesInteractionNetwork{<:Partiteness{T}, <:AnnotatedHyperedge{T}};
    add_self_interactions = true) where T

    hg = deepcopy(hg)

    if add_self_interactions

        for sp ∈ species(hg)

            # Check if the loop is already there
            z = findfirst(x -> isloop(x) & has_role(sp, :subject, x) , interactions(hg))

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
        Dict{Num, DynamicRule}(), # aux_dynamic_rules
        FoodwebVariables(species(hg)), # vars
        FoodwebVariables{T}(), # params 
    )
end
struct DynamicRule

    forwards_function::Num
    backwards_function::Num
    vars::Vector{Num}
    params::Vector{Num}
end

function DynamicRule(forwards_rule::Num, backwards_rule::Num)

    both = union(get_variables(forwards_rule), get_variables(backwards_rule))

    vars = filter(!ModelingToolkit.isparameter, both)
    params = filter(ModelingToolkit.isparameter, both)

    return DynamicRule(
        forwards_rule,
        backwards_rule,
        vars,
        params
    )
end

DynamicRule(rule::Num) = DynamicRule(rule, rule)

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

function set_dynamical_rule!(fw::FoodwebModel, he::AnnotatedHyperedge, dr::DynamicRule)

    # Add the rule
    fw.dynamic_rules[he] = dr

    # TODO This should do some checks
end

function get_symbol(fwm::FoodwebModel, x::Num)

    return get_symbol(fwm.vars, x)
end

function get_variable(fwm::FoodwebModel, x::Symbol)

    return get_variable(fwm.vars, x)
end
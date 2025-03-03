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

# Hopefully we get to this at some point.
struct SpatialFoodwebModel

end

mutable struct FoodwebModel{T}

    hg::SpeciesInteractionNetwork{<:Partiteness, <:AnnotatedHyperedge}

    t::Num
    dynamic_rules::Dict{AnnotatedHyperedge, DynamicRule}
    aux_dynamic_rules::Dict{Num, DynamicRule}
   
    vars::FoodwebVariables{T}    

    params::Vector{Num}
    param_vals::Dict{Num, Number}
    u0::Dict{Num, Number}
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
    
    rules = Dict{AnnotatedHyperedge, DynamicRule}()
    aux_rules = Dict{Num, DynamicRule}()

    vars = FoodwebVariables(species(hg))

    u0 = Dict{Num, Number}()
    param_vals = Dict{Num, Number}()
    params = Vector{Num}()

    return FoodwebModel{T}(
        hg,
        ModelingToolkit.t_nounits,
        rules,
        aux_rules,
        vars,
        params,
        param_vals,
        u0
    )
end

function set_dynamical_rule!(fw::FoodwebModel, he::AnnotatedHyperedge, dr::DynamicRule)

    # Add the rule
    fw.dynamic_rules[he] = dr

    # TODO This should do some checks
end

function var_to_sym(fwm::FoodwebModel, v::Num)

    return var_to_sym(fwm.vars, v)
end

function sym_to_var(fwm::FoodwebModel, s::Symbol)

    return sym_to_var(fwm.vars, s)
end
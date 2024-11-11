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

struct SpatialFoodwebModel

end

struct FoodwebModel{T}

    hg::SpeciesInteractionNetwork{<:Partiteness, <:AnnotatedHyperedge, <:Any}
    dynamic_rules::Dict{AnnotatedHyperedge, DynamicRule}

    t::Num

    vars::Dict{T, Num}
    u0::Dict{Num, Number}

    params::Vector{Num}
    param_vals::Dict{Num, Number}

    aux_dynamic_rules::Dict{Symbol, DynamicRule}
    aux_vars::Dict{Symbol, Num}

    odes::Union{ODEProblem, Missing}
    community_matrix::Union{CommunityMatrix, Missing}
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
    u0 = Dict{Num, Number}()
    param_vals = Dict{Num, Number}()
    params = Vector{Num}()

    t = @independent_variables t
    t = t[1]
    spp = species(hg)
    nums = create_var.(spp, Ref(t))
    vars = Dict(spp .=> nums)

    return FoodwebModel{T}(
        hg, 
        rules, 
        t, 
        vars, 
        u0, 
        params, 
        param_vals, 
        Dict{Symbol, DynamicRule}(),
        Dict{Symbol, Num}(),
        missing, 
        missing
    )
end

function set_dynamical_rule!(fw::FoodwebModel, he::AnnotatedHyperedge, dr::DynamicRule)

    # Add the rule
    fw.dynamic_rules[he] = dr

    # TODO This should do some checks
end
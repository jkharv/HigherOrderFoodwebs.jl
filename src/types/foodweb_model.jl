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

    hg::SpeciesInteractionNetwork{<:Partiteness, <:AnnotatedHyperedge, <:Any}

    t::Num
    dynamic_rules::Dict{AnnotatedHyperedge, DynamicRule}
    aux_dynamic_rules::Dict{Num, DynamicRule}
    
    params::Vector{Num}
    vars::Vector{Num}
    aux_vars::Vector{Num}
   
    # Used to convert between type T references to species and Nums from Symbolics.jl
    conversion_dict::Dict{Union{T, Num}, Union{T, Num}}    

    param_vals::Dict{Num, Number}
    u0::Dict{Num, Number}

    odes::Union{ODEProblem, Nothing}
    community_matrix::Union{CommunityMatrix, Nothing}
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
    vars = Vector{Num}()
    conversion_dict = Dict{Union{Num, T}, Union{Num, T}}()

    for sp ∈ spp
    
        v = create_var(sp, t)
        push!(vars, v)

        conversion_dict[sp] = v
        conversion_dict[v] = sp
    end

    return FoodwebModel{T}(
        hg, 
        t, 
        rules, 
        Dict{Num, DynamicRule}(), # aux_dynamic_rules
        params,
        vars, 
        Vector{Num}(), # aux_vars
        conversion_dict, 
        param_vals, 
        u0, 
        nothing, 
        nothing
    )
end

function set_dynamical_rule!(fw::FoodwebModel, he::AnnotatedHyperedge, dr::DynamicRule)

    # Add the rule
    fw.dynamic_rules[he] = dr

    # TODO This should do some checks
end
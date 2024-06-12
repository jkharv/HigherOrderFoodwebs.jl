struct DynamicalRule

    forwards_function::Num
    backwards_function::Num
    vars::Vector{Num}
    params::Vector{Num}
end

struct SpatialFoodwebModel

end

struct FoodwebModel{T}

    hg::SpeciesInteractionNetwork{<: Partiteness, <: AnnotatedHyperedge{T, Bool}}
    dynamic_rules::Dict{AnnotatedHyperedge{<:Any, Bool}, DynamicalRule}

    t::Num

    vars::Dict{T, Num}
    u0::Dict{Num, Number}

    params::Vector{Num}
    param_vals::Dict{Num, Number}

    odes::Union{ODEProblem, Missing}
    community_matrix::Union{CommunityMatrix, Missing}
end

function FoodwebModel(
    hg::SpeciesInteractionNetwork{<: Partiteness{T}, <: AnnotatedHyperedge{T, Bool}};
    add_self_interactions = true) where T

    hg = deepcopy(hg)

    if add_self_interactions

        for sp ∈ species(hg)

            # Check if the loop is already there
            z = findfirst(x -> isloop(x) & has_role(sp, :subject, x) , interactions(hg))

            # create the loop if it's not there already
            if isnothing(z)

                new_int = AnnotatedHyperedge([sp, sp], [:subject, :object], true)
                push!(hg.interactions, new_int)
            end
        end
    end
    
    rules = Dict{AnnotatedHyperedge{T, Bool}, DynamicalRule}()
    u0 = Dict{Num, Number}()
    param_vals = Dict{Num, Number}()
    params = Vector{Num}()

    t = create_variable(:t)
    spp = AnnotatedHypergraphs.species(hg)
    nums = create_variable.(spp, Ref(t))
    vars = Dict(spp .=> nums)

    return FoodwebModel{T}(hg, rules, t, vars, u0, params, param_vals, missing, missing)
end

function set_dynamical_rule!(fw::FoodwebModel, he::AnnotatedHyperedge, dr::DynamicalRule)

    # Add the rule
    fw.dynamic_rules[he] = dr

    # TODO This should do some checks
end
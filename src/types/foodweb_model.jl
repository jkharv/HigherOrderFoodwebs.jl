struct DynamicalRule

    forwards_function::Num
    backwards_function::Num
    vars::Vector{Num}
    params::Vector{Num}
end

struct SpatialFoodwebModel

end

struct FoodwebModel

    hg::SpeciesInteractionNetwork{<: Partiteness, <: AnnotatedHyperedge{<:Any, Bool}}
    dynamic_rules::Dict{AnnotatedHyperedge{<:Any, Bool}, DynamicalRule}

    t::Num

    vars::Dict{<:Any, Num}
    u0::Dict{Num, Number}

    params::Vector{Num}
    param_vals::Dict{Num, Number}

    function FoodwebModel(
        hg::SpeciesInteractionNetwork{<: Partiteness{T}, 
                                      <: AnnotatedHyperedge{T, Bool}}
        ) where T <: Any

        rules = Dict{AnnotatedHyperedge{T, Bool}, DynamicalRule}()
        u0 = Dict{Num, Number}()
        param_vals = Dict{Num, Number}()
        params = Vector{Num}()

        t = create_variable(:t)
        spp = AnnotatedHypergraphs.species(hg)
        nums = create_variable.(spp, Ref(t))
        vars = Dict(spp .=> nums)

        new(hg, rules, t, vars, u0, params, param_vals)
    end
end

function set_dynamical_rule!(fw::FoodwebModel, he::AnnotatedHyperedge, dr::DynamicalRule)

    # Add the rule
    fw.dynamic_rules[he] = dr

    # TODO This should do some checks
end
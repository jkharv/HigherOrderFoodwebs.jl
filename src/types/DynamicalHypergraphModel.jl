struct DynamicalRule

    forwards_function::Num
    backwards_function::Num
    vars::Vector{Num}
    params::Vector{Num}
end

struct DynamicalHypergraphModel

    hg::SpeciesInteractionNetwork{<:Partiteness, AnnotatedHyperedge}
    dynamics_rules::Dict{AnnotatedHyperedge, DynamicalRule}
    vars::Dict{Num, <:Number}
    params::Dict{Num, <:Number}
end

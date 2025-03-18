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
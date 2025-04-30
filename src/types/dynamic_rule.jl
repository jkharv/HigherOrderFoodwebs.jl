struct DynamicRule

    forwards_function::Num
    backwards_function::Num
    vars::Vector{Num}
end

function DynamicRule(forwards_rule::Num, backwards_rule::Num)

    both = union(
        Symbolics.get_variables(forwards_rule), 
        Symbolics.get_variables(backwards_rule)
    )

    return DynamicRule(
        forwards_rule,
        backwards_rule,
        both
    )
end

DynamicRule(rule::Num) = DynamicRule(rule, rule)
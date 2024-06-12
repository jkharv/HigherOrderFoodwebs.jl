function combine_expressions(op::Symbol, x::T, y::T)::T where T <: FunctionTemplate

    x = apply_template(x)
    y = apply_template(y)

    ff = Expr(:call, op, unblock(x.forwards_function), unblock(y.forwards_function))
    bf = Expr(:call, op, unblock(x.backwards_function), unblock(y.backwards_function))
    spp = (unique ∘ vcat)(x.canonical_vars, y.canonical_vars)
    objects = merge(x.objects, y.objects)

    return FunctionTemplate(ff, bf, spp, objects)
end

Base.:+(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:+, x, y)
Base.:-(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:-, x, y)
Base.:*(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:*, x, y)
Base.:/(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:/, x, y)
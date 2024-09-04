function combine_expressions(op::Symbol, x::T, y::T)::T where T <: FunctionTemplate

    x = apply_template(x)
    y = apply_template(y)

    ff = Expr(:call, op, unblock(x.forwards_function), unblock(y.forwards_function))
    bf = Expr(:call, op, unblock(x.backwards_function), unblock(y.backwards_function))
    spp = (unique ∘ vcat)(x.canonical_vars, y.canonical_vars)
    objects = vcat(x.objects, y.objects)

    return FunctionTemplate(ff, bf, spp, objects)
end

function sum_expr(ex1, ex2)

    return Expr(:call, +, unblock(ex1), unblock(ex2))
end

function sum_expr(ex)

    return ex
end

function sum_expr(exs...)

    return Expr(:call, + unblock(exs[1]), sum_expr(exs[2:end]))
end


Base.:+(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:+, x, y)
Base.:-(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:-, x, y)
Base.:*(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:*, x, y)
Base.:/(x::FunctionTemplate, y::FunctionTemplate) = combine_expressions(:/, x, y)
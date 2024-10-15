function holling2(object, alternate, b0)

    return object / (b0 + alternate)
end

@register_symbolic holling2(object, alternate, b0)

function Symbolics.derivative(::typeof(holling2), args::NTuple{3, Any}, ::Val{1})

    o, a, b = args
    return 1 / (b + a)
end

function Symbolics.derivative(::typeof(holling2), args::NTuple{3, Any}, ::Val{2})

    o, a, b = args
    return -(o / (a + b)^2)
end

function Symbolics.derivative(::typeof(holling2), args::NTuple{3, Any}, ::Val{3})

    o, a, b = args
    return -(o / (a + b)^2)
end
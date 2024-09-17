function logistic(x::Number, r::Number, k::Number)::Number

    return x * r * (1.0 - x/k)
end

@register_symbolic logistic(x, r, k)

function Symbolics.derivative(::typeof(logistic), args::NTuple{3, Any}, ::Val{1})

    x, r, k = args
    return ((-r * x) / k) + r * (1.0-(x/k))
end

function Symbolics.derivative(::typeof(logistic), args::NTuple{3, Any}, ::Val{2})

    x, r, k = args
    return x * (1.0 - x/k)
end

function Symbolics.derivative(::typeof(logistic), args::NTuple{3, Any}, ::Val{3})

    x, r, k = args
    return -r * x * ( -x / k^2.0)
end
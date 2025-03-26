function holling_disk(b0, object, alternate)

    return object / (b0 + alternate)
end

@register_symbolic holling_disk(b0, object, alternate)

# ∂ b0
function Symbolics.derivative(::typeof(holling_disk), args::NTuple{3, Any}, ::Val{1})

    b0, object, alternate = args
    
    return -object / (b0 + alternate)^2
end

# ∂ object
function Symbolics.derivative(::typeof(holling_disk), args::NTuple{3, Any}, ::Val{2})

    b0, object, alternate = args
    
    return 1.0 / (b0 + alternate)
end

# ∂ alternate
function Symbolics.derivative(::typeof(holling_disk), args::NTuple{3, Any}, ::Val{3})

    b0, object, alternate = args
    
    return -object / (b0 + alternate)^2
end
function create_var(dep::Symbol, indep::Num)

    x = @variables $dep(indep)

    return x[1]
end

function create_var(sym::Symbol)

    x = @variables $sym

    return x[1]
end

function create_param(sym::Symbol)

    x = @variables $sym
    param =  ModelingToolkit.toparam(x[1])

    return param
end

# Functions to add these vars and params to the FWM object.

function variables(fwm::FoodwebModel; type::Union{VariableType, Missing} = missing)

    return variables(fwm.vars; type = type)
end

function add_var!(fwm::FoodwebModel, v::Symbol, type::VariableType)

    return add_var!(fwm.vars, v, type)
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, spp::Vector{T}, val::Number) where T

    unambiguous_sym = (Symbol ∘ join)([sym, spp...], "_")
    p = create_param(unambiguous_sym)

    push!(fwm.params, p)   
    push!(fwm.param_vals, p => val)

    return p
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, spp::T, val::Number) where T

    return add_param!(fwm, sym, [spp], val)
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, val::Number) where T

    return add_param!(fwm, sym, Vector{T}(), val)
end
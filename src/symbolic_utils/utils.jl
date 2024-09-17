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

function add_var!(fwm::FoodwebModel, dep::Symbol, indep::Num)

    v = create_var(dep, indep)
    push!(fwm.aux_vars, dep => v)

    return v
end

# TODO It doesn't make sense to be adding more indep variables if I don't treat
# them differently from dep variables.  Don't actually use this function so long
# as I've not done anything to address this.
function add_var!(fwm::FoodwebModel, sym::Symbol)

    v = create_var(sym)
    push!(fwm.aux_vars, dep => v)

    return v
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
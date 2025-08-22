# This interface is used by SciML packages to allow non-integer indexing on the
# solution types. These are not exported for users of HigherOrderFoodwebs.jl

function SymbolicIndexingInterface.is_variable(
    fwm::FoodwebModel{T}, sym::T)::Bool where T

    for v in variables(fwm)

        if sym == v

            return true
        end
    end

    return false
end

function SymbolicIndexingInterface.variable_index(
    fwm::FoodwebModel{T}, sym::T)::Int64 where T

    return get_index(fwm.vars, sym)
end

function SymbolicIndexingInterface.variable_symbols(
    fwm::FoodwebModel{T})::T where T

    return variables(fwm.vars)
end

function SymbolicIndexingInterface.is_parameter(
    fwm::FoodwebModel{T}, sym::T)::Bool where T

    for v in variables(fwm.params)

        if sym == v

            return true
        end
    end

    return false   
end

function SymbolicIndexingInterface.parameter_index(
    fwm::FoodwebModel{T}, sym::T)::Int64 where T

    return get_index(fwm.params, sym)
end

function SymbolicIndexingInterface.parameter_symbols(
    fwm::FoodwebModel{T})::T where T
 
    return variables(fwm.params)
end

function SymbolicIndexingInterface.is_independent_variable(
    fwm::FoodwebModel{T}, sym::T)::T where T

    @warn "TODO: DO TIME VAR PROPERLY"

    return sym == :time
end

function SymbolicIndexingInterface.independent_variable_symbols(
    ::FoodwebModel{T})::T where T

    return :time
end

function SymbolicIndexingInterface.is_time_dependent(::FoodwebModel)

    return true
end

function SymbolicIndexingInterface.constant_structure(::FoodwebModel) 

    return true
end

function SymbolicIndexingInterface.all_variable_symbols(fwm::FoodwebModel)
 
    return variable_symbols(fwm)
end

function SymbolicIndexingInterface.all_symbols(fwm::FoodwebModel)

    return vcat(
        variable_symbols(fwm), 
        parameter_symbols(fwm),
        :time 
    )
end

function SymbolicIndexingInterface.default_values(fwm::FoodwebModel)

    vsyms = variable_symbols(fwm)
    psyms = parameter_symbols(fwm)

    vars = Dict(vsyms .=> get_value.(Ref(fwm.vars), vsyms))
    ps = Dict(psyms .=> get_value.(Ref(fwm.params), psyms))

    return merge(vars, ps)
end
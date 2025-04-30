# ------------------------------------------------------------- #
# Implementations for Num indexing on HigherOrderFoodwebs types #
# ------------------------------------------------------------- #

function SymbolicIndexingInterface.is_variable(fwm::FoodwebModel, sym::Num)

    for v in variables(fwm)

        if isequal(sym, v)

            return true
        end
    end

    return false
end

function SymbolicIndexingInterface.variable_index(fwm::FoodwebModel, sym::Num)

    return get_index(fwm.vars, sym)
end

function SymbolicIndexingInterface.variable_symbols(fwm::FoodwebModel)

    return variables(fwm.vars)
end

function SymbolicIndexingInterface.is_parameter(fwm::FoodwebModel, sym::Num)

    for v in variables(fwm.params)

        if isequal(sym, v)

            return true
        end
    end

    return false   
end

function SymbolicIndexingInterface.parameter_index(fwm::FoodwebModel, sym::Num)

    return get_index(fwm.params, sym)
end

function SymbolicIndexingInterface.parameter_symbols(fwm::FoodwebModel)
 
    return variables(fwm.params)
end

function SymbolicIndexingInterface.is_independent_variable(fwm::FoodwebModel, sym::Num)

    if isnothing(sym)
        return false
    end

    return sym == time
end

function SymbolicIndexingInterface.independent_variable_symbols(fwm::FoodwebModel)

    return time
end

function SymbolicIndexingInterface.is_time_dependent(fwm::FoodwebModel)

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
        time 
    )
end

function SymbolicIndexingInterface.default_values(fwm::FoodwebModel)

    vsyms = variable_symbols(fwm)
    psyms = parameter_symbols(fwm)

    vars = Dict(vsyms .=> get_value.(Ref(fwm.vars), vsyms))
    ps = Dict(psyms .=> get_value.(Ref(fwm.params), psyms))

    return merge(vars, ps)
end

# ------------------------------------------------------------------ #
# Implementations for Symbol/T indexing on HigherOrderFoodwebs types #
# ------------------------------------------------------------------ #

# Some of these function are unimplented for the case of Symbol/T indexing.
# This is because some of the function FoodwebModel as their only parameter,
# Deciding whether to return a Num or a Symbol/T is ambiguous in these cases.
# When it's ambiguous, we'll always return a Num; hence leaving the Symbol/T
# versions unimplented.

function SymbolicIndexingInterface.is_variable(fwm::FoodwebModel{T}, sym::T) where T

    for v in fwm.vars.syms

        if v == sym

            return true
        end
    end

    return false
end

function SymbolicIndexingInterface.variable_index(fwm::FoodwebModel{T}, sym::T) where T

    return get_index(fwm.vars, sym)
end

function SymbolicIndexingInterface.is_parameter(fwm::FoodwebModel{T}, sym::T) where T

    for v in fwm.params.syms

        if v == sym

            return true
        end
    end

    return false   
end

function SymbolicIndexingInterface.parameter_index(fwm::FoodwebModel{T}, sym::T) where T

    return get_index(fwm.params, sym)
end
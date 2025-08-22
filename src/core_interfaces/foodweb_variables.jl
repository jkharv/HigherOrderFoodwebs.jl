function add_var!(
    vs::FoodwebVariables, 
    v::Symbol, 
    type::VariableType, 
    val::Float64 = 0.0
    )

    push!(vs.type, type)
    push!(vs.syms, v)
    push!(vs.vals, val) 
    vs.idxs[v] = lastindex(vs.type)

    return v
end

function variables(v::FoodwebVariables; type::Union{VariableType, Missing} = missing)

    if ismissing(type)

        return v.syms
    end

    idxs = findall(x -> x == type, v.type)

    return [v.syms[i] for i ∈ idxs]
end

function variable_type(vs::FoodwebVariables{T}, x::T)::VariableType where T

    return variable_type(vs, get_index(vs, x))
end

function variable_type(vs::FoodwebVariables, x::Int64)::VariableType

    return vs.type[x]
end

function get_symbol(vs::FoodwebVariables, x::Int64)::Symbol

    return vs.syms[x]
end

function get_index(vs::FoodwebVariables{T}, x::T)::Int64 where T

    return vs.idxs[x]
end

function get_index(vs::FoodwebVariables{T}, x::Vector{T})::Vector{Int64} where T

    return get_index.(Ref(vs), x)
end

function set_value!(vs::FoodwebVariables{T}, x::T, val::Float64) where T

    idx = get_index(vs, x)
    vs.vals[idx] = val
end

function get_value(vs::FoodwebVariables{T}, x::T)::Float64 where T

    idx = get_index(vs, x)
    return vs.vals[idx]
end

# --------------------- #
#  Overloads from Base  #
# --------------------- #

function Base.show(io::IO, ::MIME"text/plain", v::FoodwebVariables)

    str = "$(typeof(v))
        Species variables: $(length(variables(v, type = SPECIES_VARIABLE)))
        Trait variables: $(length(variables(v, type = TRAIT_VARIABLE)))
        Environment variables: $(length(variables(v, type = ENVIRONMENT_VARIABLE)))"
   
    print(io, str)
end

function Base.length(vs::FoodwebVariables)

    return length(vs.syms)
end

function Base.in(x::Symbol, vs::FoodwebVariables)

    for s in vs.syms
   
        if s == x

            return true
        end
    end

    return false
end

function Base.in(x::Int64, vs::FoodwebVariables)

    return 0 < x < length(vs)
end
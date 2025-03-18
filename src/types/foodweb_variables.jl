@enum VariableType begin

    SPECIES_VARIABLE
    ENVIRONMENT_VARIABLE
    TRAIT_VARIABLE
    PARAMETER
end

struct FoodwebVariables{T}

    type::Vector{VariableType}
    syms::Vector{T}
    vars::Vector{Num}
    idxs::Dict{Union{T, Num}, Int64}
    vals::Vector{Float64}
end

function FoodwebVariables{T}()::FoodwebVariables{T} where T

    return FoodwebVariables{T}(
        Vector{VariableType}(),
        Vector{T}(),
        Vector{Num}(),
        Dict{Union{T, Num}, Int64}(),
        Vector{Float64}()
    )
end

function FoodwebVariables(spp::Vector{T})::FoodwebVariables{T} where T

    vs = FoodwebVariables{T}() 

    for sp in spp

        add_var!(vs, sp, SPECIES_VARIABLE)
    end

    return vs
end

function add_var!(vs::FoodwebVariables, v::Symbol, type::VariableType)

    var = create_var(v, ModelingToolkit.t_nounits)

    add_var!(vs, v, var, type)

    return var
end

function add_var!(vs::FoodwebVariables, v::Symbol, var::Num, type::VariableType)

    push!(vs.type, type)
    push!(vs.vars, var)
    push!(vs.syms, v)
    push!(vs.vals, 0.0) 
    vs.idxs[v] = lastindex(vs.type)
    vs.idxs[var] = lastindex(vs.type) 

    return var
end

function variables(v::FoodwebVariables; type::Union{VariableType, Missing} = missing)

    if ismissing(type)

        return v.vars
    end

    idxs = findall(x -> x == type, v.type)

    return [v.vars[i] for i ∈ idxs]
end

function get_symbol(vs::FoodwebVariables, x::Num)

    return vs.syms[get_index(vs, x)]
end

function get_symbol(vs::FoodwebVariables, x::Int64)

    return vs.syms[x]
end

function get_variable(vs::FoodwebVariables, x::Symbol)

    return vs.vars[get_index(vs, x)]
end

function get_variable(vs::FoodwebVariables, x::Int64)

    return vs.vars[x]
end

function get_index(vs::FoodwebVariables, x::Union{Symbol, Num})

    return vs.idxs[x]
end

function set_value!(vs::FoodwebVariables, x::Union{Symbol, Num}, val::Float64)

    idx = get_index(vs, x)
    vs.vals[idx] = val
end

function get_value(vs::FoodwebVariables, x::Union{Symbol, Num})

    idx = get_index(vs, x)
    return vs.vals[idx]
end

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
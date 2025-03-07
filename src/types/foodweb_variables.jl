@enum VariableType begin

    SPECIES_VARIABLE
    ENVIRONMENT_VARIABLE
    TRAIT_VARIABLE
end

struct FoodwebVariables{T}

    type::Vector{VariableType}
    syms::Vector{T}
    vars::Vector{Num}
    idxs::Dict{Union{T, Num}, Int64}
end

function FoodwebVariables{T}()::FoodwebVariables{T} where T

    return FoodwebVariables{T}(
        Vector{VariableType}(),
        Vector{T}(),
        Vector{Num}(),
        Dict{Union{T, Num}, Int64}()
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

function add_var!(vs::FoodwebVariables, v::Symbol, var::Num ,type::VariableType)

    push!(vs.type, type)
    push!(vs.vars, var)
    push!(vs.syms, v)
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

function sym_to_var(vs::FoodwebVariables, s::Symbol)

    return vs.vars[vs.idxs[s]]
end

function var_to_sym(vs::FoodwebVariables, v::Num)

    return vs.syms[vs.idxs[v]]
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
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
end

function add_var!(vs::FoodwebVariables, v::Symbol, var::Num ,type::VariableType)

    push!(vs.type, type)
    push!(vs.vars, var)
    push!(vs.syms, v)
    vs.idxs[v] = lastindex(vs.type)
    vs.idxs[var] = lastindex(vs.type) 
end

function variables(v::FoodwebVariables; type::Union{VariableType, Missing} = missing)

    if ismissing(type)

        return v.vars
    end

    idxs = findall(x -> x == type, v.type)

    return [v.vars[i] for i ∈ idxs]
end

function Base.show(io::IO, ::MIME"text/plain", v::FoodwebVariables)

    str = "$(typeof(v))
        Variables: $(length(v.syms))      
    "
   
    print(io, str)
end
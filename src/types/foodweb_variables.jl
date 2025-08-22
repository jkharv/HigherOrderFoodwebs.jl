@enum VariableType begin

    SPECIES_VARIABLE
    ENVIRONMENT_VARIABLE
    TRAIT_VARIABLE
    PARAMETER
end

struct FoodwebVariables{T}

    type::Vector{VariableType}
    syms::Vector{T}
    vals::Vector{Float64}
    idxs::Dict{T, Int64}
end

function FoodwebVariables{T}()::FoodwebVariables{T} where T

    return FoodwebVariables{T}(
        Vector{VariableType}(),
        Vector{T}(),
        Vector{Float64}(),
        Dict{T, Int64}(),
    )
end

function FoodwebVariables(spp::Vector{T})::FoodwebVariables{T} where T

    vs = FoodwebVariables{T}() 

    for sp in spp

        add_var!(vs, sp, SPECIES_VARIABLE)
    end

    return vs
end
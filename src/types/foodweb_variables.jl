"""
    VariableType

`Enum` representing the possible types of variable in a `FoodwebModel` :

`SPECIES_VARIABLE` : Variable representing the density or abundace of a species
in the `FoodwebModel`. Each becomes one equation in the system of ODEs. Species 
variables correspond to nodes in the `AnnotatedHypergraph`

`ENVIRONMENT_VARIABLE` : Variable representing something other than a species,
such as temperature or nitrogen levels, etc. Each becomes one equation in the
system of ODEs, does not appear in the `AnnotatedHypergraph`.

`TRAIT_VARIABLE` : Represents a dynamic trait of some species, whose evolution
is described by an ODE. Does not appear in the `AnnotatedHypergraph`.

`PARAMETER` : Represents a model parameter. Does not add ODEs to the system, and
does not appear in the `AnnotatedHypergraph`

There is a case to be made for merging `ENVIRONMENT_VARIABLE` and
`TRAIT_VARIABLE` since if we're just classifying these variables according to
(In Hypergraph) X (Is Dynamic), they're the same.

This informs how the model is compiled and solved.
"""
@enum VariableType begin
 
    SPECIES_VARIABLE
    ENVIRONMENT_VARIABLE
    TRAIT_VARIABLE
    PARAMETER
end

"""
    FoodwebVariables{T}

Container type used to keep track of the variables in a `FoodwebModel`. Allows
a consistent mapping between the `Symbol` representing a species, variable,
parameter, etc.  and integer indices.
"""
struct FoodwebVariables{T}

    type::Vector{VariableType}
    syms::Vector{T}
    vals::Vector{Float64}
    idxs::Dict{T, Int64}
end

"""
    FoodwebVariables{T}()

Returns an empty instance of `FoodwebVariables{T}`
"""
function FoodwebVariables{T}()::FoodwebVariables{T} where T

    return FoodwebVariables{T}(
        Vector{VariableType}(),
        Vector{T}(),
        Vector{Float64}(),
        Dict{T, Int64}(),
    )
end

"""
    FoodwebVariables{T}(spp::Vector{T})

Returns an instance of `FoodwebVariables{T}` with `spp` as 
variables of type `VariableType::SPECIES_VARIABLE` 
"""
function FoodwebVariables(spp::Vector{T})::FoodwebVariables{T} where T

    vs = FoodwebVariables{T}() 

    for sp in spp

        add_var!(vs, sp, SPECIES_VARIABLE)
    end

    return vs
end
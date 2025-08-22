# -------------------------------------------------- #
#  Overloads of SpeciesInteractionNetwork interface  #
# -------------------------------------------------- #

SpeciesInteractionNetworks.species(fwm::FoodwebModel) = species(fwm.hg)
SpeciesInteractionNetworks.richness(fwm::FoodwebModel) = richness(fwm.hg) 
SpeciesInteractionNetworks.interactions(fwm::FoodwebModel) = interactions(fwm.hg) 

# This function should be moved into SpeciesInteractionNetworks probably
function isproducer(fwm::FoodwebModel, sp)::Bool

    @assert sp ∈ species(fwm)

    for intx ∈ interactions(fwm)

        if isloop(intx)

            continue
        elseif subject(intx) == sp

            return false
        end
    end

    return true
end

# This function should be moved into SpeciesInteractionNetworks probably
function isconsumer(fwm::FoodwebModel, sp)::Bool

    return !isproducer(fwm, sp)
end

# ---------------------------------------------------------------------- #
#  Forwarding (mostly) onto the interface for the FoodwebVariables type  #
# ---------------------------------------------------------------------- #

# Variables and parameters are stored in two seperate FoodwebVariables objects
# This is something that might be worth revisiting in the future, but for now, 
# all of the functions below have got to check both objects for the proper
# entry.

function get_variable(fwm::FoodwebModel, x::Symbol)

    if x ∈ fwm.vars

        return get_variable(fwm.vars, x)
    elseif x ∈ fwm.params

        return get_variable(fwm.params, x)
    else

        error("Could not find $x in $fwm. Parameters are disambiguated and may
        not have the symbol you expect")
    end
end

function get_value(fwm::FoodwebModel{T}, x::T)::Float64 where T

    if x ∈ fwm.vars

        return get_value(fwm.vars, x)
    elseif x ∈ fwm.params

        return get_value(fwm.params, x)
    else

        error(
            "Could not find $x in $fwm. Parameters are disambiguated and may not
            have the symbol you expect"
        )
    end
end

function variable_type(fwm::FoodwebModel{T}, x::T)::VariableType where T

    if x ∈ fwm.vars

        return variable_type(fwm.vars, x)
    elseif x ∈ fwm.params

        return variable_type(fwm.params, x)
    else

        error(
            "Could not find $x in $fwm. Parameters are disambiguated and may not
            have the symbol you expect"
        )
    end
end

function variable_type(fwm::FoodwebModel, x::Int64)::VariableType

    @warn "This function can return wrong results (or error) if any of the
           indices represent parameters"
    
    return variable_type(fwm.vars, x)
end

function set_u0!(fwm::FoodwebModel{T}, k::T, val::Float64) where T
    
    set_value!(fwm.vars, k, val)
end

function set_u0!(fwm::FoodwebModel{T}, u0::Dict{T, Float64}) where T

    for (k, v) ∈ u0

        set_u0!(fwm, k, v)
    end
end

function set_u0!(fwm::FoodwebModel{T}, u0::Vector{Pair{T, Float64}}) where T

    for (k, v) ∈ u0

        set_u0!(fwm, k, v)
    end
end

function variables(fwm::FoodwebModel; type::Union{VariableType, Missing} = missing)

    return variables(fwm.vars; type = type)
end

function add_var!(fwm::FoodwebModel, v::Symbol, type::VariableType)

    return add_var!(fwm.vars, v, type)
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, spp::Vector{T}, val::Number) where T

    @warn "TODO: This function isn't generic enough and will only work on symbols"

    unambiguous_sym = (Symbol ∘ join)([sym, spp...], "_")

    add_var!(fwm.params, unambiguous_sym, PARAMETER, val)
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, spp::T, val::Number) where T

    return add_param!(fwm, sym, [spp], val)
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, val::Number) where T

    return add_param!(fwm, sym, Vector{T}(), val)
end

# ------------------- #
#  Overloads of Base  #
# ------------------- #

function Base.show(io::IO, ::MIME"text/plain", fwm::FoodwebModel)

    str = """
    $(typeof(fwm))
        → $(length(species(fwm))) species
        → $(length(interactions(fwm))) interactions"""
   
    print(io, str)
end
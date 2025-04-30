SpeciesInteractionNetworks.species(fwm::FoodwebModel) = species(fwm.hg)
SpeciesInteractionNetworks.richness(fwm::FoodwebModel) = richness(fwm.hg) 
SpeciesInteractionNetworks.interactions(fwm::FoodwebModel) = interactions(fwm.hg) 

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

function isconsumer(fwm::FoodwebModel, sp)::Bool

    return !isproducer(fwm, sp)
end

function SpeciesInteractionNetworks.subject(fwm::FoodwebModel, i::AnnotatedHyperedge)

    s = subject(i)
    return fwm.vars.vars[fwm.vars.idxs[s]]
end

function SpeciesInteractionNetworks.object(fwm::FoodwebModel, i::AnnotatedHyperedge)

    s = object(i)
    return fwm.vars.vars[fwm.vars.idxs[s]]
end

function SpeciesInteractionNetworks.with_role(fwm::FoodwebModel, i::AnnotatedHyperedge, r::Symbol)

    s = with_role(r, i)
    return [fwm.vars.vars[fwm.vars.idxs[i]] for i in s]
end

function get_symbol(fwm::FoodwebModel, x::Num)

    return get_symbol(fwm.vars, x)
end

function get_variable(fwm::FoodwebModel, x::Symbol)

    return get_variable(fwm.vars, x)
end

function get_value(fwm::FoodwebModel, x::Union{Symbol, Num})::Float64

    return get_value(fwm.vars, x)
end

function set_u0!(fwm::FoodwebModel{T}, k::Union{T, Num}, val::Float64) where T
    
    set_value!(fwm.vars, k, val)
end

function set_u0!(fwm::FoodwebModel{T}, u0::Dict{T, Float64}) where T

    for (k, v) ∈ u0

        set_u0!(fwm, k, v)
    end
end

function set_u0!(fwm::FoodwebModel, u0::Dict{Num, Float64})

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

    unambiguous_sym = (Symbol ∘ join)([sym, spp...], "_")
    p = create_param(unambiguous_sym)

    add_var!(fwm.params, unambiguous_sym, p, PARAMETER)
    fwm.params.vals[get_index(fwm.params, p)] = val

    return p
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, spp::T, val::Number) where T

    return add_param!(fwm, sym, [spp], val)
end

function add_param!(fwm::FoodwebModel{T}, sym::Symbol, val::Number) where T

    return add_param!(fwm, sym, Vector{T}(), val)
end

function Base.show(io::IO, ::MIME"text/plain", fwm::FoodwebModel)

    str = """
    $(typeof(fwm))
        → $(length(species(fwm))) species
        → $(length(interactions(fwm))) interactions"""
   
    print(io, str)
end
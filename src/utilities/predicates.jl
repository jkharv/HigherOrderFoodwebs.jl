# Simple predicate functions for dealing with Hypergraphs

"""
    issubject(n::Node)::Bool

Returns true if `n` is a subject
"""
function issubject(n::Node)::Bool

    return role(n) == :subject
end

"""
    isobject(n::Node)::Bool

Returns true if `n` is an object 
"""
function isobject(n::Node)::Bool

    return role(n) == :object
end

"""
    isloop(e::Edge)::Bool

Returns true if the edge `e` is a loop (subject and object species are identical).
Returns false otherwise.
"""
function isloop(e::Edge)::Bool

    return species(subject(e))[1] == species(object(e))[1]
end

"""
    isproducer(node::Node, trophic_levels::Dict{String, Float64})::Bool

Returns true if the node `node` is a producer (trophic level == 1).
"""
function isproducer(node::Node, trophic_levels::Dict{String, Float64})::Bool

    if length(species(node)) > 1

        error("The node must represent a single species to use this.")
    end

    sp_tl = trophic_levels[species(node)[1]]

    return sp_tl == 1.0 
end

"""
    isconsumer(node::Node, trophic_levels::Dict{String, Float64})::Bool

Returns true if the node `node` is a consumer (trophic level > 1.0).
"""
function isconsumer(node::Node, trophic_levels::Dict{String, Float64})::Bool

    if length(species(node)) > 1

        error("The node must represent a single species to use this.")
    end

    sp_tl = trophic_levels[species(node)[1]]
    return sp_tl > 1.0 
end

"""
    subject_is_producer(edge::Edge, trophic_levels::Dict{String, Float64})::Bool

Returns true if the subject of the edge `edge` is a producer.
"""
function subject_is_producer(edge::Edge, trophic_levels::Dict{String, Float64})::Bool

    return isproducer(subject(edge), trophic_levels)
end

"""
    subject_is_consumer(edge::Edge, trophic_levels::Dict{String, Float64})::Bool

Returns true if the subject of the edge `edge` is a consumer.
"""
function subject_is_consumer(edge::Edge, trophic_levels::Dict{String, Float64})::Bool

    return isconsumer(subject(edge), trophic_levels)
end

"""
    contains_species(e::Edge, spp::Vector{String}, r::Vector{Symbol})::Bool

Returns true if `e` contains a species in `spp` which plays a role in `r`, otherwise
false.
"""
function contains_species(e::Edge, spp::Vector{String}, r::Vector{Symbol})

    for n in e.nodes

        if (n.species ∈ spp) & (n.role ∈ r)
            return true
        end
    end

    return false
end

"""
    contains_species(e::Edge, sp::String, r::Symbol)::Bool

Returns true if `e` contains species `sp` playig role `r`, otherwise false.
"""
function contains_species(e::Edge, sp::String, r::Symbol)::Bool

    return contains(e, [sp], [r])
end
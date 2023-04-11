# Simple predicate functions for dealing with Hypergraphs

"""
    isloop(e::Edge)::Bool

Returns true if the edge `e` is a loop (subject and object species are identical).
Returns false otherwise.
"""
function isloop(e::Edge)::Bool

    return species(subject(e)) == species(object(e))
end

"""
    contains(e::Edge, spp::Vector{String}, r::Vector{Symbol})::Bool

Returns true if the edge `e` contains a species in spp which fulfills a role in `r`.
"""
function contains(e::Edge, spp::Vector{String}, r::Vector{Symbol})

    for n in e.nodes

        if (n.species ∈ spp) & (n.role ∈ r)
            return true
        end
    end

    return false
end

"""
    contains(e::Edge, sp::String, r::Symbol)

Returns true if the edge `e` contains species `sp` playig role `r.
Returns false otherwise.
"""
function contains(e::Edge, sp::String, r::Symbol)

    return contains(e, [sp], [r])
end
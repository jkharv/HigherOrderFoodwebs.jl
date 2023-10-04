"""
    get_resource_interactions(sp::String, hg::EcologicalHypergraph)::Vector{Edge}

Given a species, this function will return all the interations it has with all its
resources.
"""
function get_resource_interactions(sp::String, hg::EcologicalHypergraph)

    ints = interactions(hg)
   
    ints = filter(x -> species(subject(x))[1] == sp, ints)
    ints = filter(x -> !isloop(x), ints)

    return ints
end

function optimal_foraging!(edge::Edge)

    focal_resource = species(object(edge))[1]
    consumer = species(subject(edge))[1]

    resources = get_resource_interactions(consumer, edge.hg.value)
    f(x) = species(object(x))[1]
    resources = f.(resources)

    alternate_resources = filter(x -> x != focal_resource, resources)

    # Ensure that the focal resource is always listed first.
    add_modifier!(edge, vcat(focal_resource, alternate_resources))
end

function optimal_foraging!(hg::EcologicalHypergraph)

    mods = Vector{Node}()

    for interaction in interactions(hg)

        push!(mods, optimal_foraging!(interaction))
    end
    return mods
end
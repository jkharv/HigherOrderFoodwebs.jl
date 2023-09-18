function string_to_var(hg::EcologicalHypergraph, s::String)

    x = findfirst(x -> subject(x).species[1] == s, interactions(hg))
    spp = subject(interactions(hg)[x])
    var = collect(keys(vars(spp)))[1]

    return var
end

function remove!(hg::EcologicalHypergraph, sp::String)

    names = map(x -> x.species, nodes(hg)) 

    for i in eachindex(names)

        if sp ∈ names[i]

            remove!(nodes(hg)[i])
        end
    end

    remove_orphan_species!(hg)
end

function remove!(node::Node)

    edge = node.edge.value

    if length(nodes(edge)) <= 2

        remove!(edge)
    end

    for i ∈ eachindex(nodes(edge))

        deleteat!(nodes(edge), i)
        break
    end

    remove_orphan_species!(edge.hypergraph.value)
end

function remove!(edge::Edge)

    hg = edge.hypergraph.value

    for i ∈ eachindex(interactions(hg))

        if interactions(hg)[i] == edge
           
            deleteat!(interactions(hg), i)
            break
        end
    end

    remove_orphan_species!(hg)
end

function remove_orphan_species!(hg::EcologicalHypergraph)

    names = map(x -> x.species, nodes(hg))
    names = collect(Iterators.flatten(names))
    unique!(names)

    hg.species = sort(names)
end
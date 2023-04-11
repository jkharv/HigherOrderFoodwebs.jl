# Pretty printing overides for EcologicalHypergraphs.jl types
function Base.show(io::IO, hg::EcologicalHypergraph)
    # TODO Move out of declarations file.   
    print(io, "EcologicalHypergraph
    • Species: $(length(species(hg))) 
    • Interactions: $(length(interactions(hg)))"
    )
end

function Base.show(io::IO, e::Edge)
    # TODO Move out of declarations file.
    sub = subject(e)  
    obj = object(e)
    mods = modifiers(e)
    mods = map(x -> x.species, mods)

    print(io, "Edge \
    $(obj.species) → $(sub.species); Modified by: $(join(mods, ", "))" 
    )
end

function Base.show(io::IO, n::Node)
    # TODO Move out of declarations file.
    print(io, "Node • $(n.species) as a $(n.role)")
end
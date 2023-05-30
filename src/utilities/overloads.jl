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
    $(obj.species[1]) → $(sub.species[1]); Modified by: $(join(mods, ", "))" 
    )
end

function Base.show(io::IO, node::Node)
    
    if length(species(node)) > 1 

        print(io, "Node • ")
        print(io, "(")
        print(io, join(species(node), ", "))
        print(io, ")")
        print(io, " as a $(role(node))")
    else
        print(io, "Node • $(species(node)[1]) as a $(role(node))")
    end
end
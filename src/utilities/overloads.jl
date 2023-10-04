# Pretty printing overides for EcologicalHypergraphs.jl types
function Base.show(io::IO, hg::EcologicalHypergraph)
    
    print(io, "EcologicalHypergraph
    • Species: $(length(species(hg))) 
    • Interactions: $(length(interactions(hg)))"
    )
end

function Base.show(io::IO, e::Edge)
    
    sub = subject(e)  
    obj = object(e)
    mods = modifiers(e)
    mods = map(x -> species(x), mods)

    print(io, "Edge \
    $(species(obj)[1]) → $(species(sub)[1]); Modified by: $(join(mods, ", "))" 
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

# This overload for Symbolics.jl types is necessary until the following issue is
# addressed
# https://github.com/JuliaSymbolics/Symbolics.jl/issues/930
function Base.in(x::Num, itr::Vector{Num})

    for y in itr
    
        if isequal(x, y)
            return true
        end
    end
    return false
end
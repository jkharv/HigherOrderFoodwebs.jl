function AnnotatedHypergraph(web) 

    ints = findall(!iszero, web.edges.edges)
    ints = Tuple.(ints)
    spp = web.nodes.margin 
    ints = [[spp[first(i)], spp[last(i)]] for i ∈ ints]

    hyperedges = Vector{AnnotatedHyperedge}(undef, length(ints))

    for (i, int) ∈ enumerate(ints)

        hyperedges[i] = AnnotatedHyperedge(int, [:subject, :object], true) 
    end
  
    return SpeciesInteractionNetwork(Unipartite(spp), hyperedges)
end
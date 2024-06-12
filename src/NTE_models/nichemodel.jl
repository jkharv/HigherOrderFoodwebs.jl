function nichemodel(species::Integer=10, connectance::T=0.2) where {T <: AbstractFloat}

    @assert 0.0 < connectance < 0.5
    
    β = 1.0/(2 * connectance) - 1.0
    
    edges = zeros(Bool, (species, species))
    
    niche = sort(rand(Uniform(0.0, 1.0), species))
    centroids = zeros(species)
    ranges = niche .* rand(Beta(1.0, β), species)

    for species in axes(niche, 1)
        centroids[species] = rand(Uniform(ranges[species]/2, niche[species]))
    end

    for smallest_species in findall(isequal(minimum(niche)), niche)
        ranges[smallest_species] = 0.0
    end

    for consumer in axes(edges,1)
        for resource in axes(edges,2)
            if niche[resource] < centroids[consumer] + 0.5ranges[consumer]
                if niche[resource] > centroids[consumer] - 0.5ranges[consumer]
                    edges[consumer,resource] = true
                end
            end
        end
    end

    z = findall(edges)
    z = Tuple.(z)    

    z = AnnotatedHyperedge.(
        [[Symbol("node_$(first(i))"), Symbol("node_$(last(i))")] for i in z],
        Ref([:subject, :object]), 
        Ref(true)
    )

    spp = Unipartite(Symbol.(["node_$i" for i in 1:species]))
    
    return SpeciesInteractionNetwork(spp, z)
end
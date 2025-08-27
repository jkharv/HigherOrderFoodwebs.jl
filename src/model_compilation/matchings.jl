# OK Matchings 

# This is very quick and dirty but could be made faster using an
# actual maximum matching algorithm like Blossom or Duan & Pettie 2014

function find_matching!(edges, seed_intx)

    spp = Set{Symbol}()

    push!(spp, subject(seed_intx))
    push!(spp, object(seed_intx))

    matching = Vector{AnnotatedHyperedge}()
    push!(matching, seed_intx)
    delete!(edges, seed_intx)

    for intx in edges 
    
        s = subject(intx)    
        o = object(intx)

        if !(s ∈ spp) & !(o ∈ spp)

            push!(spp, o)
            push!(spp, s)
            push!(matching, intx)
            delete!(edges, intx)
        end
    end

    return matching
end

function matching_decomposition(web)

    edges = (Set ∘ copy ∘ interactions)(web)

    matchings = Vector{Vector{AnnotatedHyperedge}}()

    while !isempty(edges)

        matching = find_matching!(edges, first(edges))
        push!(matchings, matching)
    end

    return matchings
end
function producers(web)

    return filter(x-> generality(web, x) == 0, species(web))
end

function trophic_ordering(web::SpeciesInteractionNetwork)

    ordering  = filter(x-> (length ∘ successors)(web, x) == 0.0, species(web))
    remaining = setdiff((copy ∘ species)(web), ordering)
  
    n = 0    

    while !isempty(remaining) & (n < 50)
   
        n = n + 1

        for sp in ordering 

            candidates = (collect ∘ setdiff)(predecessors(web, sp), ordering)

            if isempty(candidates)
                continue
            end

            sort!(candidates, by = x -> generality(web, x))
            push!(ordering, first(candidates))
            remaining = setdiff(remaining, ordering)
        end
        
    end

    return ordering
end

function trophic_levels(net::SpeciesInteractionNetwork{Unipartite{T}, Binary{Bool}};
    max_error = 0.01, 
    max_iterations = 100
    ) where T

    tls = Dict(species(net) .=> 0.0)

    for sp in producers(net)

        tls[sp] = 1.0
    end

    tls_old = copy(tls)

    to = trophic_ordering(net)

    for i in 1:max_iterations

        tls_old = copy(tls)

        for sp in to
            
            acc = 0 

            for r in successors(net, sp)

                acc += tls[r]
                acc = acc / (length ∘ successors)(net, sp)
            end

            tls[sp] = acc + 1.0
        end

        err = maximum(abs.((collect ∘ values)(tls_old) - (collect ∘ values)(tls)))

        if err < max_error
            println(i)
            break
        end

    end

    return tls
end
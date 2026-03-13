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

function trophic_levels(net::SpeciesInteractionNetwork{Unipartite{T}, U};
    max_error = 0.01, 
    max_iterations = 100,
    type = :mean
    ) where {T, U <: Union{Binary{Bool}, Probabilistic{Float64}}}

    @assert type in [:mean, :maximum, :minimum]

    tls = Dict(species(net) .=> 0.0)

    for sp in producers(net)

        tls[sp] = 1.0
    end

    tls_old = copy(tls)

    ordering = trophic_ordering(net)

    for i in 1:max_iterations

        tls_old = copy(tls)

        for sp in ordering

            weights = [net[sp, r] for r in successors(net, sp)]            
            weights = weights/sum(weights)
            tl_diet = [tls[r] for r in successors(net, sp)]

            if isempty(tl_diet)

                tls[sp] = 1                

            elseif type == :mean

                tls[sp] = sum(weights .* tl_diet) + 1

            elseif type == :maximum

                tls[sp] = maximum(tl_diet) + 1

            elseif type == :minimum

                tls[sp] = minimum(tl_diet) + 1
            end


        end

        err = maximum(abs.((collect ∘ values)(tls_old) - (collect ∘ values)(tls)))

        if err < max_error
            println("Stopped early!")
            break
        end

    end

    return tls
end

"""
    trophic_levels(web::SpeciesInteractionNetwork) 

Calculates the trophic level of each species in a food web according to the
algorithm presented in Levine (1980). Returns a `Dict{T, Float64}`

## References

Levine, S. 1980. Several measures of trophic structure applicable to complex
food webs. - Journal of Theoretical Biology 83: 195–207.
"""
function trophic_levels(web::SpeciesInteractionNetwork)::Dict{Symbol, Float64}

    if count(x-> generality(web, x) == 0, species(web)) == 0

        error("Trophic level is only defined with at least one basal species.")
    end

    m = Matrix(copy(web.edges.edges))

    # *Basal or unconnected
    non_basal_indices = Vector{Int64}()
    basal_indices = Vector{Int64}()
    for (i, row) in (enumerate ∘ eachrow)(m)

        if sum(row) > 0

            push!(non_basal_indices, i)
        else

            push!(basal_indices, i)
        end
    end

    Q = Matrix{Float64}(undef, size(m)...)

    for (i, row) in (enumerate ∘ eachrow)(m)

        if sum(row) > 0
    
            Q[i, :] = row / sum(row)
        else

            Q[i, :] = zeros(Float64, length(row))
        end
    end

    for i in 1:size(Q)[1]

        Q[i,i] = 0.0
    end

    # Partition a matrix without the basal species.
    Q = Q[non_basal_indices, non_basal_indices]
   
    i = Matrix(1.0I, size(Q))
    N = inv(i - Q)

    tls = Dict{Symbol, Float64}()

    for (i, row) in (enumerate ∘ eachrow)(N)

        sp = non_basal_indices[i]
        
        tls[species(web)[sp]] = sum(row) + 1.0
    end

    for i in basal_indices

        tls[species(web)[i]] = 1.0
    end

    return tls
end
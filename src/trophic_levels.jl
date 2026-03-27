"""
    trophic_levels(web::SpeciesInteractionNetwork)::Dict{Symbol, Float64} 

Calculates the trophic level of each species in a food web according to the
algorithm presented in MacKay (2020).

## References

MacKay, R. S., Johnson, S. and Sansom, B. 2020. How directed is a directed
network? - R Soc Open Sci. 7: 201138.

"""
function trophic_levels(web::SpeciesInteractionNetwork)::Dict{Symbol, Float64}

    A = convert(SparseMatrixCSC{Float64}, web.edges.edges)

    L = laplacian(A)
    v = imbalance_vector(A)

    h = qr(L) \ v

    # Move everthing up to have minimum value of 1
    h = h .+ (abs(minimum(h)) + 1)
    h = Dict(species(web) .=> h)

    # Set all the basal species to have a trophic level of 1
    for sp in basal_species(web)

        h[sp] = 1.0
    end

    return h
end

function basal_species(web)::Vector{Symbol}

    return filter(x-> generality(web, x) == 0, species(web))
end

function laplacian(A::SparseMatrixCSC{Float64})::SparseMatrixCSC{Float64}
    
    D = spdiagm(weight_vector(A))
    
    return D - A - transpose(A)
end

function weight_vector(A::SparseMatrixCSC{Float64})::Vector{Float64}

    return abs.(sum.(eachrow(A))) + abs.(sum.(eachcol(A)))
end

function imbalance_vector(A::SparseMatrixCSC{Float64})::Vector{Float64}

    in  = abs.(sum.(eachrow(A)))
    out = abs.(sum.(eachcol(A)))

    return in - out
end

function remove_loops(web::SpeciesInteractionNetwork{T, U})::SpeciesInteractionNetwork{T, U} where {T,U}

    m = copy(web.edges.edges)

    for i in diagind(m)

        m[i] = zero(eltype(m))
    end

    return SpeciesInteractionNetwork{T, U}(copy(web.nodes), typeof(web.edges)(m))
end
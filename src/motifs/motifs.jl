"""
    role_incidence_matrix(\
    web::AnnotatedHypergraph)::Matrix{Union{Set{Symbol}, Nothing}}

Returns a incidence matrix representation of an `AnnotatedHypergraph`. Where
species \$Sn\$ does not belong to an interaction \$Em\$ the entry \$(Sn, Em)\$
of the incidence matrix will be `nothing`, otherwise \$(Sn, Em)\$ will be a
`Set{Symbol}` representating the roles that \$Sn\$ plays in \$Em\$.
"""
function role_incidence_matrix(web::AnnotatedHypergraph)::Matrix{Union{Set{Symbol}, Nothing}}
    
    s = richness(web) 
    l = (length ∘ interactions)(web)
    m = Matrix{Union{Set{Symbol}, Nothing}}(nothing, s, l)
    
    # Cols are interactions 
    for (n, intx) in enumerate(interactions(web))

        # Rows are species
        for sp in species(intx)
            
            indx = findfirst(x -> x == sp, species(web))  
            r = (Set ∘ roles)(sp, intx)

            m[indx, n] = r
        end 
    end

    return m
end

"""
    incidence_matrix_permutations(m::Matrix{T})::Vector{Matrix{T}} where T

Returns a `Vector` of all the possible permutations of an incidence matrix.
"""
function incidence_matrix_permutations(m::Matrix{T})::Vector{Matrix{T}} where T

    row_p = permutations(1:size(m)[1])
    col_p = permutations(1:size(m)[2])

    mps = Vector{Matrix{T}}(undef, length(row_p) * length(col_p))

    i = 1 
    for rp in row_p
        for cp in col_p

            mps[i] = m[rp, cp]
            i += 1    
        end
    end

    return unique(mps)
end

"""
    is_motif_match(motif, subgraph)

Returns `true` if subgraph matches with motif. An `AnnotatedHyperedge` in the
motif is considered to match an `AnnotatedHyperedge` in `subgraph` when it can
be found as a subset (⊆) within it.
"""
function is_motif_match(motif, subgraph)

    for (m, s) in zip(motif, subgraph) 

        if isnothing(m) | isnothing(s)

            if m == s
                continue
            else
                return false
            end
        else

            if m ⊆ s
                continue
            else
                return false
            end
        end
    end

    return true 
end

"""
    findmotif(motif::AnnotatedHypergraph, \
    web::AnnotatedHypergraph)::Vector{Vector{AnnotatedHyperedge}}

Returns all the subgraphs of `web` that match `motif`.

The outer `Vector` in the return type holds each match. The inner `Vector` holds
the `AnnotatedHyperedge`s in `web` belonging to a particular subgraph which
matches to `motif`

This functions satisfies the F1 definition of motif matching. Furthermore, an 
`AnnotatedHyperedge` in the motif is considered to match an `AnnotatedHyperedge`
in `web` when it can be found as a subset (⊆) within it.
"""
function SpeciesInteractionNetworks.findmotif(
    motif::AnnotatedHypergraph, 
    web::AnnotatedHypergraph)::Vector{Vector{AnnotatedHyperedge}}

    if richness(web) >= 30
        @info "This might take while..."
    end

    intx_combinations = combinations(
        1:(length ∘ interactions)(web),
        (length ∘ interactions)(motif)
    )
    spp_combinations  = combinations(1:richness(web), richness(motif))

    perms = (incidence_matrix_permutations ∘ role_incidence_matrix)(motif)
    m = role_incidence_matrix(web)
    
    hits = []

    hits_lock = ReentrantLock()

    Threads.@threads for intxs in collect(intx_combinations)
        for spp in collect(spp_combinations)

            for p in perms

                if is_motif_match(p, m[spp, intxs])

                    lock(hits_lock) do
                        push!(hits, interactions(web)[intxs])
                    end
                end
            end
        end
    end
    
    return hits 
end
function optimal_foraging(hg, sp)::SpeciesInteractionNetwork

    sp_trophic_intrxs = filter(x -> !isloop(x) && (subject(x) == sp), interactions(hg))
    sp_resources = object.(sp_trophic_intrxs)

    other_intrxs = setdiff(interactions(hg), sp_trophic_intrxs)

    modified_intrxs = Vector{AnnotatedHyperedge}()

    for intrx ∈ sp_trophic_intrxs

        other_resources = setdiff(sp_resources, [object(intrx)])
        roles = [:AF_modifier for i ∈ 1:length(other_resources)]

        i = AnnotatedHyperedge(
           [subject(intrx), object(intrx), other_resources...],
           [:subject, :object, roles...]
        )

        push!(modified_intrxs, i)
    end

    return SpeciesInteractionNetwork(
        Unipartite(species(hg)),
        [other_intrxs..., modified_intrxs...]
    )
end

function optimal_foraging(hg, spp::Vector{Symbol})::SpeciesInteractionNetwork

    new_hg = hg

    for sp ∈ spp


        new_hg = optimal_foraging(new_hg, sp)
    end

    return new_hg
end

optimal_foraging(hg) = optimal_foraging(hg, species(hg))
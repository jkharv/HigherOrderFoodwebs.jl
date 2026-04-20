function realized_network(sol, t; 
    include_reverse_interactions = false,
    include_loops = false,
    )::SpeciesInteractionNetwork

    fwm = sol.prob.f.sys
    drs = fwm.dynamic_rules
    m = spzeros(richness(fwm), richness(fwm))

    ps = get_value.(Ref(fwm.params), variables(fwm.params))

    for i in interactions(fwm)

        dr = drs[i]
        s = get_index(fwm.vars, subject(i))
        o = get_index(fwm.vars, object(i))

        if isloop(i) & include_loops

            m[s, o] = dr(sol(t), ps, t)
        elseif !isloop(i) & include_reverse_interactions

            f, r = dr(sol(t), ps, t)
            m[s, o] = f
            m[o, s] = r
        elseif !isloop(i) & !include_reverse_interactions

            f, r = dr(sol(t), ps, t)
            m[s, o] = f
        end
    end

    return SpeciesInteractionNetwork((Unipartite ∘ species)(fwm), Quantitative(m))
end

function turnover_network(sol, t; 
    include_reverse_interactions = false,
    include_loops = false,
    )::SpeciesInteractionNetwork

    net = realized_network(sol, t;
        include_reverse_interactions = include_reverse_interactions,
        include_loops = include_loops
    )

    for (s, o, f) in interactions(net) 
        
        net[s, o] = f / sol(100, idxs = o)
    end

    return net
end

function simulate_sampling(
    net::SpeciesInteractionNetwork{Unipartite{T}, Quantitative{Float64}}
    )::SpeciesInteractionNetwork{Unipartite{T}, Probabilistic{Float64}} where T

    flux = [f for (_,_,f) in net]
    subj = [s for (s,_,_) in net]
    obj  = [o for (_,o,_) in net]
    dist = Exponential(mean(flux))
    prob = map(f -> cdf(dist, f), flux)

    edges = zeros(Float64, richness(net), richness(web)) 

    for (s, o, p) in zip(subj, obj, flux)

        s = findfirst(x-> x == s, species(net))
        o = findfirst(x-> x == o, species(net))

        edges[s, o] = p
    end

    for row in eachrow(edges)

        avg = mean(row)

        if avg == 0.0 continue end

        dist = Exponential(avg)
        map!(f -> cdf(dist, f), row) 
    end

    return SpeciesInteractionNetwork(copy(net.nodes), Probabilistic(edges))
end

"""
    rescale_network(
    web::SpeciesInteractionNetwork{Unipartite{T}, Quantitative{U}}
    )::SpeciesInteractionNetwork{Unipartite{T}, Probabilistic{U}} where {T,U}

Rescales the weights of a Quantitative network to be between 0 and 1 and returns
a Probabilistic web. Weights are rescaled such that the interaction probabilities
for a consumer and all of it's resources sum to one.
"""
function rescale_network(
    web::SpeciesInteractionNetwork{Unipartite{T}, Quantitative{U}}
    )::SpeciesInteractionNetwork{Unipartite{T}, Probabilistic{U}} where {T,U}

    m = spzeros(Float64, size(web.edges.edges))
   
    for (i, row) in (enumerate ∘ eachrow)(web.edges.edges)

        m[i, :] = row
        
        # If it's got a really small magnitude and is negative, it's probably a
        # floating point error. Not doing this very occasionally triggered the
        # assert for 0 < x < 1 in the constructor for Probabilistic.
        for j in eachindex(m[i, :])

            if (abs(m[i, j]) < 1e-15) & (m[i, j] < 0)

                m[i, j] = 0.0
            end
        end

        if sum(m[i, :]) == 0
            continue
        end

        m[i, :] = m[i, :] / sum(m[i, :])
    end

    return SpeciesInteractionNetwork(copy(web.nodes), Probabilistic(m))
end

"""
    trim_network(
    web::SpeciesInteractionNetwork{<:Unipartite{T}, U},
    spp::Vector{Symbol}
    )::SpeciesInteractionNetwork{<:Unipartite{T}, U} where {T, U}

Returns a copy of `web` trimmed to contain only the species in `spp`. Species
names remain unchanged.
"""
function trim_network(
    web::SpeciesInteractionNetwork{<:Unipartite{T}, U},
    spp::Vector{Symbol}
    )::SpeciesInteractionNetwork{<:Unipartite{T}, U} where {T, U}

    x = copy(web.edges.edges)[indexin(spp, species(web)), indexin(spp, species(web))]
    intxs = typeof(web.edges)(x)

    return SpeciesInteractionNetwork(Unipartite(spp), intxs)
end
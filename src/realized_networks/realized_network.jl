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
    a Probabilistic web.
"""
function rescale_network(
    web::SpeciesInteractionNetwork{Unipartite{T}, Quantitative{U}}
    )::SpeciesInteractionNetwork{Unipartite{T}, Probabilistic{U}} where {T,U}

    intxs = copy(web.edges.edges)

    max = maximum(intxs)
    min = minimum(intxs)

    for i in findall(!iszero, intxs)
 
        intxs[i] = (intxs[i] - min)/(max-min)
    end

    return SpeciesInteractionNetwork(copy(web.nodes), Probabilistic(intxs))
end
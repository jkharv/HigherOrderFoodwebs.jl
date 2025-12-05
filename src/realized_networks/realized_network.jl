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
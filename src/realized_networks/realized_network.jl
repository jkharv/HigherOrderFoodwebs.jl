function realized_network(sol, t)::SpeciesInteractionNetwork

    fwm = sol.prob.f.sys
    drs = fwm.dynamic_rules
    m = spzeros(richness(fwm), richness(fwm))

    ps = get_value.(Ref(fwm.params), variables(fwm.params))

    for i in interactions(fwm)

        dr = drs[i]
        s = get_index(fwm.vars, subject(i))
        o = get_index(fwm.vars, object(i))

        if isloop(i)

            m[s, o] = dr(sol(t), ps, t)
        else

            f, r = dr(sol(t), ps, t)
            m[s, o] = f
            m[o, s] = r
        end         
    end

    return SpeciesInteractionNetwork((Unipartite ∘ species)(fwm), Quantitative(m))
end
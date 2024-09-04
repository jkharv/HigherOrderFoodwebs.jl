function CommunityMatrix(fwm::FoodwebModel)

    spp = species(fwm)
    s = length(spp)

    aux_vars = (collect ∘ keys)(fwm.aux_vars)
    n_aux_vars = length(aux_vars)

    cm = CommunityMatrix(zeros(Num, s + n_aux_vars, s + n_aux_vars), [spp..., aux_vars...])

    for intrx ∈ interactions(fwm)

        sbj = subject(intrx)
        obj = object(intrx)

        ff = fwm.dynamic_rules[intrx].forwards_function
        bf = fwm.dynamic_rules[intrx].backwards_function

        cm[sbj, obj] = ff
        cm[obj, sbj] = bf
    end

    for eq ∈ fwm.aux_dynamic_rules

        var = first(eq)
        cm[var, var] = last(eq).forwards_function
    end

    return cm
end
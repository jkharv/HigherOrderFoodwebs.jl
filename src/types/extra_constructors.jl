function CommunityMatrix(fwm::FoodwebModel)

    spp = species(fwm)
    s = length(spp)

    cm = CommunityMatrix(zeros(Num, s, s), spp)

    for intrx ∈ interactions(fwm)

        sbj = subject(intrx)
        obj = object(intrx)

        ff = fwm.dynamic_rules[intrx].forwards_function
        bf = fwm.dynamic_rules[intrx].backwards_function

        cm[sbj, obj] = ff
        cm[obj, sbj] = bf
    end

    return cm
end
struct CommunityMatrix{T, U} <: AbstractMatrix{T}

    m::Matrix{T}
    spp::FoodwebVariables{U}

    function CommunityMatrix(m::Matrix{T}, spp::FoodwebVariables{U}) where {T, U}

        new{T, U}(m, spp)
    end
end

function CommunityMatrix(fwm::FoodwebModel)

    vars = deepcopy(fwm.vars)
    n = length(vars)

    cm = CommunityMatrix(zeros(Num, n, n), vars)

    for intrx ∈ interactions(fwm)

        sbj = subject(intrx)
        obj = object(intrx)

        ff = fwm.dynamic_rules[intrx].forwards_function
        bf = fwm.dynamic_rules[intrx].backwards_function

        cm[sbj, obj] = ff
        cm[obj, sbj] = bf
    end

    for eq ∈ fwm.aux_dynamic_rules

        var = get_symbol(fwm, first(eq))
        dr = last(eq)
        cm[var, var] = dr.forwards_function
    end

    return cm
end
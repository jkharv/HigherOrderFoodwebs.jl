struct CommunityMatrix{T, U} <: AbstractMatrix{T}

    m::AbstractMatrix{T}
    spp::FoodwebVariables{U}

    function CommunityMatrix(m::AbstractMatrix{T}, spp::FoodwebVariables{U}) where {T, U}

        new{T, U}(m, spp)
    end
end

function CommunityMatrix(fwm::FoodwebModel)

    vars = deepcopy(fwm.vars)
    n = length(vars)

    m = Matrix{Union{Function, Missing}}(missing, n, n)
    cm = CommunityMatrix(m, vars)

    for intrx ∈ interactions(fwm)

        sbj = subject(intrx)
        obj = object(intrx)

        ff = fwm.dynamic_rules[intrx].fr
        bf = fwm.dynamic_rules[intrx].rr

        cm[sbj, obj] = ff
        cm[obj, sbj] = bf
    end

    return cm
end
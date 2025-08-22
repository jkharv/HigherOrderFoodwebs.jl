struct DynamicRule

    f::Function
    vars::Vector{Symbol}
end

function (dr::DynamicRule)(u, ps, t)

    # World age issues
    return invokelatest(dr.f, u, ps, t)
end
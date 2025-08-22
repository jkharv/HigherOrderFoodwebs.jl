struct DynamicRule

    f::Function
    vars::Vector{Symbol}
end

function (dr::DynamicRule)(u, ps, t)

    return dr.f(u, ps, t)
end
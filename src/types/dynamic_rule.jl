struct DynamicRule

    f::RuntimeGeneratedFunction
    vars::Vector{Symbol}
end

function DynamicRule(f::Expr, vars, mod)

    rtf = RuntimeGeneratedFunction(mod, mod, f)
     
    return DynamicRule(rtf, vars)
end

function (dr::DynamicRule)(u, ps, t)

    return dr.f(u, ps, t)
end
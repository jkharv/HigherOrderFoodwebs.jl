"""
The `DistributionOption` struct is used internally to deal with parameter values given
by the user which may be given as concrete values or as distributions. The `reify` 
function is used before actually doing anything with the value which converts everything
into actual concrete values.
"""
struct DistributionOption

    val::Union{Distribution, Float64}

    function DistributionOption(val::Union{Distribution, Float64})

        new(val)
    end
end

function reify(d::DistributionOption)

    if d.val isa Float64
        return d.val
    else
        return rand(d.val)
    end
end
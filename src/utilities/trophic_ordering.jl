function trophic_ordering(fwm)

    s = copy(species(fwm))
    l = filter(x -> isproducer(fwm, x), species(fwm))

    s = setdiff(s, l)

    while !isempty(s)

        r = nresources.(Ref(fwm), s, Ref(l))
        max_index = findmax(r)[2]

        push!(l, s[max_index])
        s = setdiff(s, l)
    end

    return l
end

function nresources(fwm::FoodwebModel{T}, sp::T, resources::Vector{T}) where T

    return sum(ispredeccessor.(Ref(fwm), Ref(sp), resources))
end

function ispredeccessor(fwm::FoodwebModel, sp::Symbol, pred::Symbol)

    for i in interactions(fwm)

        if (object(i) == pred) & (subject(i) == sp)
            return true
        else
            continue
        end
    end

    return false
end
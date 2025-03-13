function trophic_flux(fwm, sol, t1, t2;
    reverse_flux = false,
    include_loops = true
    )

    @assert t1 <= t2

    flux = Dict{AnnotatedHyperedge, Float64}()

    for intx ∈ interactions(fwm)

        if !include_loops && isloop(intx)

            continue
        end

        if reverse_flux

            f = fwm.dynamic_rules[intx].backwards_function
            flux[intx] = mean(sol(t1:t2, idxs = f))
        else

            f = fwm.dynamic_rules[intx].forwards_function
            flux[intx] = mean(sol(t1:t2, idxs = f))
        end
    end

    return flux
end

trophic_flux(fwm, sol, t; kwargs...) = trophic_flux(fwm, sol, t, t; kwargs...)
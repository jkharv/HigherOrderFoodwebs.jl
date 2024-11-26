function trophic_flux(
    fwm::FoodwebModel{T}, 
    sol::ODESolution, 
    sbj::T,
    obj::T, 
    t::Float64
) where T

    eq = fwm.community_matrix[sbj, obj]
    vs = get_variables(eq)
    subs = Dict(vs .=> 0.0)

    for v in vs    

        if ModelingToolkit.isparameter(v)

            subs[v] = fwm.param_vals[v]
        else

            subs[v] = sol(t, idxs = v)
        end
    end

    return substitute(eq, subs)
end

function trophic_flux(
    fwm::FoodwebModel{T}, 
    sol::ODESolution, 
    intx::AnnotatedHyperedge,
    t::Float64
) where T

    return trophic_flux(fwm, sol, subject(intx), object(intx), t)
end
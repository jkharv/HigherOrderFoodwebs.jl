"""
    fwm_jacobian(fwm::FoodwebModel)::Matrix{Num}

Calculate the (symbolic) jacobian matrix associated with a foodweb model. This
uses structural information from the hypergraph to speed things up. This should
be significantly faster than using Symbolics.jacobian 
"""
function fwm_jacobian(fwm::FoodwebModel)::CommunityMatrix{Num}

    n = (length ∘ variables)(fwm)
    jac = CommunityMatrix(
        spzeros(Num, n, n),
        fwm.vars
    )

    # By going interaction-by-interaction we can deal with only the entries in
    # the the jacobian that will be non-zero. It also limits us to only the
    # parts of function that contain the relevent variables. The other rules
    # should differentiate to zero wrt the subject & object species anyway.
    for intx ∈ interactions(fwm)

        s = subject(fwm, intx)
        o = object(fwm, intx)

        dr = fwm.dynamic_rules[intx]
        vs = dr.vars

        filter!(x -> _in(x, variables(fwm)), vs)

        ff = dr.forwards_function
        rf = dr.backwards_function
        
        for v ∈ vs

            # The (s, v) and (o, v) entries for each v should be the only
            # non-zero entries relating to this interaction
            if isloop(intx)
                # Avoid double counting the elements on the diagonal.
                jac[s, v] += Symbolics.derivative(ff, v)
            else
                jac[s, v] += Symbolics.derivative(ff, v)
                jac[o, v] += Symbolics.derivative(rf, v)
            end
        end
    end

    # With the aux rules, non-zero entries should be limited to the (subj, : )
    # row of the matrix where subj is the dynamic variable in question.
    for (subj, rule) ∈ fwm.aux_dynamic_rules

        vars = rule.vars
        filter!(x -> _in(x, variables(fwm)), vars)
        f = rule.forwards_function

        for v ∈ vars

            jac[subj, v] += Symbolics.derivative(f, v)
        end
    end

    return jac
end

function _in(sym::Num, syms::Vector{Num})

    for s in syms

        if isequal(s, sym)
            return true
        end
    end
    
    return false
end
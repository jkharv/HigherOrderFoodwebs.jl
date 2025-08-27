struct FoodwebModelFunction

    fwm::FoodwebModel
    matchings::Vector{Vector{AnnotatedHyperedge}}

    function FoodwebModelFunction(fwm::FoodwebModel)

        matchings = matching_decomposition(fwm.hg)
        return new(fwm, matchings)
    end
end

function (mf::FoodwebModelFunction)(du, u, ps, t)

    # Reset du
    du .= 0.0

    for matching in mf.matchings

        Threads.@threads for intx in matching

            s = get_index(mf.fwm.vars, subject(intx))
            o = get_index(mf.fwm.vars, object(intx))

            f = mf.fwm.dynamic_rules[intx](u, ps, t)
        
            if f isa Tuple{Float64, Float64}        

                du[s] += f[1] 
                du[o] += f[2]
            else

                du[s] += f 
            end
        end
    end
   
    # No matchings needed for aux rules, since they all lie on the diagonal.
    Threads.@threads for (aux_var, rule) in collect(mf.fwm.aux_dynamic_rules)

        aux_index = get_index(mf.fwm.vars, aux_var)

        f = rule(u, ps, t)
    
        if f isa Tuple{Float64, Float64}        

            error("Not meaningful for an aux_var rule to return a tuple")
        else

            du[aux_index] += f 
        end
    end
end

function SciMLBase.ODEProblem(
    fwm::FoodwebModel; 
    tspan = (0,0),
    kwargs...
    )

    f = FoodwebModelFunction(fwm)

    if (length ∘ variables)(fwm.vars) > 50 

        @info "Compiling the model code. On large models this can take a long time."
    end

    compile_function_float(fwm)

    # Setting sys = fwm here allows us to access the foodweb model from the
    # prob/sol object and do Num/Symbol indexing.
    ode_func = ODEFunction{true, SciMLBase.FullSpecialize}(f; jac = nothing, sys = fwm)

    u0 = values_inorder(fwm.vars)
    ps = values_inorder(fwm.params)

    return ODEProblem(ode_func, u0, tspan, ps; kwargs...)
end

# TODO move this into an Ext maybe? Make this conditional on having ForwardDiff,
# so this doesn't have to be a direct dependency?  Check if the individual
# solvers track deps sperately, cause in the case something like Tsit5 shouldn't
# depend on ForwardDiff and we can cut some extra dependencies.
function compile_function_dual(fwm)

    du = zeros((length ∘ variables)(fwm))
    u = rand((length ∘ variables)(fwm))
    ps = rand(1)

    Threads.@threads for rule in (collect ∘ values)(fwm.dynamic_rules)

        ForwardDiff.derivative(t -> rule(u, ps, t)[1], 1.0)
    end

    return nothing
end

function compile_function_float(fwm)

    xs = ones((length ∘ variables)(fwm.vars))
    ps = ones((length ∘ variables)(fwm.params))

    Threads.@threads for rule in (collect ∘ values)(fwm.dynamic_rules)

        rule(xs, ps, 1.0)
    end

    Threads.@threads for rule in (collect ∘ values)(fwm.aux_dynamic_rules)

        rule(xs, ps, 1.0)
    end

    return nothing
end

# TODO: This function should return variables in the order of their indices.
function ordered_variables(fwm::FoodwebModel)

    n_vars = length(variables(fwm))
    n_params = length(variables(fwm.params))

    vars = [get_variable(fwm.vars, i) for i in 1:n_vars]
    params = [get_variable(fwm.params, i) for i in 1:n_params]

    return (vars, params, time)
end

function values_inorder(vs::FoodwebVariables)::Vector{Float64}

    vals = zeros(length(vs))

    for v in variables(vs)

        vals[get_index(vs, v)] = get_value(vs, v)
    end

    return vals
end


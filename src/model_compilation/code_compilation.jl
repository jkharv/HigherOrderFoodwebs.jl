function compiled_function(fwm::FoodwebModel)

    vars, params, t = ordered_variables(fwm)

    cm = CommunityMatrix(fwm)
    rhs = [sum(x) for x in eachrow(cm)] 

    f = build_function(rhs, vars, params, t;
        expression = Val{false},
        check_bounds = true
    )

    return f[2] # 2 is the in-place version.
end

function compiled_jacobian(fwm::FoodwebModel)

    vars, params, t = ordered_variables(fwm)
    
    jac = HigherOrderFoodwebs.fwm_jacobian(fwm)

    f = build_function(jac, vars, params, t;
        expression = Val{false},
        check_bounds = true
    )

    return f[2] # 2 is the in-place version.
end

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

function SciMLBase.ODEProblem(fwm::FoodwebModel, tspan = (0,0); kwargs...)

    f = compiled_function(fwm)
    j = compiled_jacobian(fwm)

    # Setting sys = fwm here allows us to access the foodweb model from the
    # prob/sol object and do Num/Symbol indexing.
    ode_func = ODEFunction{true, SciMLBase.FullSpecialize}(f; jac = j, sys = fwm)

    u0 = values_inorder(fwm.vars)
    ps = values_inorder(fwm.params)

    return ODEProblem(ode_func, u0, tspan, ps; kwargs...)
end
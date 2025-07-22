function compiled_function(fwm::FoodwebModel)

    vars, params, t = ordered_variables(fwm)

    cm = CommunityMatrix(fwm)
    rhs = [sum(x) for x in eachrow(cm)] 

    f = Code.build_function(rhs, vars, params, t;
        expression = Val{false},
        linenumbers = false,
        iip_config = (false, true),
        parallel = Symbolics.ShardedForm{true}(80, 64)
    )

    return f
end

function compiled_jacobian(fwm::FoodwebModel)

    vars, params, t = ordered_variables(fwm)
    
    jac = HigherOrderFoodwebs.fwm_jacobian(fwm)

    f = Code.build_function(jac.m, vars, params, t;
        expression = Val{false},  
        linenumbers = false,
        iip_config = (false, true), 
        parallel = Symbolics.ShardedForm{true}(80, 64)
    )

    return f
end

function compiled_noise(fwm, g)

    vars, params, t = ordered_variables(fwm)
    
    f = Code.build_function(g, vars, params, t;
        expression = Val{false},  
        skipzeros = true, 
        linenumbers = false,
        parallel = Symbolics.SerialForm()
    )

    return f
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

function substitute_jacobian(fwm, jac, out, vars, params, t)

    vars_vals = Dict(variables(fwm) .=> vars)
    t_val = Dict(HigherOrderFoodwebs.time => t)
    param_vals = Dict(variables(fwm.params) .=> params)
    all_vals = merge(vars_vals, t_val, param_vals)

    Threads.@threads for i in eachindex(jac)

        x = substitute(jac[i], all_vals)
        out[i] = x.val
    end
end

function substitute_function(fwm, rhs, out, vars, params, t)

    vars_vals = Dict(variables(fwm) .=> vars)
    t_val = Dict(HigherOrderFoodwebs.time => t)
    param_vals = Dict(variables(fwm.params) .=> params)
    all_vals = merge(vars_vals, t_val, param_vals)

    Threads.@threads for i in eachindex(rhs)

        x = substitute(rhs[i], all_vals)
        out[i] = x.val
    end
end

function SciMLBase.ODEProblem(fwm::FoodwebModel, tspan = (0,0); 
    compile_symbolics = true, 
    compile_jacobian = false,
    kwargs...
    )

    if compile_symbolics 

        f = compiled_function(fwm)
    else
 
        cm = CommunityMatrix(fwm)
        rhs = [sum(x) for x in eachrow(cm)] 

        f(out, vars, params, t) = substitute_function(fwm, rhs, out, vars, params, t)
    end

    if compile_jacobian

        j = compiled_jacobian(fwm)
    else

        j = nothing
    end


    # Setting sys = fwm here allows us to access the foodweb model from the
    # prob/sol object and do Num/Symbol indexing.
    ode_func = ODEFunction{true, SciMLBase.FullSpecialize}(f; jac = j, sys = fwm)

    u0 = values_inorder(fwm.vars)
    ps = values_inorder(fwm.params)

    return ODEProblem(ode_func, u0, tspan, ps; kwargs...)
end

function default_noise(fwm, strength = 0.1)

    spp = variables(fwm, type = SPECIES_VARIABLE)
    not_spp = setdiff(variables(fwm), spp)

    eqs_spp = strength * spp
    eqs_not_spp = 0.0 * not_spp

    return [eqs_spp..., eqs_not_spp...]
end

function SciMLBase.SDEProblem(fwm::FoodwebModel, g = default_noise(fwm, 0.1), tspan = (0,0);
        compile_symbolics = true,
        compile_jacobian  = true,
        kwargs... 
    )
    
    if compile_symbolics 

        f = compiled_function(fwm)
        gc = compiled_noise(fwm, g) 
    else

        error("Uncompiled functions are not implemented in SDEProblem yet.")
    end

    if compile_jacobian

        j = compiled_jacobian(fwm)
    else

        j = nothing
    end

    sde_func = SDEFunction{true, SciMLBase.FullSpecialize}(f, gc; sys = fwm, jac = j)

    u0 = values_inorder(fwm.vars)
    ps = values_inorder(fwm.params)

    return SDEProblem(sde_func, u0, tspan, ps; kwargs...)
end







"""
    @functional_form node begin

        x -> a*e*x # Forwards function
        x -> a*x   # Backwards function
    end a e

The `@functional_form` macro takes care of creating a symbolic function and adding it to a
`Node` or `Vector{Node}`. It replaces the placeholder variable `x` with the variable
representing the supplied node and disambiguates the parameters being declared from 
similarily named parameters on different interactions.

If two functions are supplied as in the above example, the first function is the "forwards
function" and represents the amount of biomass addition to the subject of the interaction.
the second function is the "backwards function" which represents the amount of biomass
being removed from the object of the interaction. The difference between these two
functions is the loss from the system.

When this asymmetry is not required, you only need to define one function. In this case
both the forwards and backwards function of the node are identical. This is the case
for loops, such as growth, where deaths and growth can be collected into the same 
expression (net growth). 

    @functional_form node begin

        x -> x*r*(1 - x/k)
    end r k
"""
macro functional_form(node, ex, params...)

    # Clean up the structure a little bit.
    ex = unblock(ex)
    ex = prewalk(rmlines, ex)

    params = parse_parameter_block(params)
    fn = parse_function_block(ex)

    return quote
        
        add_func_to_nodes!($(esc(node)), $fn, $params)
    end
end

function parse_parameter_block(ex)

    ex = unblock(ex)
    ex = prewalk(rmlines, ex)

    params = []

    for p ∈ ex

        p isa Symbol  ? error("Parameter $p is used but not given any value.") :
        !(p isa Expr) ? error("Parameter $p is declared with invalid syntax.") :

        # Simple scalar parameter. eg. p
        if p.args[2] isa Symbol 
        
            param = p.args[2]
            val = DistributionOption(eval(p.args[3]))
            push!(params, (param = param, val = val, vector = false))
        end

        # Vector of parameters. eg. p[]
        if p.args[2] isa Expr

            param = p.args[2].args[1]
            val = DistributionOption(eval(p.args[3]))
            push!(params, (param = param, val = val, vector = true))   
        end
    end

    return params
end

function add_func_to_nodes!(nodes, fn, params)

    # eg. Not a Vector{Node}
    if nodes isa Node
        add_func_to_node!(nodes, fn, params)
    else
        add_func_to_node!.(nodes, Ref(fn), Ref(params))
    end
end

function create_parameter_vector(sym::Symbol, length::Int)::Vector{Num}

    syms = Vector{Symbol}()
    pars = Vector{Num}()

    # Create symbol names.
    for i in 1:length

        new_sym = Symbol(String(sym) * "_$i")
        push!(syms, new_sym)
    end

    # Make variables with those names.
    for sym in syms

        x = @variables $sym
        push!(pars, x[1])
    end

    # Tag those variables as parameters and return.
    pars = ModelingToolkit.toparam.(pars)
    return pars
end

function add_func_to_node!(node, fn, parameters)

    # Replace the placeholder var(s) with the proper one.
    if fn.index
        # Implicit multivariable case.
        # x[] -> f(x[])
        # The symbols replaced should be the _vector itself_.
        mod_func = rename_symbol(fn, fn.vars, vars(node))
    else
        # Explicit single or multivariable case.
        # x -> f(x) or (x,y,...) -> f(x,y,...)
        # The symbols replaced should be the _contents_ of the vector.
        mod_func = rename_symbols(fn, fn.vars, vars(node))
    end

    param_symbols = [p.param for p in parameters]

    if length(parameters) > 0

        new_params = disambiguate_parameters(node, parameters)
        add_parameters_to_node!(node, new_params)

        println(param_symbols)

        println("\n\n\n")
       
        println(params(node))        

        mod_func = rename_symbols(mod_func, param_symbols, params(node))



    end

    set_forwards_function!(node, eval(mod_func.ff))
    set_backwards_function!(node, eval(mod_func.bf))
end

function disambiguate_parameters(node::Node, params)

    sbj = species(subject(node.edge))[1]
    obj = species(object(node.edge))[1]

    new_params = []

    for param ∈ params

        new_param = Symbol(param.param, "_" , sbj, "_", obj)
        push!(new_params, (param = new_param, val = param.val, vector = param.vector))
    end

    return new_params
end

function add_parameters_to_node!(node::Node, params)

    # Symbolics let's you interpolate in a runtime generated Symbol, but not a
    # tuple of runtime generated Symbols like you can with compile time Symbols.
    new_params = Dict{Num, DistributionOption}()

    for p in params

        if p.vector

            nvars = length(vars(node))
            pnums = create_parameter_vector(p.param, nvars)
            pvals = [p.val for i ∈ 1:nvars]
            p = Dict(pnums .=> pvals)

            merge!(new_params, p)
        else

            pp = p.param
            param = @variables $pp
            param = ModelingToolkit.toparam(param[1])

            new_params[param] = p.val
        end
    end

    set_params!(node, new_params)
end

function parse_function_block(ex::Expr)

    ex = unblock(ex)

    if ex.head == :block
        # There's two equations in the block, 
        # it's asymmetric fowards & back.
        ff = parse_function(ex.args[1])
        bf = parse_function(ex.args[2])
    else
        # There's only one equation in the block, 
        # it's symmetric forwards & back.
        ff = parse_function(ex)
        bf = parse_function(ex)
    end

    return (ff = ff.func, bf = bf.func, vars = ff.vars, index = ff.index)
end

function parse_function(ex)

    lhs = unblock(ex.args[1])
    rhs = unblock(ex.args[2])

    if lhs isa Symbol

        # One variable case
        # x -> f(x)
        lhs = [lhs]
        return (vars = lhs, func = rhs, index = false) 
    elseif lhs.head == :tuple

        # Explicit mulivariable case
        # (x, y) = f(x,y)
        lhs = lhs.args
        return (vars = lhs, func = rhs, index = false) 
    elseif lhs.head == :ref

        # Implicit multivariable case
        # x[] -> f(x[])
        lhs = lhs.args[1]     
        return (vars = lhs, func = rhs, index = true) 
    end
end

function rename_symbols(fn, old_syms, new_syms)

    nsyms = length(old_syms)

    if nsyms != length(new_syms)

        error("The number of symbols given on the left hand side is not the same as the \
        number of species in the node.")
    end

    for i in 1:nsyms

        fn = rename_symbol(fn, old_syms[i], new_syms[i])
    end

    return fn
end

function rename_symbol(fn, old_sym, new_sym)

    ff = :()
    bf = :()

    ff = postwalk(x -> x == old_sym ? new_sym : x, fn.ff)
    bf = postwalk(x -> x == old_sym ? new_sym : x, fn.bf)
    
    return (ff = ff, bf = bf)
end
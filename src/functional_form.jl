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

When this assymetry is not required, you only need to define one function. In this case
both the forwards and backwards function of the node are identical. This is the case
for loops, such as growth, where deaths and growth can be collected into the same 
expression (net growth). 

    @functional_form node begin

        x -> x*r*(1 - x/k)
    end r k
"""
macro functional_form(node, ex, params...)

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

        if p isa Symbol 
            
            push!(params, (param = p, val = missing))
        end

        if p isa Expr
        
            param = p.args[2]            

            if p.args[3] isa Number
                val = Num(p.args[3])
            end

            if p.args[3] isa Expr 

                res = eval(p.args[3])

                if typeof(res) <: Distribution
                    val = res 
                elseif typeof(res) <: Number
                    val = Num(res)
                else
                    error("The expression for parameters must evaluate 
                           to either a Number or a Distribution.")
                end
            end

            push!(params, (param = param, val = val))
        end 
    end

    return params
end

function add_func_to_nodes!(nodes, fn, params)

    add_func_to_node!.(nodes, Ref(fn), Ref(params))
end

function add_func_to_node!(node, fn, params)

    # Replace the placeholder var with the proper one
    mod_func = rename_symbols(fn, [fn.var], [node.var])

    param_symbols = [p.param for p in params]

    if length(params) > 0

        new_params = disambiguate_parameters(node, params)
        add_parameters_to_node!(node, new_params)
        mod_func = rename_symbols(mod_func, param_symbols, node.params)
    end
    
    node.func_forwards = eval(mod_func.ff)
    node.func_backwards = eval(mod_func.bf)
end

function disambiguate_parameters(node::Node, params)

    sbj = species(subject(node.edge))
    obj = species(object(node.edge))

    new_params = []

    for param in params

        new_param = Symbol(param.param, "_" , sbj, "_", obj)
        push!(new_params, (param = new_param, val = param.val))
    end

    return new_params
end

function add_parameters_to_node!(node::Node, params)

    # Symbolics let's you interpolate in a runtime generated Symbol, but not a
    # tuple of runtime generated Symbols like you can with compile time Symbols.
    new_params = []
    vals = []

    for p in params

        # Using the @parameters macro directly caused problems.
        pp = p.param
        param = @variables $pp
        param = ModelingToolkit.toparam(param[1])

        push!(new_params, param)
        push!(vals, p.val)
    end

    node.params = new_params
    node.param_vals = vals
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

    return (ff = ff.func, bf = bf.func, var = ff.var)
end

function parse_function(ex)

    lhs = unblock(ex.args[1])
    rhs = unblock(ex.args[2])
    return (var = lhs, func = rhs) 
end
     
function rename_symbols(fn, old_syms, new_syms)

    nsyms = length(old_syms)

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
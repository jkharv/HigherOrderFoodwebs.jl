# specification for the function that will be assigned to a node and actually creating
# that function and all of its parameters.

function create_node_function!(node::Node, fn::FunctionTemplate)

    create_replacement_symbols!(node, fn)
    fnf, fnb = replace_symbols(fn)

    set_forwards_function!(node, eval(fnf))  
    set_backwards_function!(node, eval(fnb))
end

function create_node_function!(nodes::Vector{Node}, fn::FunctionTemplate)

    create_node_function!.(nodes, Ref(fn))
end

function replace_symbols(fn::FunctionTemplate)

    # create a rename dict with bare symbols as keys

    k = collect(keys(fn.objects))
    k = map(x -> x.sym, k)
    v = collect(values(fn.objects))
    rename_dict = Dict(k .=> v)

    function f(sym)

        if sym ∈ keys(rename_dict)
            return rename_dict[sym]
        else
            return sym
        end
    end

    ff = postwalk(f, fn.forwards_function)
    bf = postwalk(f, fn.backwards_function)
    
    return (ff = ff, bf = bf)
end

function create_replacement_symbols!(node::Node, fn::FunctionTemplate)

    for key in keys(fn.objects)

        fn.objects[key] = create_replacement_symbol(node, key)
    end
end

function create_replacement_symbol(node::Node, sym::TemplateScalarVariable)::Num

    var = collect(keys(node.func.vars))

    length(var) > 1 ? error("Must use multivariable function on multivariable node") :

    return var[1]
end

function create_replacement_symbol(node::Node, sym::TemplateScalarParameter)::Num

    new_param = disambiguate_symbol(node, sym.sym)
    new_param = create_param(new_param)
    set_param!(node, new_param => sym.val)

    return new_param
end

function create_replacement_symbol(node::Node, sym::TemplateVectorParameter)::Vector{Num}

    nvars = length(node.func.vars)
    params = Vector{Num}(undef, nvars)

    for i in 1:nvars

        new_param = Symbol(disambiguate_symbol(node, sym.sym), "_$i")
        new_param = create_param(new_param)
        set_param!(node, new_param => sym.val)
        params[i] = new_param
    end

    return params 
end

function create_replacement_symbol(node::Node, sym::TemplateVectorVariable)::Vector{Num}

    var = collect(keys(node.func.vars))
    return var
end

function disambiguate_symbol(node::Node, sym::Symbol)::Symbol

    sbj = species(subject(node.edge))[1]
    obj = species(object(node.edge))[1]

    return Symbol(sym, "_" , sbj, "_", obj)
end

function create_var(sym::Symbol)::Num

    x = @variables $sym
    
    return x[1]
end

function create_param(sym::Symbol)::Num

    x = @variables $sym
    param = ModelingToolkit.toparam.(x[1])
    
    return param
end
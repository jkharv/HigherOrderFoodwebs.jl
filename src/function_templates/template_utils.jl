function create_variable(sym::Symbol)::Num

    x = @variables $sym
   
    return x[1]
end

function create_variable(dep::Symbol, indep::Num)::Num

    x = @variables $dep(indep)
   
    return x[1]
end

function create_param(sym::Symbol)::Num

    x = @variables $sym
    param = ModelingToolkit.toparam.(x[1])
    
    return param
end

function get_variables(fwm::FoodwebModel, spp::Vector{Symbol})

    return [fwm.vars[sp] for sp ∈ spp]
end

function DynamicalRule(tmplt::FunctionTemplate)

    tmplt = apply_template(tmplt)

    ff = eval(tmplt.forwards_function)
    bf = eval(tmplt.backwards_function)

    f = collect ∘ Iterators.flatten ∘ values ∘ filter
    vars = f(kv -> kv[1] isa TemplateVariable, tmplt.objects)
    params = f(kv -> kv[1] isa TemplateParameter, tmplt.objects)


    return DynamicalRule(ff, bf, vars, params)
end

function Base.show(io::IO, ::MIME"text/plain", f::FunctionTemplate)

    fs = f.forwards_function.args[1]
    bs = f.backwards_function.args[1]

    println(io, "Forwards function:  " * string(fs))    
    println(io, "Backwards Function: " * string(bs))    
    println(io, "Template Symbols:")

    for s in f.objects

        o = first(s)
        sym = string(o.sym)
        val = string(o.val)

        type = o isa TemplateParameter ? "Parameter " : "Variable  "

        println(io, "  "  * type * sym * " ~ " * val * " => " * string(last(s)))
    end
end
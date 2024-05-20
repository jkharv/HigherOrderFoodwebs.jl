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

function apply_template(tmplt::FunctionTemplate, sym::Symbol, var::Union{Num, Vector{Num}})

    ff = postwalk(x -> x==sym ? var : x, tmplt.forwards_function)
    bf = postwalk(x -> x==sym ? var : x, tmplt.backwards_function)

    fn = FunctionTemplate(ff, bf, tmplt.cannonical_vars, tmplt.objects)

    for i ∈ tmplt.objects

        if first(i).sym == sym
            delete!(fn.objects, first(i))
        end
    end

    return fn
end

function apply_template(tmplt::FunctionTemplate)

    fn = FunctionTemplate(tmplt.forwards_function, 
                          tmplt.backwards_function,
                          tmplt.cannonical_vars, Dict())
    
    for o ∈ tmplt.objects

        if ismissing(last(o))

            error("""Could not apply the template, Some variables or parameters\
                     were not proberly defined""")
        end

        fn = apply_template(fn, first(o).sym, last(o))
    end

    return fn
end

function apply_template!(tmplt::FunctionTemplate)

    tmplt = apply_template(tmplt)
end

# Go through the template a produce unambiguous symbols and 
# `Num`s to go with the parameters.
function create_unambiguous_parameters!(tmplt::FunctionTemplate, fwm::FoodwebModel)
   
    for p ∈ tmplt.objects

        if first(p) isa TemplateParameter

            sym = string(first(p).sym)
            # Concat var names and gensym to disambiguate
            sym = join([sym, tmplt.cannonical_vars...], "_")   
            sym = gensym(sym)

            # Create param and register in the FoodwebModel param list.
            push!(fwm.params, create_param(sym))
            push!(fwm.param_vals,  fwm.params[end] => first(p).val)

            tmplt.objects[first(p)] = fwm.params[end]
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", f::FunctionTemplate)

    fs = f.forwards_function.args[1]
    bs = f.backwards_function.args[1]

    println(io, "Forwards function:  " * string(fs))    
    println(io, "Backwards Function: " * string(bs))    
    println(io, "Canonical Variables: " * string(f.cannonical_vars))
    println(io, "Template Symbols:")

    for s in f.objects

        o = first(s)
        sym = string(o.sym)
        val = string(o.val)

        type = o isa TemplateParameter ? "Parameter " : "Variable  "

        println(io, "  "  * type * sym * " ~ " * val * " => " * string(last(s)))
    end
end
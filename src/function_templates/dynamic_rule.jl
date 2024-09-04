macro group(fwm, spp, func, params...)
    
    # Clean up the AST a little bit.  Not doing this breaks the parsing code
    # currently. TODO fix up the parsing code, make it more resillient, so we
    # don't need to do this.
    func = prewalk(rmlines, func)
    func = unblock(func)
    
    vars = parse_variables(func)

    fn = parse_function(func)
    fn = FunctionTemplate(fn.ff, fn.bf, [], vars)

    # Minor thing, but `create_unambiguous_parameters` used to use the
    # `cannonical_vars` field in the template to give unabiguous parameter names
    # which refer to the interaction they belong to. They're `gensym`ed so it it
    # doesn't pose a technical problem but it would be sorta nice. This got
    # broken cause I realized `eval(spp)` at compile time only works for the
    # trivial cause of giving a strait up vec of symbols; otherwise compile time
    # eval doesn't really work.
   
    parameters = _params(fwm, spp, params...)
    functions = :(_group($(esc(fwm)), $(esc(spp)), $fn))
    
    return Expr(:call, +, unblock(parameters), unblock(functions))
end

function _group(fwm, spp, tmplt)

    new_tmplt = FunctionTemplate(
        tmplt.forwards_function,
        tmplt.backwards_function, 
        tmplt.canonical_vars,
        Vector{TemplateObject}()
    )

    for o in tmplt.objects

        if ismissing(o.num)
         
            num = create_runtime_symbol(o, spp, fwm)
            new_o = (typeof(o))(o.sym, o.val, num)
            push!(new_tmplt.objects, new_o)
        else
            push!(new_tmplt.objects, o)
        end
    end

    return new_tmplt
end

function _param(fwm, spp, param::Expr)::Expr

    MacroTools.postwalk(param) do x

        MacroTools.@capture(x, a_Symbol ~ b_) || return x
        
        p = TemplateScalarParameter(a, missing, missing)
        return quote
            
            FunctionTemplate(:(0+0),:(0+0), [], 
                [create_runtime_parameter($p.sym, $(esc(b)), $(esc(spp)), $(esc(fwm)))]
            )
        end
    end 
end

# Temp hack, until I pretty much rewrite the function template code.
function create_runtime_parameter(sym, val, spp, fwm)

    # Make it unambigous
    new_sym = (gensym ∘ join)([sym, spp...], "_" )

    # Create the parameter and add it to the FoodwebModel.
    param = create_param(new_sym)
    push!(fwm.params, param)
    push!(fwm.param_vals, param => val)

    return TemplateScalarParameter(sym, val, param)
end


function _params(fwm, spp, params...)

    p = (unblock ∘ _param).(Ref(fwm), Ref(spp), params)

    e_acc = FunctionTemplate(:(0+0),:(0+0), [], [])
    for e ∈ p

        e_acc = Expr(:call, +, e, e_acc)
    end
    return e_acc
end

macro params(params...)

    if isempty(params)
        return nothing
    end

    return _params(params...) 
end

macro set_aux_rule(fwm, sym, ex)

    return quote

        $(esc(fwm)).aux_dynamic_rules[$(esc(sym))] = DynamicalRule($(esc(ex)))
    end
end

macro set_rule(fwm, interaction, ex)

    return quote

        $(esc(fwm)).dynamic_rules[$(esc(interaction))] = DynamicalRule($(esc(ex)))
    end
end
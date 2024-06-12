macro group(fwm, interaction, spp, func, params...)
    
    # Clean up the AST a little bit.  Not doing this breaks the parsing code
    # currently. TODO fix up the parsing code, make it more resillient, so we
    # don't need to do this.
    func = prewalk(rmlines, func)
    func = unblock(func)
    
    vars = parse_variables(func)
    params = parse_parameters(params)

    fn = parse_function(func)
    fn = FunctionTemplate(fn.ff, fn.bf, [], merge!(vars, params))

    # Minor thing, but `create_unambiguous_parameters` used to use the
    # `cannonical_vars` field in the template to give unabiguous parameter names
    # which refer to the interaction they belong to. They're `gensym`ed so it it
    # doesn't pose a technical problem but it would be sorta nice. This got
    # broken cause I realized `eval(spp)` at compile time only works for the
    # trivial cause of giving a strait up vec of symbols; otherwise compile time
    # eval doesn't really work.
    
    return quote

        placeholder_fn_name($(esc(fwm)), $(esc(interaction)), $(esc(spp)), $fn)
    end
end

function placeholder_fn_name(fwm, interaction, spp, tmplt)

    @assert spp ⊆ species(fwm)
    @assert spp ⊆ species(interaction)

    new_tmplt = deepcopy(tmplt)

    for o in new_tmplt.objects

        if ismissing(last(o))
           
            new_tmplt.objects[first(o)] = create_runtime_symbol(first(o), spp, fwm)
        end
    end

    return new_tmplt
end

macro set_rule(fwm, interaction, ex)

    return quote

        $(esc(fwm)).dynamic_rules[$(esc(interaction))] = DynamicalRule($(esc(ex)))
    end
end
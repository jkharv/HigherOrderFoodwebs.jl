function function_generator(rename_dict::Dict, fbody)::Expr

    fsym = gensym(:dynamic_rule)

    fbody = prewalk(fbody) do x

        if x ∈ keys(rename_dict)

            sym = first(rename_dict[x]) # u or ps
            index = last(rename_dict[x])
            return :($sym[$index])
        else
            return x
        end
    end

    return :( 
        function $fsym(u, ps, t)

            $fbody
        end
    )
end

function get_index_expr(fwm, rename_dict, variable_syms, isparameter, ex)

    @assert ex.head == Symbol("=")

    lhs = ex.args[1]
    rhs = ex.args[2]

    if isparameter

        index = :(get_index($fwm.params, $rhs))
        sym = Meta.quot(:ps)
    else

        index = :(get_index(fwm.vars, $rhs))
        sym = Meta.quot(:u)
    end
    
    replacement_sym = (Meta.quot ∘ Symbol)(lhs)

    return quote

        z = $rhs
        if z isa Vector{Symbol}
            append!($variable_syms, $rhs)
        else
            push!($variable_syms, $rhs)
        end

        $rename_dict[$replacement_sym] = ($sym, $index)
    end
end

function rule(fwm, intx, body)

    macrocalls = Expr(:block) 
    notmacrocalls = Expr(:block)

    rename_dict = gensym(:rename_dict)
    variable_syms = gensym(:variable_syms) 

    for line in body.args

        if (line isa LineNumberNode)

            continue
        end

        if !(line.head == :macrocall)

            push!(notmacrocalls.args, line)
            continue
        end

        macroname = line.args[1]
 
        if macroname == Symbol("@var")

            push!(macrocalls.args, 
                get_index_expr(fwm, rename_dict, variable_syms, false, line.args[end])
            )
        elseif macroname == Symbol("@param")

            push!(macrocalls.args, 
                get_index_expr(fwm, rename_dict, variable_syms, true, line.args[end])
            )
        end
    end

    notmacrocalls = Meta.quot(notmacrocalls)

    return quote

        $rename_dict = Dict{Symbol, Tuple{Symbol, Union{Int64, Vector{Int64}}}}()
        $variable_syms = Vector{Symbol}()
        $macrocalls

        # TODO replace this direct field access with a setter function that
        # dispatch to either fwm.dynamic_rules or fwm.aux_dynamic_rules based on
        # type.
        set_dynamic_rule!(
            $fwm, 
            $intx,
            DynamicRule(
                HigherOrderFoodwebs.function_generator($rename_dict, $notmacrocalls),
                $variable_syms,
                @__MODULE__() 
            )
        )
    end
end

# No for loop
# @rule fwm intx begin
#   ...
# end
macro rule(fwm, intx, body)

    out = rule(fwm, intx, body)

    return quote
        
        $out
    end
end

# for loop
# @rule fwm for intx in interactions(fwm)
#   ...
# end
macro rule(fwm, body)

    loop_head = body.args[1]
    loop_var  = loop_head.args[1]

    loop_body = body.args[2]
    loop_body = rule(fwm, loop_var, loop_body)

    out_loop = Expr(:for)
    append!(out_loop.args, [loop_head, loop_body])

    return quote
        $(esc(out_loop))
    end
end

# The dispatch is all done in @rule so the only time these get
# called is if a user tries to call this outside of a @rule
# This is purely here to provide a helpful error message.
macro var(ex...)

    error("@var is only valid withing a @rule block")
end

# The dispatch is all done in @rule so the only time these get
# called is if a user tries to call this outside of a @rule
# This is purely here to provide a helpful error message.
macro param(ex...)

    error("@param is only valid withing a @rule block")
end
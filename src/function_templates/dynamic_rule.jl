function with_role(rl::Symbol, int::AnnotatedHyperedge{T, U})::Vector{Symbol} where {T<:Any, U<:Any}

    spp = AnnotatedHypergraphs.species(int)
    filter(x-> has_role(x, int, rl), spp)
end

macro group(spp, func, params...)

    # Clean up the AST a little bit.
    func = prewalk(rmlines, func)
    func = unblock(func)

    group_macro(spp, func, params...)
end

function group_macro(spp, func, params...)::Expr

    vars = parse_variables(func)
    params = parse_parameters(params)

    spp = eval(spp)
    spp_nums = create_variable.(spp)

    


    fn = parse_function(func)
    fn = FunctionTemplate(fn.ff, fn.bf, spp, merge!(vars, params))

    




    return quote

        $fn
    end
end

macro dynamical_rule(blocks...)

    # Clean up the AST a little bit.
    blocks = prewalk.(rmlines, blocks)
    
    blocks
end

# Create test hypergraph
spp = Unipartite([:s1, :s2, :s3, :s4])
i1 = AnnotatedHyperedge([:s1, :s2, :s3], [:subject, :object, :modifier], true)
i2 = AnnotatedHyperedge([:s1, :s2, :s3], [:subject, :modifier, :object], true)
i3 = AnnotatedHyperedge([:s1, :s2, :s3], [:subject, :modifier, :object], true)
hg = SpeciesInteractionNetwork(spp, [i1, i2, i3])
fwm = FoodwebModel(hg)
tmplt = @group [:s1,:s2,:s3] begin
    
        x[] -> a*b*sum(x[1:end])
end a ~ 1 b ~ 2
vs = filter(x -> first(x) ∈ tmplt.cannonical_vars, fwm.vars)
vs = collect(values(vs))
x = first(first(tmplt.objects) )
tmplt.objects[x] = create_variable.(tmplt.cannonical_vars)
create_unambiguous_parameters!(tmplt, fwm)


tmplt
apply_template!(tmplt)
eval(x.forwards_function)
function sp_to_var(hg::EcologicalHypergraph, s::String)

    x = findfirst(x -> subject(x).species[1] == s, interactions(hg))
    spp = subject(interactions(hg)[x])
    var = collect(keys(vars(spp)))[1]

    return var
end

function var_to_sp(hg::EcologicalHypergraph, v::Num)

    filt = filter(x -> v ∈ keys(vars(x)), nodes(hg))
    filt = filter(x -> length(vars(x)) > 0, filt)

    if length(filt) == 0 

        error("Couldn't find the species for that variable");
    end

    sp = first(species(filt[1]))

    return  sp
end
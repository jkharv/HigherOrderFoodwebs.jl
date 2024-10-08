using HigherOrderFoodwebs
using SpeciesInteractionNetworks
using ModelingToolkit
using Distributions
using DifferentialEquations

hg  = (optimal_foraging ∘ nichemodel)(20, 0.2);
fwm = FoodwebModel(hg);

# Useful shorthand for later
HigherOrderFoodwebs.isproducer(x) = isproducer(fwm, x) 
HigherOrderFoodwebs.isconsumer(x) = isconsumer(fwm, x)

growth = filter(isloop, interactions(fwm));
trophic = filter(!isloop, interactions(fwm));

producer_growth = filter(isproducer ∘ subject, growth)
consumer_growth = filter(isconsumer ∘ subject, growth)

# Not actually a community matrix, but we'll use it 
# because it has species-based indexing.
atk_rates = CommunityMatrix(
    zeros(Num, length(species(fwm)), length(species(fwm))),
    species(fwm)
)

atk_rates_syms = CommunityMatrix(
    Matrix{Union{Missing,Symbol}}(missing, length(species(fwm)), length(species(fwm))),
    species(fwm)
)

for i ∈ trophic

    s = subject(i)
    o = object(i)

    sym = Symbol("a_$(s)_$(o)")
    add_var!(fwm, sym, fwm.t)
    atk_rates[s, o] = fwm.aux_vars[sym]
    atk_rates_syms[s, o] = sym
end

for i ∈ producer_growth

    s = fwm.vars[subject(i)]
    k = add_param!(fwm, :k, [subject(i)], 1.0 + rand()/10)

    dr = DynamicRule(s * (1.0 - (s / k)))
    fwm.dynamic_rules[i] = dr
end

for i ∈ consumer_growth

    s = fwm.vars[subject(i)]
    m = add_param!(fwm, :m, [subject(i)], 0.2)

    dr = DynamicRule(-s * m)
    fwm.dynamic_rules[i] = dr
end

for i ∈ trophic

    s = fwm.vars[subject(i)]
    o = fwm.vars[object(i)]
    m = with_role(:AF_modifier, i)
    m = [fwm.vars[x] for x in m]

    a_so_sym = atk_rates_syms[subject(i), object(i)]
    a_so = atk_rates[subject(i), object(i)]
    as   = [atk_rates[subject(i), x] for x in species(fwm)]
    as   = filter(!iszero, as) 

    set_initial_condition!(fwm, Dict(a_so_sym => 0.6))

    e = add_param!(fwm, :e, [subject(i), object(i)], 0.15)

    if length(m) > 0
        
        mean_gain = mean([o, m...] .* as)
        
        fwm.aux_dynamic_rules[a_so_sym] = DynamicRule(
            0.001 * (a_so * s * o) - mean_gain * a_so * (1 - a_so)
        )
    else

        fwm.aux_dynamic_rules[a_so_sym] = DynamicRule(Num(0))
    end

    fwm.dynamic_rules[i] = DynamicRule(
         s * o * a_so * e,
        -s * o * a_so
    )
end

solver = assemble_foodweb(fwm);

sol = solve(solver, RK4();
    force_dtmin = true,
    maxiters = 1e7,
    abstol = 0.01,
    reltol = 0.01,
    tspan = (1, 1000)
);

sol[end]
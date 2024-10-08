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

for i ∈ trophic

    s = subject(i)
    o = object(i)

    sym = Symbol("a_$(s)_$(o)")
    add_var!(fwm, sym)
    atk_rates[s, o] = fwm.aux_vars[sym]
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



    e = add_param!(fwm, :e, [subject(i), object(i)], 0.15)

    dr = DynamicRule(
         s * o * e,
        -s * o
    )
    
    fwm.dynamic_rules[i] = dr
end

solver = assemble_foodweb(fwm);

sol = solve(solver, RK4();
    force_dtmin = true,
    abstol = 0.01,
    reltol = 0.01,
    tspan = (1, 5000)
);

sol[end]
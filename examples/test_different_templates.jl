using Revise
using HigherOrderFoodwebs
using SpeciesInteractionNetworks
using ModelingToolkit
using Distributions
using DifferentialEquations
using Plots

hg  = (optimal_foraging ∘ nichemodel)(20, 0.2);
fwm = FoodwebModel(hg);

# Useful shorthand for later
HigherOrderFoodwebs.isproducer(x) = isproducer(fwm, x) 
HigherOrderFoodwebs.isconsumer(x) = isconsumer(fwm, x)

growth = filter(isloop, interactions(fwm));
trophic = filter(!isloop, interactions(fwm));

producer_growth = filter(isproducer ∘ subject, growth)
consumer_growth = filter(isconsumer ∘ subject, growth)

for i ∈ producer_growth

    s = fwm.vars[subject(i)]
    k = add_param!(fwm, :k, [subject(i)], 1.0)

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

u0 = Dict(species(fwm) .=> rand(Uniform(0.5, 1.0), length(species(fwm))));
set_initial_condition!(fwm, u0)

et = ExtinctionThresholdCallback(fwm, 1e-20, Vector{Tuple{Float64, Symbol}});

sol = solve(fwm, RK4();
    force_dtmin = true,
    abstol = 1e-5,
    reltol = 1e-3,
    tspan = (1, 1000)
);

plot(sol, legend = false)
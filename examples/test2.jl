using DifferentialEquations
using HigherOrderFoodwebs
using SpeciesInteractionNetworks
using Random
using Statistics
using ModelingToolkit
using DataFrames
using SymbolicIndexingInterface
using FoodwebPlots
import GLMakie

# --------------------------------------- #
# Draw a random structure for the foodweb #
# --------------------------------------- #

fwm = (FoodwebModel ∘ optimal_foraging ∘ nichemodel)(10, 0.3)

# -------------------------------------- #
# Generate some species-level parameters #
# -------------------------------------- #

traits = DataFrame(:species => species(fwm))

traits.vulnerability = vulnerability.(Ref(fwm.hg), traits.species);
traits.generality = generality.(Ref(fwm.hg), traits.species);
traits.trophic_level = distancetobase.(Ref(fwm.hg), traits.species, mean);

f_mass(tl) = tl == 1.0 ? 1.0 : 100^(tl - 1);
traits.body_mass = f_mass.(traits.trophic_level);

traits.metabolic_rate    = add_param!.(Ref(fwm), :x, traits.species, 0.5);
traits.growth_rate       = add_param!.(Ref(fwm), :r, traits.species, 1.0);
traits.carrying_capacity = add_param!.(Ref(fwm), :k, traits.species, 1.0);
traits.max_consumption   = add_param!.(Ref(fwm), :y, traits.species, 6.0);
traits.adaptation_rate   = add_param!.(Ref(fwm), :g, traits.species, 0.025);

# --------------------------------------------------------- #
# Subset the interactions for different parts of the model. #
# --------------------------------------------------------- #

growth = filter(isloop, interactions(fwm));

isprod(x) = isproducer(fwm, x);
iscons(x) = isconsumer(fwm, x);

producer_growth = filter(isprod ∘ subject, growth);
consumer_growth = filter(iscons ∘ subject, growth);
trophic = filter(!isloop, interactions(fwm));

# ----------------------------------------------------------------------- #
# Set up a matrix to keep track of the attack rates for each interaction. #
# ----------------------------------------------------------------------- #

# Not actually a community matrix, but we'll use it anyway cause it has
# species-based indexing.
atk_rates = CommunityMatrix(
    zeros(Num, length(species(fwm)), length(species(fwm))),
    species(fwm)
);

for i ∈ trophic

    s = subject(i)
    o = object(i)

    v = add_var!(fwm, Symbol("a_$(s)_$(o)"), fwm.t)
    atk_rates[s, o] = v 
end

# ----------------------------------------- #
# Set up the dynamical aspects of the model #
# ----------------------------------------- #

for i ∈ producer_growth

    sbj = subject(i)
    s = fwm.conversion_dict[sbj]

    r = traits[traits.species .== sbj, :growth_rate][1]
    k = traits[traits.species .== sbj, :carrying_capacity][1]
    x = traits[traits.species .== sbj, :metabolic_rate][1]

    fwm.dynamic_rules[i] = DynamicRule(logistic(s, r, k))
end

for i ∈ consumer_growth

    sbj = subject(i)
    s = fwm.conversion_dict[sbj]

    x = traits[traits.species .== sbj, :metabolic_rate][1]

    fwm.dynamic_rules[i] = DynamicRule(-x * s)
end

F(Bj, B, ar, b0) = Bj / (b0 + sum(ar .* B))

for i ∈ trophic

    s = fwm.conversion_dict[subject(i)]
    o = fwm.conversion_dict[object(i)]
    af_m = [fwm.conversion_dict[x] for x in with_role(:AF_modifier, i)]
    r = [o, af_m...]

    x = traits[traits.species .== subject(i), :metabolic_rate][1]
    y = traits[traits.species .== subject(i), :max_consumption][1]
    g = traits[traits.species .== subject(i), :adaptation_rate][1]
    a = atk_rates[subject(i), object(i)]
    ar = [atk_rates[subject(i), x] for x in with_role(:AF_modifier, i)]
    ar = [a, ar...] 

    object_gain = x * y * a * F(o, r, a, 1.0)
    mean_gain = mean(x * y * ar .* F.(r, Ref(r), Ref(ar), Ref(1.0)))
    fwm.aux_dynamic_rules[a] = DynamicRule( 
        g * a * (1 - a) * (object_gain - mean_gain)
    )
    set_u0!(fwm, a,  1.0 / length(r))

    ar_norm = a ./ sum(ar) 
    a_norm = ar[1]

    fwd = a_norm * x * y * F(o, r, ar_norm, 1.0) * s
    bwd = -fwd

    fwm.dynamic_rules[i] = DynamicRule(fwd, bwd)
end

# ---------------------- #
#  Simulate the foodweb  #
# ---------------------- #

using FoodwebPlots
using GLMakie

foodwebplot(fwm)




solver = assemble_foodweb(fwm, Rosenbrock23())

et = ExtinctionThresholdCallback(fwm, 1e-20);
es = ExtinctionSequenceCallback(fwm, shuffle(species(fwm)), 100.0);

@time sol = solve(solver, Rosenbrock23();
    callback = CallbackSet(et,es),
    maxiters = 1e7,
    force_dtmin = true,
    saveat = collect(1:0.1:1000),
    tspan = (1, 1000)
);

for i in trophic
    println(HigherOrderFoodwebs.trophic_flux(fwm, sol, i, 100.0))
end

# f = GLMakie.Figure()
empty!(f)
ax = GLMakie.Axis(f[1,1], ylabel = "Biomass", xlabel = "Timestep")
GLMakie.ylims!(ax, (-0.1,1.1))
for sp in species(fwm)

    GLMakie.lines!(ax, sol.t, sol[sp])
end

empty!(f)
ax = GLMakie.Axis(f[1,1], ylabel = "Attack Rate", xlabel = "Timestep")
GLMakie.ylims!(ax, (-0.1,1.1))
for a in (collect ∘ values)(fwm.aux_vars)

    GLMakie.lines!(ax, sol.t, sol[a])
end
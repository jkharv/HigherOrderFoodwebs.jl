using Revise
using OrdinaryDiffEq
using ModelingToolkit
using EcologicalNetworks
using EcologicalHypergraphs
using Plots

#----------------------------------------
# Creating a foodweb and hypergraph
#----------------------------------------

web = nichemodel(15, 0.2)
hg = EcologicalHypergraph(web)

tl = trophic_level(web)
producer_filter = x -> subject_is_producer(x, tl)
consumer_filter = x -> subject_is_consumer(x, tl)

# Make groups of interactions.
producer_growth = filter(x -> isloop(x) & producer_filter(x), interactions(hg))
consumer_growth = filter(x -> isloop(x) & consumer_filter(x), interactions(hg))
trophic = filter(!isloop, interactions(hg))

#----------------------------------------
# Basic foodweb model
#----------------------------------------

# Growth function for producers
@functional_form subject.(producer_growth) begin
    
    x -> r*x*(1 - x/k)
end r ~ Normal(0.8, 0.25) k ~ Uniform(0.1, 10.0) 

# Growth function for consumers
@functional_form subject.(consumer_growth) begin
    
    x -> r * x
end r ~ Uniform(-0.2, -0.05)

# Trophic interaction function pt.1
@functional_form subject.(trophic) begin

    x -> a*e*x
    x -> -a*x
end a ~ Normal(0.7, 0.25) e ~ Normal(0.1, 0.15)

# Trophic interaction function pt.2
@functional_form object.(trophic) begin
    
    x -> x
end

#---------------------------------------- 
# Add some modifiers
#----------------------------------------

# Nothing is being modified right now.
interactions(hg)

# Add some modifiers
mods = optimal_foraging!(hg)

# Now there's lots of modifiers
interactions(hg)

# Add the modifier functions
@functional_form mods begin
   
    x -> 1/(1+(x/m)^2)
    
end m ~ Uniform(0.75, 1.0)

#---------------------------------------- 
# Do something with the hypergraph
#----------------------------------------

# Turn our hypergraph into a numerical ODE system.
sys = build_numerical_system(hg, (0,500))

# Hand it over to an ODE solver
sol = solve(sys, Tsit5())

# Plot the solution.
plot(sol, legend = false)
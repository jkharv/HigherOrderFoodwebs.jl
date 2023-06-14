using Revise
using OrdinaryDiffEq
using ModelingToolkit
using EcologicalNetworks
using EcologicalHypergraphs
using Plots

#----------------------------------------
# Creating a foodweb and hypergraph
#----------------------------------------

web = nichemodel(15, 0.2);
hg = EcologicalHypergraph(web);

tl = trophic_level(web);
producer_filter = x -> subject_is_producer(x, tl);
consumer_filter = x -> subject_is_consumer(x, tl);

# Make groups of interactions.
producer_growth = filter(x -> isloop(x) & producer_filter(x), interactions(hg));
consumer_growth = filter(x -> isloop(x) & consumer_filter(x), interactions(hg));
trophic = filter(!isloop, interactions(hg));

#----------------------------------------
# Basic foodweb model
#----------------------------------------

# Growth function for producers
@functional_form subject.(producer_growth) begin
    
    x -> r*x*(1 - x/k)
end r ~ Normal(0.8, 0.25) k ~ Uniform(0.1, 10.0);

# Growth function for consumers
@functional_form subject.(consumer_growth) begin
    
    x -> r * x
end r ~ Uniform(-0.2, -0.05);

# Trophic interaction function pt.1
@functional_form subject.(trophic) begin

    x -> a*e*x
    x -> -a*x
end a ~ Normal(0.7, 0.25) e ~ Normal(0.1, 0.15);

# Trophic interaction function pt.2
@functional_form object.(trophic) begin
    
    x -> x
end;

#---------------------------------------- 
# Add some modifiers
#----------------------------------------

# Add some modifiers
mods = optimal_foraging!(hg);

# Add the modifier functions
@functional_form mods begin
   
    x[] ->  (p[1] * x[1]) / sum(p[1:end] .* x[1:end])

end p[] ~ Uniform(0.2, 0.3);

#---------------------------------------- 
# Do something with the hypergraph
#----------------------------------------

# Turn our hypergraph into a numerical ODE system.
sys = ODESystem(hg);
num_sys = ODEProblem(sys, get_var_dict(hg), (0, 500), get_param_dict(hg));

# Hand it over to an ODE solver
sol = solve(num_sys, Tsit5());

# Plot the solution.
plot(sol, legend = false)
using Revise
using OrdinaryDiffEq
using ModelingToolkit
using EcologicalNetworks 
using EcologicalHypergraphs
using Plots

web = nichemodel(20, 0.2)
hg = EcologicalHypergraph(web)

tl = trophic_level(web)

producers = collect(keys(filter(x -> last(x) == 1.0, tl)))
consumers = collect(keys(filter(x -> last(x) > 1.0, tl)))
loops = filter(isloop, hg.edges)

producer_growth = filter(x -> EcologicalHypergraphs.contains(x, producers, [:subject]), loops)
consumer_growth = filter(x -> EcologicalHypergraphs.contains(x, consumers, [:subject]), loops)

trophic = filter(!isloop, hg.edges)

#----------------------------------------
# Basic foodweb model
#----------------------------------------

@functional_form test_node begin
    
    (x, y) -> r*x*(1 - y/k)
end r ~ Normal(0.7, 0.25) k ~ Uniform(0.5, 10.0) 

@functional_form subject.(consumer_growth) begin
    
    x -> r * x
end r ~ Uniform(-0.2, -0.05)

@functional_form subject.(trophic) begin

    x -> a*e*x
    x -> -a*x
end a ~ Normal(0.7, 0.25) e ~ Normal(0.1, 0.15)

@functional_form object.(trophic) begin
    
    x -> x
end

#---------------------------------------- 
# Add some modifiers
#----------------------------------------

# mods = add_modifier!.(rand(hg.edges, 40), rand(species(hg), 40))
# mods = first.(modifiers.(mods))

# @functional_form mods begin
   
#     x -> 1/x*m
    
# end m ~ Normal(0.5, 0.2)

# #---------------------------------------- 
# # Do something with the hypergraph
# #----------------------------------------

sys = build_numerical_system(hg, (0,500))
sol = solve(sys, Tsit5())
plot(sol)
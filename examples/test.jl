using DifferentialEquations
using Plots

web = nichemodel(20, 0.2)

hg = EcologicalHypergraph(web)

tl = trophic_level(web)

producers = collect(keys(filter(x -> last(x) == 1.0, tl)))
consumers = collect(keys(filter(x -> last(x) > 1.0, tl)))
loops = filter(isloop, hg.edges)

producer_growth = filter(x -> contains(x, producers, [:subject]), loops)
consumer_growth = filter(x -> contains(x, consumers, [:subject]), loops)

trophic = filter(!isloop, hg.edges)

#----------------------------------------
# Basic foodweb model
#----------------------------------------

@functional_form subject.(producer_growth) begin
    
    x -> r*x*(1-x/k)
end r k

@functional_form subject.(consumer_growth) begin
    
    x -> -r * x
end r

@functional_form subject.(trophic) begin

    x -> a*e*x
    x -> -a*x
end a e

@functional_form object.(trophic) begin
    
    x -> x
end

#---------------------------------------- 
# Add some modifiers
#----------------------------------------

mods = add_modifier!.(rand(hg.edges, 8), rand(species(hg), 8))
mods = first.(modifiers.(mods))

@functional_form mods begin
   
    x -> exp(m)*100*sin(x + m)
    
end m

#---------------------------------------- 
# Do something with the hypergraph
#----------------------------------------

cm = community_matrix(hg)

sys = build_system(hg)

vars = convert(Vector{Symbol}, sys.states)
vars = Dict(vars .=> rand(length(vars)))

params = convert(Vector{Symbol}, sys.ps)
params = Dict(params .=> rand(length(params)))

prob = ODEProblem(sys, vars, [0, 1000], params)

sol = solve(prob, Tsit5())

plot(sol)
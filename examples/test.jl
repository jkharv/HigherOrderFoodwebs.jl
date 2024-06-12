using Revise
using HigherOrderFoodwebs
using AnnotatedHypergraphs
using Distributions
using DifferentialEquations
using Plots

hg  = nichemodel(20, 0.2)
fwm = FoodwebModel(hg)

self_loops = filter(isloop, interactions(fwm))
trophic = filter(!isloop, interactions(fwm))

for intrx ∈ self_loops 

    tmplt = @group fwm intrx species(intrx) begin
        
        x -> r * x * (1 - x) / k
    end r ~ 0.2 k ~ 10

    @set_rule fwm intrx begin
        
        tmplt
    end
end 

for intrx ∈ trophic

    sbj = @group fwm intrx with_role(:subject, intrx) begin

        x -> x * a * e
        x -> -x * a 
    end a ~ 0.9 e ~ 0.09

    obj = @group fwm intrx with_role(:object, intrx) begin

        x -> x 
        x -> x  
    end

    @set_rule fwm intrx begin
     
        sbj * obj
    end
end

x = Dict(species(fwm) .=> rand(Uniform(1, 10), richness(hg)))
set_initial_condition!(fwm, x)

sol = solve(fwm; tspan=(0, 5000))
plot(sol)
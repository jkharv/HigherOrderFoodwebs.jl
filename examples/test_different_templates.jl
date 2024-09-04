using Revise
using HigherOrderFoodwebs
using SpeciesInteractionNetworks
using ModelingToolkit
using Distributions
using DifferentialEquations
using Plots

hg  = (optimal_foraging ∘ nichemodel)(30, 0.2)
fwm = FoodwebModel(hg)

self_loops = filter(isloop, interactions(fwm))
trophic = filter(!isloop, interactions(fwm))

function add_auxiliary_variable!(fwm::FoodwebModel, sym::Symbol)

    num = HigherOrderFoodwebs.create_variable(sym, fwm.t)
    fwm.aux_vars[sym] = num
end

function aux_var(fwm, sym)

    return fwm.aux_vars[sym]
end

av(x) = aux_var(fwm, x)


function new_param(fwm, sym, spp, val)
    
    # Make it unambigous
    sym = (gensym ∘ join)([sym, spp...], "_" )

    # Create the parameter and add it to the FoodwebModel.
    param = HigherOrderFoodwebs.create_param(sym)
    push!(fwm.params, param)
    push!(fwm.param_vals, param => val)

    return param
end

new_param(sym, spp, val) = new_param(fwm, sym, spp, val)

for i ∈ self_loops

    s = fwm.vars[subject(i)]
    k = new_param(:k, [subject(i)], 10.0)

    growth = s * (1.0 - s / k)  

    fwm.dynamic_rules[i] = HigherOrderFoodwebs.DynamicalRule(
        growth, # Forwards
        growth, # Backwards
        [s],    # Variables
        [k]     # Parameters
    )
end

for i ∈ trophic

    s = subject(i)
    o = object(i)
    m = with_role(:AF_modifier, i)





end


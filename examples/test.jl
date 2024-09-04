using Revise
using HigherOrderFoodwebs
using SpeciesInteractionNetworks
using ModelingToolkit
using Distributions
using DifferentialEquations

hg  = (optimal_foraging ∘ nichemodel)(30, 0.2);
fwm = FoodwebModel(hg);

self_loops = filter(isloop, interactions(fwm))
trophic = filter(!isloop, interactions(fwm))

av(x) = aux_var(fwm, x)

function add_auxiliary_variable!(fwm::FoodwebModel, sym::Symbol)

    num = HigherOrderFoodwebs.create_variable(sym, fwm.t)
    fwm.aux_vars[sym] = num
end

function aux_var(fwm, sym)

    return fwm.aux_vars[sym]
end

for intrx ∈ self_loops 

    tmplt = @group fwm species(intrx) begin
        
        x -> r * x * (1 - x) / k
    end r ~ 1 k ~ rand(Uniform(1,10))

    @set_rule fwm intrx tmplt
end 

for intrx ∈ trophic

    sbj = with_role(:subject, intrx)
    obj = with_role(:object, intrx)
    afmods = with_role(:AF_modifier, intrx)

    # Dynamics of a_ij
    sym = Symbol("a_$(sbj[1])_$(obj[1])")
    add_auxiliary_variable!(fwm, sym)

    a = @group fwm [sym, sbj..., obj..., afmods...] begin
       
        x[] -> g * a * (e * f * x[3] - sum(a * e * f * x[4:end]))
    end g ~ 0.0001 a ~ 0.9 e ~ 0.14 f ~ 8

    @set_aux_rule fwm sym a

    # Biomass Dynamics
    sbj_tmplt = @group fwm [with_role(:subject, intrx)..., sym] begin

        x[] -> x[1] * x[2] * e
        x[] -> -x[1] * x[2] 
    end e ~ 0.09

    obj_tmplt = @group fwm with_role(:object, intrx) begin

        x -> x 
        x -> x  
    end

    @set_rule fwm intrx sbj_tmplt * obj_tmplt
end

x_a0s = Dict((collect ∘ keys)(fwm.aux_vars) .=> 0.9)
x_spp = Dict([x => 0.5 for x in species(fwm)])
set_initial_condition!(fwm, merge(x_a0s, x_spp))

extinction_record = Vector{Tuple{Float64, Symbol}}()

et = ExtinctionThresholdCallback(fwm, 1e-20, extinction_record);

sol = solve(fwm, RK4(); 
    callback = et
)

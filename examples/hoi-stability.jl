using DifferentialEquatons
using ModelingToolkit
using EcologicalNetworks
using EcologicalHypergraphs
using Statistics
using Plots
using StatsPlots

function build_community(n_spp)

    web = nichemodel(n_spp, 0.2)
    hg = EcologicalHypergraph(web)

    tl = trophic_level(web)
    producer_filter = x -> subject_is_producer(x, tl)
    consumer_filter = x -> subject_is_consumer(x, tl)

    loops = filter(isloop, interactions(hg))
    producer_growth = filter(producer_filter, loops)
    consumer_growth = filter(consumer_filter, loops)

    trophic = filter(!isloop, interactions(hg))

    # Producer growth
    @functional_form subject.(producer_growth) begin
        
        x -> r*x*(1 - x/k)
    end r ~ Uniform(0.5, 2.0) k ~ Uniform(0.1, 10)

    # Consumer growth
    @functional_form subject.(consumer_growth) begin
        
        x -> r*x
    end r ~ Uniform(-0.2, -0.01)

    # Trophic interactions
    @functional_form subject.(trophic) begin
    
        x -> a*e*x
        x -> -a*x
    end a ~ Uniform(0.2, 0.8) e ~ Uniform(0.1, 0.20)

    # Trophic interactions pt. 2
    @functional_form object.(trophic) begin
        
        x -> x
    end

    sys = build_numerical_system(hg, (0,500))
    sol = solve(sys, Tsit5())

    if sol.retcode != ReturnCode.Success

        return (n = 0, sol = sol, hg = hg)
    end

    n_spp_stable = n_spp - sum(isapprox.(sol[end], Ref(0), atol=1e-8))
    return (n = n_spp_stable, sol = sol, hg = hg)
end

function stable_community_factory(n_spp_min)

    for i ∈ 1:100

        x = build_community(n_spp_min * 3)
        if x.n >= n_spp_min
            println("Stable community with $(x.n) species.")
            return (hg = x.hg, sol = x.sol) 
        end
    end
    error("Couldn't get a stable community after 100 attempts.")
end

function coefv(sol)

    n_spp = length(sol[1])
    acc = 0
    
    for i in 1:n_spp    

        acc = acc + std(sol[i,:])/mean(sol[i,:])
    end
    return acc/n_spp
end

function add_optimal_foraging(hg)

    hg = deepcopy(hg)
    mods = optimal_foraging!(hg)
   
    @functional_form mods begin
   
        x[] ->  x[1] / sum(x[1:end])
    end 

    return build_numerical_system(hg, (0, 500))
end


# Make some stable communities
comms = [10 for i ∈ 1:20];
comms = stable_community_factory.(comms);
hgs = map(x -> x.hg, comms);

solns = map(x -> x.sol, comms);
coefvs_no_hoi = map(coefv, solns);

sys_w_hoi = add_optimal_foraging.(hgs);
solns_w_hoi = map(x -> solve(x, Tsit5()), sys_w_hoi);

coefvs_w_hoi = map(coefv, solns_w_hoi);

x = hcat(coefvs_no_hoi, coefvs_w_hoi)
dotplot(coefvs_w_hoi, side=:right, label="With optimal foraging")
dotplot!(coefvs_no_hoi, side=:left, label="Without optimal foraging")
ylabel!("Mean coefficient of variation")
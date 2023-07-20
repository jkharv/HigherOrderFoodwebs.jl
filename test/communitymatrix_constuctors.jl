m = [
 0  0  0  0  0
 0  1  0  0  0
 0  1  1  1  0
 0  1  1  1  0
 0  0  0  1  1
]

web = UnipartiteNetwork(convert(Matrix{Bool}, m))
hg = EcologicalHypergraph(m, ["s1", "s2", "s3", "s4", "s5"])

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

# Add some modifiers
mods = optimal_foraging!(hg);

# Add the modifier functions
@functional_form mods begin
   
    x[] ->  (p[1] * x[1]) / sum(p[1:end] .* x[1:end])

end p[] ~ Uniform(0.2, 0.3);

cm = CommunityMatrix(hg)

@testset "CommunityMatrix constructors" begin
    
    @test_skip species(cm) == species(hg)
    @test_skip vars(cm) == vars(hg)
    @test_skip EcologicalHypergraphs.params(cm) == EcologicalHypergraphs.species(hg)
    @test isequal(cm["s1", "s1"], cm[1,1])
    @test isequal(cm["s3", "s5"], cm[3,5])
end
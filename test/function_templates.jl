# ===============================================================================
# Explicit single variable function templates
# ===============================================================================

m = [
1 0 0 0
0 1 0 0
0 0 1 0
0 0 0 1
]
m = convert(Matrix{Bool}, m)

hg = DynamicalHypergraph(m, ["s1", "s2", "s3", "s4"])

@functional_form subject.(interactions(hg)) begin
    
    x -> r * x

end r ~ Normal(0.5, 0.2)

i1 = subject(interactions(hg)[1])
i2 = subject(interactions(hg)[2])
eq = first(keys(vars(i1))) * first(keys(EcologicalHypergraphs.params(i1)))

@testset "Explicit single variable" begin

    @test haskey(vars(hg), collect(keys(vars(i1)))[1])
    @test vars(i1) != vars(i2)
    @test length(EcologicalHypergraphs.params(i1)) == 1
    @test collect(values(EcologicalHypergraphs.params(i1)))[1] == Normal(0.5, 0.2)
    @test isequal(forwards_function(i1), eq)
    @test isequal(backwards_function(i1), eq)
end

# ===============================================================================
# Explicit multivariable function templates
# ===============================================================================

# m = [
# 1 0 0 0
# 0 1 0 0
# 0 0 1 0
# 0 0 0 1
# ]

# hg = EcologicalHypergraph(m, ["s1", "s2", "s3", "s4"])

# int1 = interactions(hg)[1]
# n = add_modifier!(int1, ["s2", "s3", "s4"])

# @functional_form n begin
    
#     x,y,z -> r * x * y * z

# end r ~ Normal(0.5, 0.2)

# i1 = subject(interactions(hg)[1])
# keys(vars(i2))

@testset "Explicit multi variable" begin

    @test_skip haskey(vars(hg), collect(keys(vars(i1)))[1])
    @test_skip vars(i1) != vars(i2)
    @test_skip length(params(i1)) == 1
    @test_skip collect(values(params(i1)))[1] == Normal(0.5, 0.2)
    @test_skip isequal(forwards_function(i1), eq)
    @test_skip isequal(backwards_function(i1), eq)
end

# ===============================================================================
# Implicit multivariable function templates
# ===============================================================================

m = [
1 0 0 0
0 1 0 0
0 0 1 0
0 0 0 1
]
m = convert(Matrix{Bool}, m)

hg = DynamicalHypergraph(m, ["s1", "s2", "s3", "s4"])

int1 = interactions(hg)[1]
n = add_modifier!(int1, ["s2", "s3", "s4"])

@functional_form n begin
    
    x[] -> r * sum(x[1:end])

end r ~ Normal(0.5, 0.2)

eq = sum(keys(vars(n))) * collect(keys(EcologicalHypergraphs.params(n)))[1]

@testset "Implicit multivariable variable" begin

    @test length(vars(n)) == 3
    @test length(EcologicalHypergraphs.params(n)) == 1
    @test isequal(forwards_function(n), eq)
    @test isequal(backwards_function(n), eq)
    @test collect(values(EcologicalHypergraphs.params(n)))[1] == Normal(0.5, 0.2)
end
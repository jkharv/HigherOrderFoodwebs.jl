using Documenter
using EcologicalHypergraphs

# Disables prettyurls when not in a CI environment. This makes browing the
# generated HTML easier, eg no need to use a webserver.
# when in CI it uses prettyurls that look good in deployment.
fmt = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true")

makedocs(
    sitename = "EcologicalHypergraphs", 
    format = fmt,
    modules = [EcologicalHypergraphs],
    authors = "Jake Harvey",
    pages = [
        "Index" => "index.md",
        "Examples" => [
            "Optimal Foraging" => "examples/optimal_foraging.md",
        ],
        "Interface" => [
            "Types" => "interface/types.md",
            "Core Functions" => "interface/core.md"
        ],
        "Dynamics" => [
            "Dynamical Hypergraphs" => "dynamics/dynamical_hypergraphs.md",
            "Community Matrices" => "dynamics/community_matrices.md"
        ],
        "Statistics" => [
            "Statistical Hypergraphs" => "statistics/statistical_hypergraphs.md"
        ],
    ]
)

deploydocs(
    repo   = "github.com/jkharv/EcologicalHypergraphs.jl.git",
    devbranch = "main"
)
using Documenter
using HigherOrderFoodwebs

# Disables prettyurls when not in a CI environment. This makes browing the
# generated HTML easier, eg no need to use a webserver.
# when in CI it uses prettyurls that look good in deployment.
fmt = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true")

makedocs(
    sitename = "HigherOrderFoodwebs", 
    format = fmt,
    modules = [HigherOrderFoodwebs],
    authors = "Jake Harvey",
    pages = [
        "Index" => "index.md"
    ]
)

deploydocs(
    repo   = "github.com/jkharv/HigherOrderFoodwebs.jl.git",
    devbranch = "main"
)
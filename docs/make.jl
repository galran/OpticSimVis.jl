
using Documenter
using OpticSimVis

makedocs(
    sitename = "OpticSimVis.jl",
    format = Documenter.HTML(
        # prettyurls = get(ENV, "CI", nothing) == "true",
        # assets = [asset("assets/GlimmerJulia.png", class = :ico, islocal = true)],
    ),
    modules = [Glimmer],
    pages = [
        "Home" => "index.md",
        "Reference" => "ref.md",
    ],
    expandfirst = [])


deploydocs(
    repo = "github.com/galran/OpticSimVis.jl.git",
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)
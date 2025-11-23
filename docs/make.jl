using hfttb
using Documenter

DocMeta.setdocmeta!(hfttb, :DocTestSetup, :(using hfttb); recursive=true)

makedocs(;
    modules=[hfttb],
    authors="linan <linanisyugioh@163.com>",
    sitename="hfttb.jl",
    format=Documenter.HTML(;
        canonical="https://linanisyugioh.github.io/hfttb.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/linanisyugioh/hfttb.jl",
    devbranch="master",
)

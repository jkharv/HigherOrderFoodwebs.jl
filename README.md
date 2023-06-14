# EcologicalHypergraphs.jl

[![](https://img.shields.io/badge/docs-dev-orange.svg)](
    https://jakeharvey.science/EcologicalHypergraphs.jl/dev)

`EcologicalHypergraphs.jl` allows you to do ecology using hypergraphs. Currently, it 
supports using hypergraphs do create large dynamical foodweb models which can incorporate
non-trophic effects. In the future, it will support statistical study of these hypergraphs
as well. It may also support embedding these hypergraphs in spatial networks in the
future to facilitate metacommunity models.

## Getting started

This package isn't yet in the Julia general registry. You can still install it directly
from this git repository.

    ] add github.com/jkharv/EcologicalHypergraphs.jl

## Examples

There are examples in the example directory of this repository.

## Integration with other packages

* `SimpleHypergraphs.jl`
    * Conversion functions are planned for converting to and from `SimpleHypergraphs.jl`
    types.

### EcologicalNetworks.jl

`EcologicalHypergraphs.jl` currently has constructors for creating hypergraphs from
`EcologicalNetworks.jl` types, allowing access to all the structural models that it
provides. We will eventually include functions that can project hypergraphs into pairwise
graphs using `EcologicalNetworks.jl` types, allowing the use of existing analysis tools
in the package.

### Symbolics.jl

Dynamical models done in `EcologicalHypergraphs.jl` are specified using `Symbolics.jl`.
You can do anything that `Symbolics.jl` allows you to do to the resultant model.

### ModelingToolkit.jl

`Symbolics.jl` is used via `ModelingToolkit.jl` meaning that parameters are tagged
differently than variables and creating numerical systems `ModelingToolkit.jl` does
all of its usual symbolic manipulations on the system.
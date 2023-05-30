# EcologicalHypergraphs.jl

`EcologicalHypergraphs.jl` allows you to do ecology using hypergraphs. Currently, it 
supports using hypergraphs do create large dynamical foodweb models which can incorporate
non-trophic effects. In the future, it will support statistical study of these hypergraphs
as well. It may also support embedding these hypergraphs in spatial networks in the
future to facilitate metacommunity models.

## Getting started

TODO

## Examples

TODO

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

Dynamical models done in `EcologicalHypergraphs.jl` are specified using `Symbolics.jl` you
can do anything that `Symbolics.jl` allows you to do to the resultant model.

### ModelingToolkit.jl

`Symbolics.jl` is used via `ModelingToolkit.jl` meaning parameters are tagged differently
than variables and when creating numerical systems `ModelingToolkit.jl` does all of its
usual symbolic manipulations on the system.
# Dynamical Hypergraphs

The core of `EcologicalHypergraph`'s dynamical tool set is the `@functional_form` macro.
This macro allows you to assign symbolic functions to each node in a hypergraph along
with the values of any parameters. This hypergraph with functional form information can
be transformed into a system of ODEs which can be solved using Julia's ecosystem of DE
solvers.

```@docs
@functional_form
```

# Systems of Differential Equations

These functions are used for converting `EcologicalHypergraph` objects annotated with
functions to systems of differential equations for use in either
`DifferentialEquations.jl` or `Symbolics.jl`

```@docs
build_symbolic_system
build_numerical_system
```
module HigherOrderFoodwebs

using SpeciesInteractionNetworks
using Distributions
using SparseArrays
using LinearAlgebra

using SciMLBase
using SymbolicIndexingInterface

using OrdinaryDiffEqTsit5
using OrdinaryDiffEqRosenbrock

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

using MacroTools: prewalk

# ---------------------- #
# Core type declarations #
# ---------------------- #

include("./types/dynamic_rule.jl")
export DynamicRule

include("./types/foodweb_variables.jl")
export FoodwebVariables
export SPECIES_VARIABLE, ENVIRONMENT_VARIABLE, TRAIT_VARIABLE, PARAMETER

include("./types/foodweb_model.jl")
export FoodwebModel

include("./types/community_matrix.jl")
export CommunityMatrix

# --------------- #
# Core interfaces #
# --------------- #

include("./core_interfaces/dynamic_rule.jl")

include("./core_interfaces/foodweb_variables.jl")
export add_var!, variables, get_symbol, get_index
export set_value!, get_value, variable_type

include("./core_interfaces/foodweb_interface.jl")
export species, richness, interactions, role, roles, has_role
export isproducer, isconsumer, set_u0!
export set_dynamic_rule!
export subject, object, with_role # From SpeciesInteractionNetworks.jl

include("./core_interfaces/rule-macro.jl")
export @rule, @var, @param

# Passthroughs to the FoodwebVariables type
export get_symbol, set_u0!, variable_type
export add_var!, add_param!

include("./core_interfaces/community_matrix.jl")
# The Array interface from Base. No exports needed

include("./core_interfaces/symbolic_indexing.jl")
# No exports needed, this only gets used internally by SciML stuff.

# --------------------------------------------------------- #
# Solver callbacks that are generally relevant for foodwebs #
# --------------------------------------------------------- #

include("./solver_callbacks/extinction_sequence_callback.jl")
export ExtinctionSequenceCallback

include("./solver_callbacks/invasion_sequence_callback.jl")
export InvasionSequenceCallback 

include("./solver_callbacks/extinction_threshold_callback.jl")
export ExtinctionThresholdCallback

include("./solver_callbacks/richness_termination_callback.jl")
export RichnessTerminationCallback

# ----------------------- #
# Foodweb assembly models #
# ----------------------- #

include("./foodweb_assembly/foodweb_assembly.jl")
include("./foodweb_assembly/trophic_ordering.jl")
export assemble_foodweb, assemble_stochastic_foodweb

# ----------------- #
# Structural models #
# ----------------- #

include("./structural_models/types.jl")
include("./structural_models/optimal_foraging.jl")
include("./structural_models/nichemodel.jl")
export nichemodel, optimal_foraging

# ------------------------------------- #
# Tools for examining realized networks #
# ------------------------------------- #

include("./realized_networks/trophic_flux.jl")
export trophic_flux

# ----------------- #
# Model compilation #
# ----------------- #

include("./model_compilation/code_compilation.jl")

end
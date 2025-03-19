module HigherOrderFoodwebs

using MacroTools: prewalk, postwalk, @capture, unblock, rmlines, prettify
using SpeciesInteractionNetworks
using ModelingToolkit
using Symbolics
using Distributions
using LinearAlgebra
using SparseArrays
using SciMLBase
using OrdinaryDiffEq
using SymbolicIndexingInterface

# ----------------------#
# Core type declrations #
# ----------------------#

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
export add_var!, variables, get_symbol, get_variable, get_index
export set_value!, get_value

include("./core_interfaces/foodweb_interface.jl")
export species, richness, interactions, role, roles, has_role
export isproducer, isconsumer, set_u0!
export subject, object, with_role # From SpeciesInteractionNetworks.jl
export get_symbol, get_variable, set_u0!
export add_var!, add_param!

include("./core_interfaces/community_matrix.jl")
# The Array interface from Base. No exports needed

include("./core_interfaces/sciml_ext.jl")
export ODESystem, ODEProblem

# --------------------------------------------------------- #
# Solver callbacks that are generally relevant for foodwebs #
# --------------------------------------------------------- #

include("./solver_callbacks/extinction_sequence_callback.jl")
export ExtinctionSequenceCallback

include("./solver_callbacks/extinction_threshold_callback.jl")
export ExtinctionThresholdCallback

include("./solver_callbacks/richness_termination_callback.jl")
export RichnessTerminationCallback

# ----------------------- #
# Foodweb assembly models #
# ----------------------- #

include("./foodweb_assembly/foodweb_assembly.jl")
include("./foodweb_assembly/trophic_ordering.jl")
export assemble_foodweb

# ----------------- #
# Structural models #
# ----------------- #

include("./structural_models/types.jl")
include("./structural_models/optimal_foraging.jl")
include("./structural_models/nichemodel.jl")
export nichemodel, optimal_foraging

# --------------------------------------------------------- #
# Common functions and their derivatives for foodweb models #
# --------------------------------------------------------- #

include("./registered_symbolics/holling_2.jl")
include("./registered_symbolics/logistic.jl")
export holling2, logistic

# ------------------------------------- #
# Tools for examining realized networks #
# ------------------------------------- #

include("realized_networks/trophic_flux.jl")
export trophic_flux

end
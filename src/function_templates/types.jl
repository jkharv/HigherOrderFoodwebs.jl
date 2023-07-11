# This file contains type hierachy of template objects that are parsed from the function
# templates provided by the user.

abstract type TemplateObject end
abstract type TemplateVariable <: TemplateObject end
abstract type TemplateParameter <: TemplateObject end

struct TemplateScalarParameter <: TemplateParameter

    sym::Symbol
    val::Union{Missing, DistributionOption}
end

struct TemplateVectorParameter <: TemplateParameter

    sym::Symbol
    val::Union{Missing, DistributionOption}   
end

struct TemplateScalarVariable <:TemplateVariable

    sym::Symbol
    val::Union{Missing, DistributionOption}
end

struct TemplateVectorVariable <: TemplateVariable

    sym::Symbol
    val::Union{Missing, DistributionOption}
end

const RenameDict = Dict{TemplateObject, Union{Num, Vector{Num}, Missing}}

struct FunctionTemplate

    forwards_function::Expr
    backwards_function::Expr

    objects::RenameDict
end
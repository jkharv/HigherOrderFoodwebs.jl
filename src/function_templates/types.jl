# This file contains type hierachy of template objects that are parsed from the
# function templates provided by the user.

abstract type TemplateObject end
abstract type TemplateVariable <: TemplateObject end
abstract type TemplateParameter <: TemplateObject end

struct TemplateScalarParameter <: TemplateParameter

    sym::Symbol
    val::TermValue
    num::Union{Num, Vector{Num}, Missing}
end

struct TemplateVectorParameter <: TemplateParameter

    sym::Symbol
    val::TermValue
    num::Union{Num, Vector{Num}, Missing}
end

struct TemplateScalarVariable <:TemplateVariable

    sym::Symbol
    val::TermValue
    num::Union{Num, Vector{Num}, Missing}
end

struct TemplateVectorVariable <: TemplateVariable

    sym::Symbol
    val::TermValue
    num::Union{Num, Vector{Num}, Missing}
end

struct FunctionTemplate

    forwards_function::Expr
    backwards_function::Expr

    canonical_vars::Vector{Symbol}
    objects::Vector{TemplateObject}
end
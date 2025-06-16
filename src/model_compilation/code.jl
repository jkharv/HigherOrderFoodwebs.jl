# --------- #
# Test Code #
# --------- #

# cm = CommunityMatrix(fwm)

# test_rhs = Vector{Num}()
# for row in eachrow(cm)

#     push!(test_rhs, sum(row))
# end

# using BenchmarkTools

# @time f = toexpr(test_rhs);
# @profview f = toexpr(test_rhs);

# vars, params, t = HigherOrderFoodwebs.ordered_variables(Main.fwm)

# jac = HigherOrderFoodwebs.fwm_jacobian(Main.fwm)

# f = build_function(jac, vars, params, t;
#     conv = Code.toexpr,
#     expression = Val{false},  
#     skipzeros = true, 
#     checkbounds = true,
#     linenumbers = false,
#     parallel = Symbolics.MultithreadedForm()
# )

# f[2] # 2 is the in-place version.

# ------- #
# Imports #
# ------- #

module Code

using StaticArrays, SparseArrays, LinearAlgebra, NaNMath, SpecialFunctions
using Symbolics

# export toexpr, Assignment, (←), Let, Func, DestructuredArgs, LiteralExpr,
#        SetArray, MakeArray, MakeSparseArray, MakeTuple, AtIndex,
#        SpawnFetch, Multithreaded, ForLoop, cse

import SymbolicUtils
import SymbolicUtils.Rewriters
import SymbolicUtils: @matchable, BasicSymbolic, Sym, Term, iscall, operation, arguments, issym,
                      symtype, sorted_arguments, metadata, isterm, term, maketerm, Symbolic
import SymbolicIndexingInterface: symbolic_type, NotSymbolic

# ---------------------- #
# CodegenPrimitive types #
# ---------------------- #

abstract type CodegenPrimitive end

struct ForLoop <: CodegenPrimitive
    itervar
    range
    body
end

@matchable struct Assignment <: CodegenPrimitive
    lhs
    rhs
end

# Call elements of vector arguments by their name.
@matchable struct DestructuredArgs <: CodegenPrimitive
    elems
    inds
    name
    inbounds::Bool
    create_bindings::Bool
end

@matchable struct SetArray <: CodegenPrimitive
    inbounds::Bool
    arr
    elems  # Either iterator of Pairs or just an iterator
    return_arr::Bool
end

SetArray(inbounds, arr, elems) = SetArray(inbounds, arr, elems, false)

@matchable struct AtIndex <: CodegenPrimitive
    i
    elem
end

function DestructuredArgs(elems, name=nothing; inds=eachindex(elems), inbounds=false, create_bindings=true)
    if name === nothing
        # I'm sorry if you get a hash collision here lol
        name = Symbol("##arg#", hash((elems, inds, inbounds, create_bindings)))
    end
    DestructuredArgs(elems, inds, name, inbounds, create_bindings)
end

@matchable struct Let <: CodegenPrimitive
    pairs::Vector{Union{Assignment,DestructuredArgs}} # an iterator of pairs, ordered
    body
    let_block::Bool
end

Let(assignments, body) = Let(assignments, body, true)

@matchable struct MakeArray <: CodegenPrimitive
    elems
    similarto # Must be either a reference to an array or a concrete type
    output_eltype
end

MakeArray(elems, similarto) = MakeArray(elems, similarto, nothing)

## We use a separate type for Sparse Arrays to sidestep the need for
## iszero to be defined on the expression type
@matchable struct MakeSparseArray{S<:AbstractSparseArray} <: CodegenPrimitive
    array::S
end

@matchable struct Func <: CodegenPrimitive
    args::Vector
    kwargs
    body
    pre::Vector
end

Func(args, kwargs, body) = Func(args, kwargs, body, [])

struct LiteralExpr <: CodegenPrimitive
    ex
end

struct Multithreaded end

struct SpawnFetch{Typ} <: CodegenPrimitive
    exprs::Vector
    args::Union{Nothing, Vector}
    combine
end

(::Type{SpawnFetch{T}})(exprs, combine) where {T} = SpawnFetch{T}(exprs, nothing, combine)

@matchable struct MakeTuple <: CodegenPrimitive
    elems
end

MakeTuple(x::Tuple) = MakeTuple(collect(x))

# ---------------- #
# State Management #
# ---------------- #

struct NameState
    rewrites::Dict{Any, Any}
end
NameState() = NameState(Dict{Any, Any}())
function union_rewrites!(n, ts)
    for t in ts
        n[t] = Symbol(string(t))
    end
end

struct LazyState
    ref::Ref{Any}
end
LazyState() = LazyState(Ref{Any}(nothing))

function Base.get(st::LazyState)
    s = getfield(st, :ref)[]
    s === nothing ? getfield(st, :ref)[] = NameState() : s
end

@inline Base.getproperty(st::LazyState, f::Symbol) = f==:symbolify ?  getproperty(st, :rewrites) : getproperty(get(st), f)

# ------------------- #
# Utilities / Misc??? #
# ------------------- #

# This unwrap and the toexpr(::Num) are to convert from the Symbolics wrapper
# type to the types used in SymbolicUtils
value(x) = x.val 
unwrap(x) = value(x)

lhs(a::Assignment) = a.lhs
rhs(a::Assignment) = a.rhs

const (←) = Assignment

Base.convert(::Type{Assignment}, p::Pair) = Assignment(pair[1], pair[2])

const NaNMathFuns = (
    sin,
    cos,
    tan,
    asin,
    acos,
    acosh,
    atanh,
    log,
    log2,
    log10,
    lgamma,
    log1p,
    sqrt,
)

# ---------------- #
# toexpr Functions #
# ---------------- #

# Top entrypoint?
toexpr(x) = toexpr(x, LazyState())

# This sorta does dispatch I guess?
function toexpr(O, st)

    if issym(O)
        O = substitute_name(O, st)
        return issym(O) ? nameof(O) : toexpr(O, st)
    end
    O = substitute_name(O, st)

    if _is_array_of_symbolics(O)
        return issparse(O) ? toexpr(MakeSparseArray(O)) : toexpr(MakeArray(O, typeof(O)), st)
    end
    
    !iscall(O) && return O

    op = operation(O)
    expr′ = function_to_expr(op, O, st)
    if expr′ !== nothing
        return expr′
    else
        !iscall(O) && return O
        args = arguments(O)

        return Expr(:call, toexpr(op, st), map(x->toexpr(x, st), args)...)
    end
end

function recurse_expr(ex::Expr, st) 

    println("Recurse")

    return Expr(ex.head, recurse_expr.(ex.args, (st,))...)
end

function recurse_expr(ex, st) 
    
    println("Recurse")    

    return toexpr(ex, st)
end

toexpr(n::Num, st) = toexpr(value(n), st)

function toexpr(a::Assignment, st) 
    
    return :($(toexpr(a.lhs, st)) = $(toexpr(a.rhs, st)))
end

function toexpr(O::Expr, st) 
 
    return O
end

toexpr(x::DestructuredArgs, st) = toexpr(x.name, st)

function toexpr(l::Let, st)
    if all(x->x isa Assignment && !(x.lhs isa DestructuredArgs), l.pairs)
        dargs = l.pairs
    else
        assignments = []
        for x in l.pairs
            if x isa DestructuredArgs
                if x.create_bindings
                    append!(assignments, get_assignments(x, st))
                else
                    for a in get_assignments(x, st)
                        st.rewrites[a.lhs] = a.rhs
                    end
                end
            elseif x isa Assignment && x.lhs isa DestructuredArgs
                if x.lhs.create_bindings
                    push!(assignments, x.lhs.name ← x.rhs)
                    append!(assignments, get_assignments(x.lhs, st))
                else
                    push!(assignments, x.lhs.name ← x.rhs)
                    for a in get_assignments(x.lhs, st)
                        st.rewrites[a.lhs] = a.rhs
                    end
                end
            else
                push!(assignments, x)
            end
        end
        # expand and come back
        return toexpr(Let(assignments, l.body, l.let_block), st)
    end

    funkyargs = get_rewrites(map(lhs, dargs))
    union_rewrites!(st.rewrites, funkyargs)

    bindings = map(p->toexpr(p, st), dargs)
    l.let_block ? Expr(:let,
                       Expr(:block, bindings...),
                       toexpr(l.body, st)) : Expr(:block,
                                                  bindings...,
                                                  toexpr(l.body, st))
end

toexpr_kw(f, st) = Expr(:kw, toexpr(f, st).args...)

function toexpr(f::Func, st)
    funkyargs = get_rewrites(vcat(f.args, map(lhs, f.kwargs)))
    union_rewrites!(st.rewrites, funkyargs)
    dargs = filter(x->x isa DestructuredArgs, f.args)
    if !isempty(dargs)
        body = Let(dargs, f.body, false)
    else
        body = f.body
    end
    if isempty(f.kwargs)
        :(function ($(map(x->toexpr(x, st), f.args)...),)
              $(f.pre...)
              $(toexpr(body, st))
          end)
    else
        :(function ($(map(x->toexpr(x, st), f.args)...),;
                    $(map(x->toexpr_kw(x, st), f.kwargs)...))
              $(f.pre...)
              $(toexpr(body, st))
          end)
    end
end

function toexpr(a::AtIndex, st)
    toexpr(a.elem, st)
end

function toexpr(s::SetArray, st)
    ex = quote
        $([:($(toexpr(s.arr, st))[$(ex isa AtIndex ? toexpr(ex.i, st) : i)] = $(toexpr(ex, st)))
           for (i, ex) in enumerate(s.elems)]...)
        $(s.return_arr ? toexpr(s.arr, st) : nothing)
    end
    s.inbounds ? :(@inbounds $ex) : ex
end

function toexpr(a::MakeArray, st)

    similarto = toexpr(a.similarto, st)
    T = similarto isa Type ? similarto : :(typeof($similarto))
    ndim = ndims(a.elems)
    elT = a.output_eltype

    # elements = asyncmap(x -> toexpr(x, st), a.elems; ntasks = 500)

    elements = Vector{Any}(undef, size(a.elems))

    Threads.@threads for i in eachindex(a.elems)

        elements[i] = toexpr(a.elems[i], st)
    end
    
    return quote
        $create_array($T,
                     $elT,
                     Val{$ndim}(),
                     Val{$(size(a.elems))}(),
                     $(elements...),
                     )
    end
end

function toexpr(a::MakeSparseArray{<:SparseMatrixCSC}, st)
    sp = a.array
    :(SparseMatrixCSC($(sp.m), $(sp.n),
                      $(copy(sp.colptr)), $(copy(sp.rowval)),
                      [$(toexpr.(sp.nzval, (st,))...)]))
end

function toexpr(a::MakeSparseArray{<:SparseVector}, st)
    sp = a.array
    :(SparseVector($(sp.n),
                   $(copy(sp.nzind)),
                   [$(toexpr.(sp.nzval, (st,))...)]))
end

function toexpr(a::MakeTuple, st)

    :(($(toexpr.(a.elems, (st,))...),))
end

function toexpr(p::SpawnFetch{Multithreaded}, st)

    args = p.args === nothing ? Iterators.repeated((), length(p.exprs)) : p.args
    spawns = map(p.exprs, args) do thunk, xs
        :(Base.Threads.@spawn $(toexpr(thunk, st))($(toexpr.(xs, (st,))...)))
    end
    quote
        $(toexpr(p.combine, st))(map(fetch, ($(spawns...),))...)
    end
end

function toexpr(exp::LiteralExpr, st)

    recurse_expr(exp.ex, st)
end

function toexpr(f::ForLoop, st)
    :(for $(toexpr(f.itervar, st)) in $(toexpr(f.range, st))
        $(toexpr(f.body, st))
    end)
end

# ------------------------ #
# function_to_expr methods #
# ------------------------ #

function function_to_expr(op, O, st)
    (get(st.rewrites, :nanmath, false) && op in NaNMathFuns) || return nothing
    name = nameof(op)
    fun = GlobalRef(NaNMath, name)
    args = map(Base.Fix2(toexpr, st), arguments(O))
    expr = Expr(:call, fun)
    append!(expr.args, args)
    return expr
end

function function_to_expr(op::Union{typeof(*),typeof(+)}, O, st)

    out = get(st.rewrites, O, nothing)
    out === nothing || return out
    args = map(Base.Fix2(toexpr, st), arguments(O))
    # args = map(Base.Fix2(toexpr, st), sorted_arguments(O))
    # The commented line is what this originally was. Not sure
    # if the arguments being sorted is actually necessary. 
    # + and * are commutative no?

    if length(args) >= 3 && symtype(O) <: Number
        x, xs = Iterators.peel(args)
        foldl(xs, init=x) do a, b
            Expr(:call, op, a, b)
        end
    else
        expr = Expr(:call, op)
        append!(expr.args, args)
        expr
    end
end

function function_to_expr(op::typeof(^), O, st)
    args = arguments(O)
    if args[2] isa Real && args[2] < 0
        args[1] = Term(inv, Any[args[1]])
        args[2] = -args[2]
    end
    if isequal(args[2], 1)
        return toexpr(args[1], st)
    end
    if get(st.rewrites, :nanmath, false) === true && !(args[2] isa Integer)
        op = NaNMath.pow
        return toexpr(Term(op, args), st)
    end
    return nothing
end

function function_to_expr(::typeof(ifelse), O, st)
    args = arguments(O)
    :($(toexpr(args[1], st)) ? $(toexpr(args[2], st)) : $(toexpr(args[3], st)))
end

function function_to_expr(x::BasicSymbolic, O, st)
    issym(x) ? get(st.rewrites, O, nothing) : nothing
end

function substitute_name(O, st)
    if (issym(O) || iscall(O)) && haskey(st.rewrites, O)
        st.rewrites[O]
    else
        O
    end
end

function _is_tuple_or_array_of_symbolics(O)
    return O isa CodegenPrimitive ||
        (symbolic_type(O) != NotSymbolic() && !(O isa Union{Symbol, Expr})) ||
        _is_array_of_symbolics(O) ||
        _is_tuple_of_symbolics(O)
end

function _is_array_of_symbolics(O)
    # O is an array, not a symbolic array, and either has a non-symbolic eltype or contains elements that are
    # symbolic or arrays of symbolics
    return O isa AbstractArray && symbolic_type(O) == NotSymbolic() &&
        (symbolic_type(eltype(O)) != NotSymbolic() && !(eltype(O) <: Union{Symbol, Expr}) ||
        any(_is_tuple_or_array_of_symbolics, O))
end

# workaround for https://github.com/JuliaSparse/SparseArrays.jl/issues/599
function _is_array_of_symbolics(O::SparseMatrixCSC)
    return symbolic_type(eltype(O)) != NotSymbolic() && !(eltype(O) <: Union{Symbol, Expr}) ||
        any(_is_tuple_or_array_of_symbolics, findnz(O)[3])
end

function _is_tuple_of_symbolics(O::Tuple)
    return any(_is_tuple_or_array_of_symbolics, O)
end
_is_tuple_of_symbolics(O) = false

get_rewrites(args::DestructuredArgs) = ()
function get_rewrites(args::Union{AbstractArray, Tuple})
    cflatten(map(get_rewrites, args))
end
get_rewrites(x) = iscall(x) ? (x,) : ()
cflatten(x) = Iterators.flatten(x) |> collect

function get_assignments(d::DestructuredArgs, st)
    name = toexpr(d, st)
    map(d.inds, d.elems) do i, a
        ex = (i isa Symbol ? :($name.$i) : :($name[$i]))
        ex = d.inbounds && d.create_bindings ? :(@inbounds($ex)) : ex
        a ← ex
    end
end

## Array
@inline function _create_array(::Type{<:Array}, T, ::Val{dims}, elems...) where dims

    arr = Array{T}(undef, dims)
    @assert prod(dims) == nfields(elems)
    @inbounds for i=1:prod(dims)
        arr[i] = elems[i]
    end

    return arr
end

@inline function create_array(A::Type{<:Array}, T, ::Val, d::Val, elems...)
    _create_array(A, T, d, elems...)
end

@inline function create_array(A::Type{<:Array}, ::Nothing, ::Val, d::Val{dims}, elems...) where dims
    T = promote_type(map(typeof, elems)...)
    _create_array(A, T, d, elems...)
end

## Vector
#
@inline function create_array(::Type{<:Array}, ::Nothing, ::Val{1}, ::Val{dims}, elems...) where dims
    [elems...]
end

@inline function create_array(::Type{<:Array}, T, ::Val{1}, ::Val{dims}, elems...) where dims
    T[elems...]
end

## Matrix

@inline function create_array(::Type{<:Array}, ::Nothing, ::Val{2}, ::Val{dims}, elems...) where dims
    vhcat(dims, elems...)
end

@inline function create_array(::Type{<:Array}, T, ::Val{2}, ::Val{dims}, elems...) where dims
    typed_vhcat(T, dims, elems...)
end

@inline function create_array(::Type{<:Base.ReinterpretArray}, ::Nothing,
        ::Val{1}, ::Val{dims}, elems...) where {dims}
    [elems...]
end

@inline function create_array(
        ::Type{<:Base.ReinterpretArray}, T, ::Val{1}, ::Val{dims}, elems...) where {dims}
    T[elems...]
end


vhcat(sz::Tuple{Int,Int}, xs::T...) where {T} = typed_vhcat(T, sz, xs...)
vhcat(sz::Tuple{Int,Int}, xs::Number...) = typed_vhcat(Base.promote_typeof(xs...), sz, xs...)
vhcat(sz::Tuple{Int,Int}, xs...) = typed_vhcat(Base.promote_eltypeof(xs...), sz, xs...)

function typed_vhcat(::Type{T}, sz::Tuple{Int, Int}, xs...) where T
    nr,nc = sz
    a = Matrix{T}(undef, nr, nc)
    k = 1
    for j=1:nc
        @inbounds for i=1:nr
            a[i, j] = xs[k]
            k += 1
        end
    end
    a
end

## Arrays of the special kind
@inline function create_array(A::Type{<:SubArray{T,N,P,I,L}}, S, nd::Val, d::Val, elems...) where {T,N,P,I,L}
    create_array(P, S, nd, d, elems...)
end

@inline function create_array(A::Type{<:PermutedDimsArray{T,N,perm,iperm,P}}, S, nd::Val, d::Val, elems...) where {T,N,perm,iperm,P}
    create_array(P, S, nd, d, elems...)
end


@inline function create_array(A::Type{<:Transpose{T,P}}, S, nd::Val, d::Val, elems...) where {T,P}
    create_array(P, S, nd, d, elems...)
end

@inline function create_array(A::Type{<:UpperTriangular{T,P}}, S, nd::Val, d::Val, elems...) where {T,P}
    create_array(P, S, nd, d, elems...)
end

## SArray
@inline function create_array(::Type{<:SArray}, ::Nothing, nd::Val, ::Val{dims}, elems...) where dims
    SArray{Tuple{dims...}}(elems...)
end

@inline function create_array(::Type{<:SArray}, T, nd::Val, ::Val{dims}, elems...) where dims
    SArray{Tuple{dims...}, T}(elems...)
end

## MArray
@inline function create_array(::Type{<:MArray}, ::Nothing, nd::Val, ::Val{dims}, elems...) where dims
    MArray{Tuple{dims...}}(elems...)
end

@inline function create_array(::Type{<:MArray}, T, nd::Val, ::Val{dims}, elems...) where dims
    MArray{Tuple{dims...}, T}(elems...)
end

end # module
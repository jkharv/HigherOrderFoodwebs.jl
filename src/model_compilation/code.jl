module Code

using Symbolics
using Symbolics: Arr, SetArray, ArrayOp, AbstractSparseArray, Setfield, _recursive_unwrap, unwrap, DestructuredArgs, Func
using SymbolicUtils
using SymbolicUtils: Sym 
using SymbolicUtils.Code
using SymbolicUtils.Code: toexpr, SpawnFetch
using Base.Threads
using SymbolicUtils.Code: LazyState
using LinearAlgebra
using RuntimeGeneratedFunctions

RuntimeGeneratedFunctions.init(@__MODULE__)

abstract type ParallelForm end
struct SerialForm <: ParallelForm end

"""
    ShardedForm{multithread}(cutoff, ncalls)

Split a long array construction into nested functions where each function calls
`ncalls` other functions, and the leaf functions populate at most `cutoff` number
of items in the array. If `multithread` is true, uses threading.
"""
struct ShardedForm{multithreaded} <: ParallelForm
    cutoff::Union{Nothing,Int}
    ncalls::Int
end

ShardedForm(cutoff, ncalls) = ShardedForm{false}(cutoff, ncalls)
ShardedForm() = ShardedForm(80, 4)

const MultithreadedForm = ShardedForm{true}

MultithreadedForm() = MultithreadedForm(nothing, 2*nthreads())

function throw_missing_specialization(n)
    throw(ArgumentError("Missing specialization for $n arguments. Check `iip_config`."))
end

# Scalar output

unwrap_nometa(x) = unwrap(x)
unwrap_nometa(x::Symbolics.CallWithMetadata) = unwrap(x.f)
function destructure_arg(arg::Union{AbstractArray, Tuple,NamedTuple}, inbounds, name)
    if !(arg isa Arr)
        DestructuredArgs(map(unwrap_nometa, arg), name, inbounds=inbounds, create_bindings=false)
    else
        unwrap_nometa(arg)
    end
end
destructure_arg(arg, _, _) = unwrap_nometa(arg)

function default_arg_name(i)
    Symbol("ˍ₋arg$(i)")
end

const DEFAULT_OUTSYM = Symbol("ˍ₋out")

# don't CSE inside operators
SymbolicUtils.Code.cse_inside_expr(sym, ::Symbolics.Operator, args...) = false
# don't CSE inside `getindex` of things created via `@variables`
# EXCEPT called variables
function SymbolicUtils.Code.cse_inside_expr(sym, ::typeof(getindex), x::SymbolicUtils.BasicSymbolic, idxs...)
    return !hasmetadata(sym, VariableSource) || hasmetadata(sym, CallWithParent)
end

function build_function(op, args...;
                        conv = toexpr,
                        expression = Val{true},
                        expression_module = @__MODULE__(),
                        checkbounds = false,
                        states = LazyState(),
                        linenumbers = true,
                        wrap_code = nothing,
                        cse = false,
                        nanmath = true,
                        kwargs...)

    op = _recursive_unwrap(op)
    states.rewrites[:nanmath] = nanmath
    dargs = map((x) -> destructure_arg(x[2], !checkbounds, default_arg_name(x[1])), enumerate(collect(args)))
    fun = Func(dargs, [], op)
    if wrap_code !== nothing
        fun = wrap_code(fun)
    end
    if cse
        fun = Code.cse(fun)
    end
    expr = conv(fun, states)
    if !checkbounds
        @assert Meta.isexpr(expr, :function)
        expr.args[2] = :(@inbounds begin; $(expr.args[2]); end)
    end
    if expression == Val{true}
        expr
    else
        _build_and_inject_function(expression_module, expr)
    end
end

function get_unimplemented_expr(dargs)
    Func(dargs, [], term(throw_missing_specialization, length(dargs)))
end

SymbolicUtils.Code.get_rewrites(x::Arr) = SymbolicUtils.Code.get_rewrites(unwrap(x))

function build_function(op::Union{Arr, ArrayOp, SymbolicUtils.SymbolicUtils.BasicSymbolic{<:AbstractArray}}, 
                        args...;
                        conv = toexpr,
                        expression = Val{true},
                        expression_module = @__MODULE__(),
                        checkbounds = false,
                        states = LazyState(),
                        linenumbers = true,
                        cse = false,
                        nanmath = true,
                        wrap_code = (identity, identity),
                        kwargs...)

    op = _recursive_unwrap(op)
    dargs = map((x) -> destructure_arg(x[2], !checkbounds, default_arg_name(x[1])), enumerate(collect(args)))
    states.rewrites[:nanmath] = nanmath

    outsym = DEFAULT_OUTSYM
    body = inplace_expr(op, outsym)
    iip_expr = wrap_code[2](Func(vcat(outsym, dargs), [], body))

    if cse
        iip_expr = Code.cse(iip_expr)
    end

    iip_expr = conv(iip_expr, states)

    if !checkbounds
        @assert Meta.isexpr(iip_expr, :function)
        iip_expr.args[2] = :(@inbounds begin; $(iip_expr.args[2]); end)
    end
    if expression == Val{true}
        return iip_expr
    else
        return _build_and_inject_function(expression_module, iip_expr)
    end
end

function _build_and_inject_function(mod::Module, ex)

    if ex.head == :function && ex.args[1].head == :tuple
        ex.args[1] = Expr(:call, :($mod.$(gensym())), ex.args[1].args...)
    elseif ex.head == :(->)
        return _build_and_inject_function(mod, Expr(:function, ex.args...))
    end
    RuntimeGeneratedFunction(mod, mod, ex)
end

SymbolicUtils.Code.toexpr(n::Num, st) = toexpr(value(n), st)

function fill_array_with_zero!(x::AbstractArray)
    if eltype(x) <: AbstractArray
        foreach(fill_array_with_zero!, x)
    else
        fill!(x, false)
    end
    return x
end

function build_function(rhss::AbstractArray, args...;
                       conv=toexpr,
                       expression = Val{true},
                       expression_module = @__MODULE__(),
                       checkbounds = false,
                       postprocess_fbody=ex -> ex,
                       linenumbers = false,
                       outputidxs=nothing,
                       skipzeros = false,
                       force_SA = false,
                       similarto = nothing,
                       wrap_code = (nothing, nothing),
                       fillzeros = skipzeros && !(rhss isa SparseMatrixCSC),
                       states = LazyState(),
                       nanmath = true,
                       parallel=nothing, 
                       cse = false, 
                       kwargs...)
    if rhss isa SubArray
        rhss = copy(rhss)
    end
    rhss = _recursive_unwrap(rhss)
    states.rewrites[:nanmath] = nanmath
    # We cannot switch to ShardedForm because it deadlocks with
    # RuntimeGeneratedFunctions
    dargs = map((x) -> destructure_arg(x[2], !checkbounds,
                                  Symbol("ˍ₋arg$(x[1])")), enumerate([args...]))
    i = findfirst(x->x isa DestructuredArgs, dargs)
    if similarto === nothing
        similarto = force_SA ? SArray : i === nothing ? Array : dargs[i].name
    end

    out = Sym{Any}(DEFAULT_OUTSYM)
    iip_expr = Func(vcat(out, dargs), [], postprocess_fbody(set_array(parallel,
                                dargs,
                                out,
                                outputidxs,
                                rhss,
                                checkbounds,
                                skipzeros)))
    if wrap_code[2] !== nothing
        iip_expr = wrap_code[2](iip_expr)
    end

    if cse
        iip_expr = Code.cse(iip_expr)
    end

    iip_expr = conv(iip_expr, states)

    if !checkbounds
        @assert Meta.isexpr(iip_expr, :function)
        iip_expr.args[2] = :(@inbounds begin; $(iip_expr.args[2]); end)
    end
    if expression == Val{true}
        return iip_expr
    else
        return _build_and_inject_function(expression_module, iip_expr)
    end
end

_nnz(x::AbstractArray) = length(x)
_nnz(x::AbstractSparseArray) = nnz(x)
_nnz(x::Union{Base.ReshapedArray, LinearAlgebra.Transpose}) = _nnz(parent(x))

function make_array(s, dargs, arr, similarto)
    s !== nothing && Base.@warn("Parallel form of $(typeof(s)) not implemented")
    _make_array(arr, similarto)
end

function make_array(s::SerialForm, dargs, arr, similarto)
    _make_array(arr, similarto)
end

function make_array(s::ShardedForm, closed_args, arr, similarto)
    if arr isa AbstractSparseArray
        return term(SparseMatrixCSC, arr.m, arr.n, copy(arr.colptr), copy(arr.rowval), make_array(s, closed_args, arr.nzval, Vector))
    end
    per_task = ceil(Int, length(arr) / s.ncalls)
    slices = collect(Iterators.partition(arr, per_task))
    arrays = map(slices) do slice
        Func(closed_args, [], _make_array(slice, similarto)), closed_args
    end
    SpawnFetch{typeof(s)}(first.(arrays), last.(arrays), vcat)
end

struct Funcall{F, T}
    f::F
    args::T
end

(f::Funcall)() = f.f(f.args...)

function SymbolicUtils.Code.toexpr(p::SpawnFetch{MultithreadedForm}, st)

    args = isnothing(p.args) ? Iterators.repeated((), length(p.exprs)) : p.args

    spawns = map(p.exprs, args) do thunk, a
        ex = :($Funcall($(drop_expr(@RuntimeGeneratedFunction(@__MODULE__, toexpr(thunk, st), false))),          
                       ($(toexpr.(a, (st,))...),)))
        quote
            let
                task = Base.Task($ex)
                task.sticky = false
                Base.schedule(task)
                task
            end
        end
    end

    quote
        $(toexpr(p.combine, st))(map(fetch, ($(spawns...),))...)
    end
end

function SymbolicUtils.Code.toexpr(p::SpawnFetch{ShardedForm{false}}, st)
    args = isnothing(p.args) ?
              Iterators.repeated((), length(p.exprs)) : p.args
    spawns = map(p.exprs, args) do thunk, a
        :($(drop_expr(@RuntimeGeneratedFunction(@__MODULE__, toexpr(thunk, st), false)))($(toexpr.(a, (st,))...),))
    end
    quote
        $(toexpr(p.combine, st))($(spawns...))
    end
end

function nzmap(f, x::Union{Base.ReshapedArray, LinearAlgebra.Transpose})
    Setfield.@set x.parent = nzmap(f, x.parent)
end

function nzmap(f, x::SubArray)
    unview = copy(x)
    if unview isa Union{SparseMatrixCSC, SparseVector}
        n = nnz(unview)
        if n != length(unview.nzval)
            resize!(unview.nzval, n)
            resize!(unview.rowval, n)
        end
    end
    nzmap(f, unview)
end

function nzmap(f, x::AbstractSparseArray)
    Setfield.@set x.nzval = nzmap(f, x.nzval)
end
nzmap(f, x) = map(f, x)

_issparse(x::AbstractArray) = issparse(x)
_issparse(x::Union{SubArray, Base.ReshapedArray, LinearAlgebra.Transpose}) = _issparse(parent(x))

function setparent(arr, val)
    Setfield.@set arr.parent = val
end

function set_nzval(arr, val)
    Setfield.@set arr.nzval = val
end

## In-place version

function set_array(p, closed_vars, args...)
    p !== nothing && Base.@warn("Parallel form of $(typeof(p)) not implemented")
    _set_array(args...)
end

function set_array(s::SerialForm, closed_vars, args...)
    _set_array(args...)
end

function recursive_split(leaf_f, s, out, args, outputidxs, xs)
    cutoff = isnothing(s.cutoff) ? ceil(Int, length(xs) / (2*s.ncalls)) : s.cutoff
    if length(xs) <= cutoff
        return leaf_f(outputidxs, xs)
    else
        per_part = ceil(Int, length(xs) / s.ncalls)
        slices = collect(Iterators.partition(zip(outputidxs, xs), per_part))
        fs = map(slices) do slice
            recursive_split(leaf_f, s, out, args, first.(slice), last.(slice))
        end
        return Func(args, [],
                    SpawnFetch{typeof(s)}(fs, [args for f in fs],
                                          (@inline noop(x...) = nothing)),
                    [])
    end
end

function set_array(s::ShardedForm, closed_args, out, outputidxs, rhss, checkbounds, skipzeros)

    if rhss isa AbstractSparseArray
        return set_array(s,
                         closed_args,
                         LiteralExpr(:($out.nzval)),
                         nothing,
                         rhss.nzval,
                         checkbounds,
                         skipzeros)
    end

    outvar = !(out isa Sym) ? gensym("out") : out

    if outputidxs === nothing
        outputidxs = collect(eachindex(rhss))
    end
    all_args = [outvar, closed_args...]
    ex = recursive_split(s, outvar, all_args, outputidxs, rhss) do idxs, xs
        Func(all_args, [],
             _set_array(outvar, idxs, xs, checkbounds, skipzeros),
             [])
    end.body

    return out isa Sym ? ex : LiteralExpr(quote
        $outvar = $out
        $ex
    end)
end

function _set_array(out, outputidxs, rhss::AbstractSparseArray, checkbounds, skipzeros)
    Let([Assignment(Symbol("%$out"), _set_array(LiteralExpr(:($out.nzval)), nothing, rhss.nzval, checkbounds, skipzeros))], out, false)
end

function _set_array(out, outputidxs, rhss::AbstractArray, checkbounds, skipzeros)
    if parent(rhss) !== rhss
        return _set_array(out, outputidxs, parent(rhss), checkbounds, skipzeros)
    end
    if outputidxs === nothing
        outputidxs = collect(eachindex(rhss))
    end
    indexes = AtIndex[]
    for (i, outi) in enumerate(outputidxs)
        if !(rhss[i] isa AbstractArray) && !(skipzeros && _iszero(rhss[i]))
            push!(indexes, AtIndex(outi, rhss[i]))
        elseif rhss[i] isa AbstractArray
            push!(indexes, AtIndex(outi, _set_array(LiteralExpr(:($out[$outi])), nothing, rhss[outi], checkbounds, skipzeros)))
        end
    end
    return SetArray(!checkbounds, out, indexes, true)
end

_set_array(out, outputidxs, rhs, checkbounds, skipzeros) = rhs

end # module Code


# This overload for Symbolics.jl types is necessary until the following issue is
# addressed
# https://github.com/JuliaSymbolics/Symbolics.jl/issues/930
function Base.in(x::Num, itr::Vector{Num})

    for y in itr
    
        if isequal(x, y)
            return true
        end
    end
    return false
end
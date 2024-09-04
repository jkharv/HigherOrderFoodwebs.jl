# The code in this file is concernced with parsing the expressions passed to the 
# @functional_form macro and packaging it into a tidy format with all the data needed
# to create the necessary parameters and build the function that will actually get 
# assigned to a node.

"""
    parse_variables(ex::Expr)::RenameDict

Parses the variables used in the function template.
"""
function parse_variables(ex::Expr)::Vector{TemplateObject}

    # Deal with the block possibly containing forward _and_ backward functions.
    ex.head == :block ? ex = ex.args[1] : ex = ex
    lhs = ex.args[1]

    if lhs isa Symbol

        # One variable case
        # x -> f(x)
        return [TemplateScalarVariable(lhs, missing, missing)]
    end
    if lhs.head == :tuple

        # Explicit mulivariable case
        # (x, y) = f(x,y)
        return [TemplateScalarVariable(var, missing, missing) for var in lhs.args]
    end
    if lhs.head == :ref

        # Implicit multivariable case
        # x[] -> f(x[])
        return [TemplateVectorVariable(lhs.args[1], missing, missing)]
    end
end

"""
    parse_function(ex::Expr)

Parses the function template itself
"""
function parse_function(ex::Expr)

    if ex.head == :block
        # There's two equations in the block, 
        # it's asymmetric fowards & back.
        ff = ex.args[1].args[2]        
        bf = ex.args[2].args[2] 
        return (ff = ff, bf = bf)
    else
        # There's only one equation in the block, 
        # it's symmetric forwards & back.
        f = ex.args[2]
        return (ff = f, bf = f)
    end
end
# The code in this file is concernced with parsing the expressions passed to the 
# @functional_form macro and packaging it into a tidy format with all the data needed
# to create the necessary parameters and build the function that will actually get 
# assigned to a node.

"""
    parse_parameters(ex::Tuple{Vararg{Union{Expr, Symbol}}})::RenameDict

Parses the parameter block that at the end of a @functional_form
"""
function parse_parameters(ex::Tuple{Vararg{Union{Expr, Symbol}}})::RenameDict

    params = RenameDict()

    for p ∈ ex

        p isa Symbol  ? error("Parameter $p is declared but not given any value.") :
        !(p isa Expr) ? error("Parameter $p is declared with invalid syntax.") :

        # Simple scalar parameter. eg. p
        if p.args[2] isa Symbol 
        
            param = p.args[2]
            val = DistributionOption(eval(p.args[3]))
        
            paramsymbol = TemplateScalarParameter(param, val)
            params[paramsymbol] = missing # No replacement yet
        
        # Vector of parameters. eg. p[]
        elseif p.args[2] isa Expr
               
            param = p.args[2].args[1]
            val = DistributionOption(eval(p.args[3]))

            paramsymbol = TemplateVectorParameter(param, val)
            params[paramsymbol] = missing 
        else
            error("Parameter $p is declared with invalid syntax.")
        end
    end

    return params
end

"""
    parse_variables(ex::Expr)::RenameDict

Parses the variables used in the function template.
"""
function parse_variables(ex::Expr)::RenameDict

    # Deal with the block possibly containing forward _and_ backward functions.
    ex.head == :block ? ex = ex.args[1] : ex = ex
    lhs = ex.args[1]

    vars = RenameDict()

    if lhs isa Symbol

        # One variable case
        # x -> f(x)
        var = TemplateScalarVariable(lhs, missing)
        vars[var] = missing 
    elseif lhs.head == :tuple

        # Explicit mulivariable case
        # (x, y) = f(x,y)
        for var in lhs.args
            var = TemplateScalarVariable(var, missing)
            vars[var] = missing
        end
    elseif lhs.head == :ref

        # Implicit multivariable case
        # x[] -> f(x[])
        var = TemplateVectorVariable(lhs.args[1], missing)
        vars[var] = missing
    end

    return vars
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
"""
    @functional_form node begin

        x -> a*e*x # Forwards function
        x -> a*x   # Backwards function
    end a e

The `@functional_form` macro takes care of creating a symbolic function and adding it to a
`Node` or `Vector{Node}`. It replaces the placeholder variable `x` with the variable
representing the supplied node and disambiguates the parameters being declared from 
similarily named parameters on different interactions.

If two functions are supplied as in the above example, the first function is the "forwards
function" and represents the amount of biomass addition to the subject of the interaction.
the second function is the "backwards function" which represents the amount of biomass
being removed from the object of the interaction. The difference between these two
functions is the loss from the system.

When this asymmetry is not required, you only need to define one function. In this case
both the forwards and backwards function of the node are identical. This is the case
for loops, such as growth, where deaths and growth can be collected into the same 
expression (net growth). 

    @functional_form node begin

        x -> x*r*(1 - x/k)
    end r k
"""
macro functional_form(node, func, params...)

    # Clean up the structure a little bit.
    func = unblock(func)
    func = prewalk(rmlines, func)
    
    vars = parse_variables(func)
    params = parse_parameters(params)
    fn = parse_function(func)
    fn = FunctionTemplate(fn.ff, fn.bf, merge!(params, vars))

    return quote

        create_node_function!($(esc(node)), $fn)
    end
end
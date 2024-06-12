function Base.show(io::IO, ::MIME"text/plain", fwm::FoodwebModel)

    str = """
    $(typeof(fwm))
        → $(length(fwm.hg.species.vertices)) species
        → $(length(fwm.hg.interactions)) interactions"""
   
    print(io, str)
end

function Base.show(io::IO, ::MIME"text/plain", dr::DynamicalRule)

    str = """
    DynamicalRule
        f.f.: $(dr.forwards_function)
        b.f.: $(dr.backwards_function)
        Variables: $(dr.vars)
        Parameters: $(dr.params)
    """
    
    print(io, str)
end
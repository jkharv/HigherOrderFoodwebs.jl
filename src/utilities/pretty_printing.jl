function Base.show(io::IO, ::MIME"text/plain", fwm::FoodwebModel)

    str = """
    $(typeof(fwm))
        → $(length(species(fwm))) species
        → $(length(interactions(fwm))) interactions"""
   
    print(io, str)
end

function Base.show(io::IO, ::MIME"text/plain", dr::DynamicRule)

    str = """
    DynamicRule
        f.f.: $(dr.forwards_function)
        b.f.: $(dr.backwards_function)
        Variables: $(dr.vars)
        Parameters: $(dr.params)
    """
    
    print(io, str)
end

function Base.show(io::IO, ::MIME"text/plain", cm::CommunityMatrix)

    println(io, "Community Matrix")
end


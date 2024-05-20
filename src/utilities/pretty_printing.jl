function Base.show(io::IO, ::MIME"text/plain", fwm::FoodwebModel)

    str = """
    $(typeof(fwm))
        → $(length(fwm.hg.species.vertices)) species
        → $(length(fwm.hg.interactions)) interactions"""
   
    print(io, str)
end
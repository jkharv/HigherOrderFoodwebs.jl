function Base.show(io::IO, ::MIME"text/plain", dr::DynamicRule)

    str = """
    DynamicRule
        f.: $(dr.f)
        Variables: $(dr.vars)
    """
    
    print(io, str)
end
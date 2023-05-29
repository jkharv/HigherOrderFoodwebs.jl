"""
    get_resource_interactions(sp::String, hg::EcologicalHypergraph)::Vector{Edge}

Given a species, this function will return all the interations it has with all its
resources.
"""
function get_resource_interactions(sp::String, 
    hg::EcologicalHypergraph)

    ints = interactions(hg)
    filter(x -> (species(subject(x)) == sp) & !isloop(x), ints)
    
end

function add_optimal_foraging_modifiers!(hg)

        modifiers = Vector{Node}()

    # Yuck, there must be a better way of doing this.
    for sp in species(hg)
    
        resource_interactions = get_resource_interactions(sp, hg)
        for ri ∈ resource_interactions
            for mod ∈ resource_interactions   
                resource = species(object(mod))
                focal_resource = species(object(ri))

                # Add modifier nodes only representing _alternative_ resources.
                if resource != focal_resource

                    n = add_modifier!(ri, resource)    
                    push!(modifiers, n)
                end
            end
        end
    end
    return modifiers
end
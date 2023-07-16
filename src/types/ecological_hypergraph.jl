mutable struct FunctionalForm
    
    func_forwards::Num
    func_backwards::Num

    params::Dict{Num, DistributionOption}
    vars::Vector{Num}

    function FunctionalForm(edge, species)

        varnames = Symbol.(species)
        
        vars = Vector{Num}()
        sizehint!(vars, length(varnames))

        for v in varnames

            var = @variables $v(edge.hypergraph.t)
            append!(vars, var)
        end
       
        new(Num(1), Num(1), Dict(), vars) 
    end
end

"""
Represents a node in the annotated hypergraph. Stores the species and the role
it plays in it's edge.
"""
mutable struct Node

    # See https://github.com/JuliaLang/julia/issues/269 Hopefully in the future 
    # circularly defined types will be possible.
    edge::Any

    species::Vector{String}
    role::Symbol

    func::FunctionalForm
       
    function Node(edge, species::Vector{String}, role::Symbol)

        func = FunctionalForm(edge, species)

        new(edge, species, role, func)
    end
end

function Node(edge, species::String, role::Symbol)

    Node(edge, [species], role)
end

"""
Represents a hyperedge in EcologicalHypergraph.

"""
mutable struct Edge

    hypergraph::Any
    nodes::Vector{Node}

    function Edge(hypergraph, nodes::Vector{Node})

        new(hypergraph, nodes)
    end
end

"""
Type represeting an EcologicalHypergraph hypergraph.

Implements an Annotated Hypergraph as described in Chodrow and Mellow (2020)
"""
mutable struct EcologicalHypergraph

    edges::Vector{Edge}
    species::Vector{String}
    roles::Vector{Symbol}

    t::Num # Single time_var for representing t w/ ModelingToolkit.

    vars::Dict{Num, DistributionOption}

    function EcologicalHypergraph(edges::Vector{Edge}, 
                                  species::Vector{String}, 
                                  roles::Vector{Symbol})

        roles = append!(roles, [:subject, :object]) 

        time_var = :t 
        time_var = @variables $time_var

        vars = Dict{Num, DistributionOption}()

        new(edges, species, roles, time_var[1], vars)
    end
end

function EcologicalHypergraph(adjm::AbstractMatrix, spp::Vector{String})

    if(size(adjm[1]) != size(adjm[2]))

        throw(ArgumentError("An adjacency matrix must be square."))
    end

    non_zero_indices = findall(x -> !iszero(x), adjm)
    L = length(non_zero_indices)

    edges = Vector{Edge}(undef, L)
    H = EcologicalHypergraph(edges, spp, Vector{Symbol}())

    for l in 1:L
        
        sub, obj = Tuple(non_zero_indices[l])
        edges[l] = Edge(H, Vector{Node}(undef, 2))
        n1 = Node(edges[l], spp[sub], :subject)
        n2 = Node(edges[l], spp[obj], :object)
        edges[l].nodes = [n1, n2] 

        vn1 = Dict(n1.func.vars .=> [DistributionOption(2.0)])
        vn2 = Dict(n1.func.vars .=> [DistributionOption(2.0)])

        merge!(H.vars, vn1)
        merge!(H.vars, vn2)
    end

    return H
end

"""
    EcologicalHypergraph(network::UnipartiteNetwork{Bool, String}, add_self = true)

Constructor for `EcologicalHypergraph`
Convert a network from `EcologicalNetworks.jl` into an EcologicalHypergraph.
"""
function EcologicalHypergraph(network::UnipartiteNetwork{Bool, String}; add_self = true)

    edges = Matrix(network.edges)

    if add_self

        for i in 1:length(species(network))
            
            if !edges[i, i]

                edges[i, i] = true
            end
        end
    end

    return EcologicalHypergraph(edges, species(network))
end
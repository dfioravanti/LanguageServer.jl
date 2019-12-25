abstract type Outbound end
abstract type HasMissingFields end

function JSON.Writer.CompositeTypeWrapper(t::HasMissingFields)
    fns = collect(fieldnames(typeof(t)))
    dels = Int[]
    for i = 1:length(fns)
        f = fns[i]
        if getfield(t, f) isa Missing
            push!(dels, i)
        end
    end
    deleteat!(fns, dels)
    JSON.Writer.CompositeTypeWrapper(t, Tuple(fns))
end


include("utils.jl")
include("basic.jl")
include("initialize.jl")
include("document.jl")
include("features.jl")
include("configuration.jl")


mutable struct CancelParams
    id::Union{String,Int64}
end
CancelParams(d::Dict) = CancelParams(d["id"])
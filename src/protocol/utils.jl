function field_allows_missing(field::Expr)
    field.head == :(::) && field.args[2] isa Expr &&
    field.args[2].head == :curly && field.args[2].args[1] == :Union &&
    last(field.args[2].args) == :Missing
end

function field_type(field::Expr)
    if field.args[2] isa Expr && field.args[2].head == :curly && field.args[2].args[1] == :Union
        return field.args[2].args[2]
    else
        return field.args[2]
    end
end

"""
    @dict_readable(arg)

A macro that given a structure creates a constructor for that structure that accepts 
a Dict as input. The Dict is assumed to have as keys the various fieldnames of the 
structure. For example for the structure
```
@dict_readable struct LocationLink <: Outbound
    originalSelectionRange::Union{Range,Missing}
    targetUri::DocumentUri
    targetRange::Range
    targetSelectionRange::Range
end
```
it produces the following constructor
```
function LocationLink(dict::Dict) 
    LocationLink(
            if haskey(dict, "originalSelectionRange")
                Range(dict["originalSelectionRange"])
            else
                missing
            end,
            DocumentUri(dict["targetUri"]), 
            Range(dict["targetRange"]), 
            Range(dict["targetSelectionRange"])
            )
end
```
"""
macro dict_readable(arg)
    tname = arg.args[2] isa Expr ? arg.args[2].args[1] : arg.args[2]
    ex = quote
        $((arg))

        function $((tname))(dict::Dict)
        end
    end
    fex = :($((tname))())
    for field in arg.args[3].args
        if !(field isa LineNumberNode)
            fieldname = string(field.args[1])
            fieldtype = field_type(field)
            if fieldtype isa Expr && fieldtype.head == :curly && fieldtype.args[2] != :Any
                f = :($(fieldtype.args[2]).(dict[$fieldname]))
            elseif fieldtype != :Any
                f = :($(fieldtype)(dict[$fieldname]))
            else
                f = :(dict[$fieldname])
            end
            if field_allows_missing(field)
                f = :(haskey(dict,$fieldname) ? $f : missing)
            end
            push!(fex.args, f)
        end
    end
    push!(ex.args[end].args[2].args, fex)
    return esc(ex)
end

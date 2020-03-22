module PythontexProfiler

export profile

using DataFrames
using PrettyTables
import Base: parse, push!

struct RuntimeData
    files::Vector{String}
    lines::Vector{Int32}
    times::Vector{Float64}
    bytes::Vector{Int64}
    gctimes::Vector{Float64}
end

RuntimeData() = RuntimeData(String[], Int32[], Float64[], Int64[], Float64[])

function push!(D::RuntimeData, file, line, time, bytes, gctime)
    push!(D.files, file)
    push!(D.lines, line)
    push!(D.times, time)
    push!(D.bytes, bytes)
    push!(D.gctimes, gctime)
end

function to_df(D::RuntimeData)
    d = DataFrame(file=D.files, line=D.lines, time=D.times, bytes=D.bytes, gctime=D.gctimes)
    sort!(d, [:time, :bytes, :gctime, :file], rev=true)
    return d
end

to_pretty_table(D::RuntimeData) = pretty_table(to_df(D), nosubheader=true)

function profile(filename::String)
    D = RuntimeData()
    file = ""
    line = 0
    name3 = ""
    o = nothing
    open(filename) do file
        for ln in eachline(file)
            m = match(r"=>PYTHONTEX#\w+#(?<name1>\w+)#(?<name2>\w+)#(?<num>\d+)#(?<name3>\w+)####(?<file>[\w\-\.]*)#(?<line>\d+)#", ln)
            if m != nothing
                if o != nothing && (name3 == "c" || name3 == "code")
                    code = String(take!(o))
                    val, t, bytes, gctime, memallocs = @timed include_string(Main, code)
                    push!(D, file, line, t, bytes, gctime)
                end
                file = m[:file]
                line = parse(Int32, m[:line])
                name3 = m[:name3]
                o = IOBuffer()
                println("Running $file:$line")
            else
                if occursin(r"^=>PYTHONTEX:SETTINGS", ln)
                    if o != nothing && (name3 == "c" || name3 == "code")
                        code = String(take!(o))
                        val, t, bytes, gctime, memallocs = @timed include_string(Main, code)
                        push!(D, file, line, t, bytes, gctime)
                    end
                    break
                else
                    println(o, ln)
                end
            end
        end
    end

    return to_pretty_table(D)
end

end # module

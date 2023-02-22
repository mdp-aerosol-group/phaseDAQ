const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.55, 0.0, 0, 1)
const mblue = RGBA(0.31, 0.58, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const lpm = 1.666666e-5
const bufferlength = 400

const path = Signal("")
const outfile = Signal("")

function newfile()
    a = pwd() |> x -> split(x, "/")
    datestr = Dates.format(now(), "yyyymmdd")
    datetimestr = Dates.format(now(), "yyyymmdd_HHMMSS")
    thepath = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/PhasePOPS/" * datestr
    read(`mkdir -p $thepath`)
    push!(path, thepath)
    push!(outfile, "PhasePOPS_" * datetimestr * ".csv")
    sleep(0.4)
    x = path.value*"/"*outfile.value
    read(`touch $x`)
end

newfile()

const rampTE1 = Reactive.Signal(false)
const stateTE1 = Reactive.Signal(:Manual)
const imgCounter = Signal(1)
const currentT = Signal(0.0)

# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Float64)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Float64, x)
    catch
        y = default
    end
end

# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Missing)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Float64, x)
    catch
        y = missing
    end
end

function parse_box(s::String, default)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Float64, x)
    catch
        y = default
    end
end

function parse_box(s::String)
    x = get_gtk_property(gui[s], :active_id, String)
    y = Symbol(x)
end

function parse_missing(N)
    str = try
        @sprintf("%.1f", N)
    catch
        "missing"
    end

    return str
end

function parse_missing1(N)
    str = try
        @sprintf("%.2f", N)
    catch
        "missing"
    end

    return str
end

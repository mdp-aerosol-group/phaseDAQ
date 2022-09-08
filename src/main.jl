
using Gtk
using GtkReactive
using InspectDR
using Reactive
using Colors
using DataFrames
using Printf
using Dates
using CSV
using FileIO
using LibSerialPort
using Interpolations
using Statistics
using NumericIO
using TETechTC3625RS232
using DifferentialMobilityAnalyzers
using LabjackU6Library
using POPS


const gui = GtkBuilder(filename = pwd() * "/gui.glade")
const wnd = gui["mainWindow"]
const serialPort = get_gtk_property(gui["TESerialPort1"], "text", String)
const portTE1 = TETechTC3625RS232.configure_port(serialPort)

@isdefined(task1) || (task1 = @async POPS.UDPdataLoop())
@isdefined(task2) || (task2 = @async POPS.UDPmsgLoop())
@isdefined(task3) || (task3 = @async POPS.UDPsendLoop())

sleep(3)

#const HANDLE = openUSBConnection(-1)
#const caliInfo = getCalibrationInformation(HANDLE)
const V = Signal(0.0)
const powerSMPS = Signal(true)
#TETechTC3625RS232.turn_power_off(portTE1)
include("global_variables.jl")  # Reactive Signals and global variables
include("te_io.jl")             # Thermoelectric Signals (wavefrom)
include("gtk_graphs.jl")        # push graphs to the UI#
include("setup_graphs.jl")      # Initialize graphs 
include("daq_loops.jl")         # Contains DAQ loops               
include("gtk_callbacks.jl")     # Link gui to signals               
include("dma_control.jl")       # Classifier logic
include("labjack_io.jl")        # Labjack Input/Output
include("hygroclip_io.jl")      # Rotronic Input/Output

Gtk.showall(wnd)                # Show GUI

const signalV = map(calibrateVoltage, V) 
const labjack_signals = map((v0, p0) -> labjackReadWrite(v0, p0), signalV, powerSMPS)

# Generate signals
sampleHz = fps(1.0 * 1.0015272)
main_elapsed_time = foldp(+, 0.0, sampleHz)     # Main timer
TE1_elapsed_time = foldp(+, 0.0, sampleHz)      # Time since last state change
TE1setT, TE1reset = TE1_signals()               # Signal for setpoint Temperature

function main()
    @async sampleHz_data_file()         # Write data file
    #@async sampleHz_generic_loop()      # generic daq 
end

mainloop = map(_ -> main(), sampleHz)   # run master loop

function displayDataPacket(p)
    str = try
        msg = deepcopy(p[53:end])
        data = ntoh.(reinterpret(Float32, msg))
        i = length(data)
        n = (i > 300) ? 300 : n
        strs1 = map(x -> @sprintf(",%.2f", data[x]), 1:n)
        strs2 = map(x -> @sprintf(",%.2f", data[x]), i-18:i-1)
        join(hcat(String(p[1:51]), strs1..., strs2...))
    catch
        "missing"
    end
    set_gtk_property!(gui["UDPtextBuffer"], :text, str)
end

function displayDecodedPacket(p)
    qstr = @sprintf("%.3f", p.q)
    cstr = @sprintf("%.1f", p.c)
    countstr = @sprintf("%i", sum(p.ph))
    set_gtk_property!(gui["POPSq"], :text, qstr)
    set_gtk_property!(gui["POPSc"], :text, cstr)
    set_gtk_property!(gui["POPScount"], :text, countstr)
    t = main_elapsed_time.value
    addpoint!(t, p.c, POPSConc, gplotConc, 1, true)
    addpoint!(t, p.q, POPSFlow, gplotFlow, 1, false)
    graph = POPSFlow.strips[1]
    graph.yext = InspectDR.PExtents1D() 
    graph.yext_full = InspectDR.PExtents1D(0.0, 0.4)
    addpoint!(t, sum(p.ph), POPSCount, gplotCount, 1, true)
    try
        x = range(p.config[7], stop = p.config[8], length = p.nbins) |> collect
        addseries!(exp10.(x), p.ph, POPSHist, gplotHist, 1, true, true)
    catch
    end
end

PacketLoop = map(displayDataPacket, POPS.UDPdataPacket)
MsgLoop = map(p -> set_gtk_property!(gui["UDPmsgBuffer"], :text, String(p)), POPS.UDPmsgPacket)

val = get_gtk_property(updateBins, :value, Int) |> POPS.setBins
sleep(1)
val = get_gtk_property(updateLogmin, :value, Float64) |> POPS.setLogMin
sleep(1)
val = get_gtk_property(updateLogmax, :value, Float64) |> POPS.setLogMax
sleep(1)

DecodeLoop = map(displayDecodedPacket, POPS.decodedUDP)

    
#wait(Godot)

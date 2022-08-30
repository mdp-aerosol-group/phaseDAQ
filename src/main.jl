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

const gui = GtkBuilder(filename = pwd() * "/gui.glade")  
const wnd = gui["mainWindow"]
const serialPort = get_gtk_property(gui["TESerialPort1"], "text", String)
const portTE1 = TETechTC3625RS232.configure_port(serialPort)
#const HANDLE = openUSBConnection(-1)
#const caliInfo = getCalibrationInformation(HANDLE)

const V = Signal(0.0)
const powerSMPS = Signal(true)

TETechTC3625RS232.turn_power_off(portTE1)

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
#const labjack_signals = map((v0, p0) -> labjackReadWrite(v0, p0), signalV, powerSMPS)

# Generate signals
sampleHz = fps(1.0 * 1.0015272) 
main_elapsed_time = foldp(+, 0.0, sampleHz)     # Main timer
TE1_elapsed_time = foldp(+, 0.0, sampleHz)      # Time since last state change
TE1setT, TE1reset = TE1_signals()               # Signal for setpoint Temperature

function main()
    @async sampleHz_data_file()         # Write data file
    @async sampleHz_generic_loop()      # Generic DAQ 
end

MainLoop = map(_ -> main(), sampleHz)   # Run Master Loop

wait(Godot)

te1Mode = gui["TE1Mode"]
signal_connect(te1Mode, "changed") do widget, others...
    push!(stateTE1, get_gtk_property(te1Mode, "active-id", String) |> Symbol)
end

updatePower = Signal(false)
te1Power = gui["power"]
signal_connect(te1Power, "state-set") do widget, others...
    push!(updatePower, true)
end

updateBandwidth = Signal(false)
te1Proportional = gui["proportional"]
signal_connect(te1Proportional, "value-changed") do widget, others...
    push!(updateBandwidth, true)
end

updateIntegral = Signal(false)
te1Integral = gui["integral"]
signal_connect(te1Integral, "value-changed") do widget, others...
    push!(updateIntegral, true)
end

updateDerivative = Signal(false)
te1Derivative = gui["derivative"]
signal_connect(te1Derivative, "value-changed") do widget, others...
    push!(updateDerivative, true)
end

updateThermistor = Signal(false)
te1Thermistor = gui["thermistor"]
signal_connect(te1Thermistor, "changed") do widget, others...
    push!(updateThermistor, true)
end

updatePolarity = Signal(false)
te1Polarity = gui["polarity"]
signal_connect(te1Polarity, "changed") do widget, others...
    push!(updatePolarity, true)
end

updateBins = gui["nbins"]
signal_connect(updateBins, "value-changed") do widget, others...
    val = get_gtk_property(updateBins, :value, Int)
    POPS.setBins(val)
    sleep(2)
    newfile()
end

updateLogmin = gui["logmin"]
signal_connect(updateLogmin, "value-changed") do widget, others...
    val = get_gtk_property(updateLogmin, :value, Float64)
    POPS.setLogMin(val)
end

updateLogmax = gui["logmax"]
signal_connect(updateLogmax, "value-changed") do widget, others...
    val = get_gtk_property(updateLogmax, :value, Float64)
    POPS.setLogMax(val)
end

rebootSBRIO = gui["reboot"]
signal_connect(rebootSBRIO, "pressed") do widget, others...
    POPS.reboot()
end

newfileSignal = gui["newfile"]
signal_connect(newfileSignal, "pressed") do widget, others...
    newfile()
end

Godot = @task _ -> false
id = signal_connect(x -> schedule(Godot), gui["closeButton"], "clicked")
Godot = @task _ -> false

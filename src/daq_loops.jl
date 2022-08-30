function sampleHz_data_file()
    ts = now()     

    sampleHz_df = DataFrame(
        Timestamp = ts,
        Unixtime = datetime2unix(ts),
        Int64time = Dates.value(ts),
        LapseTime = @sprintf("%.3f", main_elapsed_time.value),
        state = stateTE1.value,
        T1 = parse_box("TE1ReadT1", missing),
        T2 = parse_box("TE1ReadT2", missing),
        TSet = TE1setT.value,
        RH = parse_box("readRH", missing),
        T = parse_box("readT", missing),
        Vset = V.value,
        Vread = parse_box("readV", missing),
        Iread = parse_box("readI", missing),
    )

    sampleHz_df |> CSV.write(path * "/" * outfile, append = true)
end

function sampleHz_generic_loop()
    push!(powerSMPS, true)
    t = main_elapsed_time.value
    set_gtk_property!(gui["Timer"], :text, Dates.format(now(), "HH:MM:SS"))
    if updatePower.value == true
        value = get_gtk_property(gui["power"], :state, Bool)
        ret =
            (value == true) ? TETechTC3625RS232.turn_power_on(portTE1) :
            TETechTC3625RS232.turn_power_off(portTE1)
        state = (value == true) ? " is on" : " is off"
        @printf("Power%s\n", state)
        push!(updatePower, false)
    end

    if updateBandwidth.value == true
        value = get_gtk_property(gui["proportional"], :value, Float64)
        ret = TETechTC3625RS232.write_proportional_bandwidth(portTE1, value)
        @printf("Set proportional bandwidth to %f\n", ret)
        push!(updateBandwidth, false)
    end

    if updateIntegral.value == true
        value = get_gtk_property(gui["integral"], :value, Float64)
        ret = TETechTC3625RS232.write_integral_gain(portTE1, value)
        @printf("Set integral gain to %f\n", ret)
        push!(updateIntegral, false)
    end

    if updateDerivative.value == true
        value = get_gtk_property(gui["derivative"], :value, Float64)
        ret = TETechTC3625RS232.write_derivative_gain(portTE1, value)
        @printf("Set derivative gain to %f\n", ret)
        push!(updateDerivative, false)
    end

    if updateThermistor.value == true
        value =
            get_gtk_property(gui["thermistor"], "active-id", String) |> x -> parse(Int, x)
        ret = TETechTC3625RS232.set_sensor_type(portTE1, value)
        @printf("Set thermistor type to %s\n", ret)
        push!(updateThermistor, false)
    end

    if updatePolarity.value == true
        value = get_gtk_property(gui["polarity"], "active-id", String) |> x -> parse(Int, x)
        ret = TETechTC3625RS232.set_sensor_type(portTE1, value)
        @printf("Set controller polarity to %s\n", ret)
        push!(updatePolarity, false)
    end

    TE1_T1 = TETechTC3625RS232.read_sensor_T1(portTE1)
    TE1_T2 = TETechTC3625RS232.read_sensor_T2(portTE1)
    Tcur = 0.5 * (TE1_T1 + TE1_T2)
    ismissing(Tcur) || push!(currentT, Tcur)
    Power = TETechTC3625RS232.read_power_output(portTE1)
    TETechTC3625RS232.set_temperature(portTE1, TE1setT.value)

    mode = get_gtk_property(te1Mode, "active-id", String) |> Symbol
    (mode == :Ramp) && set_gtk_property!(
        gui["TERampCounter1"],
        :text,
        @sprintf("%.1f", TE1_elapsed_time.value)
    )
    set_gtk_property!(gui["TE1ReadT1"], :text, parse_missing1(TE1_T1))
    set_gtk_property!(gui["TE1ReadT2"], :text, parse_missing1(TE1_T2))
    set_gtk_property!(gui["TE1PowerOutput"], :text, parse_missing1(Power))
    addpoint!(t, TE1setT.value, plotTemp, gplotTemp, 1, true)
    (typeof(TE1_T1) == Missing) || addpoint!(t, TE1_T1, plotTemp, gplotTemp, 2, true)
    #(typeof(TE1_T2) == Missing) || addpoint!(t,TE1_T2,plotTemp,gplotTemp,3,true)
    
    AIN, Tk, rawcount, count = labjack_signals.value 
    readV = AIN[1] |> (x -> (x * 1000.0))
    readI = AIN[2] |> (x -> -x * 0.167 * 1000.0)
    RH, T = AIN2HC(AIN, 3, 4)
    
    set_gtk_property!(gui["readV"], :text, @sprintf("%.1f", readV))
    set_gtk_property!(gui["readI"], :text, @sprintf("%.1f", readI))
    set_gtk_property!(gui["readRH"], :text, @sprintf("%.1f", RH))
    set_gtk_property!(gui["readT"], :text, @sprintf("%.1f", T))
end

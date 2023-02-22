function sampleHz_data_file()
    ts = now()

    state = stateTE1.value
    T1 = parse_box("TE1ReadT1", -990)
    T2 = parse_box("TE1ReadT2", -999)
    TSet = TE1setT.value
    RH = parse_box("readRH", -999)
    T = parse_box("readT", -999)
    Vset = V.value
    Vread = parse_box("readV", -999)
    Iread = parse_box("readI", -999)
    str1 =
        [
            Dates.format(ts, "yyyy-mm-ddTHH:MM:SS,"),
            @sprintf(
                "%i,%.3f,%s,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,",
                datetime2unix(ts),
                main_elapsed_time.value,
                state,
                T1,
                T2,
                TSet,
                RH,
                Vset,
                Vread,
                Iread
            )
        ] |> join


    p = POPS.UDPdataPacket.value
    str2 = try
        msg = deepcopy(p[53:end])
        data = ntoh.(reinterpret(Float32, msg))
        strs = map(x -> @sprintf(",%.2f", x), data)
        join(hcat(String(p[1:51]), strs...))
    catch
        "missing"
    end

    str = join([str1, str2, "\n"])
    open(path.value * "/" * outfile.value, "a") do f
        write(f, str)
    end
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
    (typeof(TE1_T2) == Missing) || addpoint!(t, TE1_T2, plotTemp, gplotTemp, 3, true)

    AIN, Tk, rawcount, count = labjack_signals.value
    readV = AIN[1] |> (x -> (x * 1000.0))
    readI = AIN[2] |> (x -> -x * 0.167 * 1000.0)
    RH, T = AIN2HC(AIN, 3, 4)

    set_gtk_property!(gui["readV"], :text, @sprintf("%.1f", readV))
    set_gtk_property!(gui["readI"], :text, @sprintf("%.1f", readI))
    set_gtk_property!(gui["readRH"], :text, @sprintf("%.1f", RH))
    set_gtk_property!(gui["readT"], :text, @sprintf("%.1f", T))

    p = POPS.decodedUDP.value
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

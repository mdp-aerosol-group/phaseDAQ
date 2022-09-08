function graph1(yaxis)
    plot = InspectDR.transientplot(yaxis, title = "")
    InspectDR.overwritefont!(plot.layout, fontname = "Arial", fontscale = 1.0)
    plot.layout[:enable_legend] = true
    plot.layout[:halloc_legend] = 160
    plot.layout[:halloc_left] = 50
    plot.layout[:enable_timestamp] = false
    plot.layout[:length_tickmajor] = 10
    plot.layout[:length_tickminor] = 6
    plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
    plot.layout[:frame_data] = InspectDR.AreaAttributes(
        line = InspectDR.line(style = :solid, color = black, width = 0.5),
    )
    plot.layout[:line_gridmajor] =
        InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

    plot.xext = InspectDR.PExtents1D()
    plot.xext_full = InspectDR.PExtents1D(0, 205)

    a = plot.annotation
    a.xlabel = "Time (s)"
    a.ylabels = ["Temperature (C)"]

    return plot
end

function size_distribution()
    plotPOPSSize = InspectDR.Plot2D(:log, :lin, title = "")
    InspectDR.overwritefont!(plotPOPSSize.layout, fontname = "Arial", fontscale = 1.0)
    plotPOPSSize.layout[:enable_legend] = true
    plotPOPSSize.layout[:halloc_legend] = 160
    plotPOPSSize.layout[:halloc_left] = 50
    plotPOPSSize.layout[:enable_timestamp] = false
    plotPOPSSize.layout[:length_tickmajor] = 10
    plotPOPSSize.layout[:length_tickminor] = 6
    plotPOPSSize.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
    plotPOPSSize.layout[:frame_data] = InspectDR.AreaAttributes(
        line = InspectDR.line(style = :solid, color = black, width = 0.5),
    )
    plotPOPSSize.layout[:line_gridmajor] =
        InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

    plotPOPSSize.xext = InspectDR.PExtents1D()
    plotPOPSSize.xext_full = InspectDR.PExtents1D(10, 65000)

    graph = plotPOPSSize.strips[1]
    graph.yext = InspectDR.PExtents1D()
    graph.yext_full = InspectDR.PExtents1D(0.001, 1000)

    graph = plotPOPSSize.strips[1]
    graph.grid =
        InspectDR.GridRect(vmajor = true, vminor = true, hmajor = true, hminor = true)

    a = plotPOPSSize.annotation
    a.xlabel = "Digitizer-PH Amplitude (ch)"
    a.ylabels = ["Counts"]

    return plotPOPSSize
end

style = :solid
plotTemp = graph1(:lin)
plotTemp.layout[:halloc_legend] = 110
mpTemp, gplotTemp = push_plot_to_gui!(plotTemp, gui["TempGraph1"], wnd)
wfrm = add(plotTemp, [0.0], [22.0], id = "Set T(°C)")
wfrm.line = line(color = black, width = 2, style = style)
wfrm = add(plotTemp, [0.0], [22.0], id = "T1 (°C)")
wfrm.line = line(color = mblue, width = 2, style = style)
wfrm = add(plotTemp, [0.0], [22.0], id = "T2 (°C)")
wfrm.line = line(color = red, width = 2, style = style)

style = :solid
POPSConc = graph1(:lin)
POPSConc.layout[:halloc_legend] = 110
mpConc, gplotConc = push_plot_to_gui!(POPSConc, gui["POPSConcentration"], wnd)
wfrm = add(POPSConc, [0.0], [22.0], id = "Conc (# cm-3)")
wfrm.line = line(color = black, width = 2, style = style)

style = :solid
POPSFlow = graph1(:lin)
POPSFlow.layout[:halloc_legend] = 110
mpFlow, gplotFlow = push_plot_to_gui!(POPSFlow, gui["POPSFlow"], wnd)
wfrm = add(POPSFlow, [0.0], [0.0], id = "Flow (L min-1)")
wfrm.line = line(color = black, width = 2, style = style)
graph = POPSFlow.strips[1]
graph.yext = InspectDR.PExtents1D()
graph.yext_full = InspectDR.PExtents1D(0, 0.4)

style = :solid
POPSCount = graph1(:lin)
POPSCount.layout[:halloc_legend] = 110
mpCount, gplotCount = push_plot_to_gui!(POPSCount, gui["CountData"], wnd)
wfrm = add(POPSCount, [0.0], [0.0], id = "Count (# s-1)")
wfrm.line = line(color = black, width = 2, style = style)

style = :solid
POPSHist = size_distribution()
POPSHist.layout[:halloc_legend] = 110
mpHist, gplotHist = push_plot_to_gui!(POPSHist, gui["Histogram"], wnd)
wfrm = add(POPSHist, [0.0], [0.0], id = "Count (# s-1)")
wfrm.line = line(color = black, width = 2, style = style)

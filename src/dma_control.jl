

function get_DMA_config(
    sheath::GtkSpinButtonLeaf,
    temp::GtkSpinButtonLeaf,
    dmat::GtkComboBoxTextLeaf,
    dmag::GtkComboBoxTextLeaf,
)
    Q = get_gtk_property(sheath, "value", Float64)
    T = get_gtk_property(temp, "value", Float64)
    column = get_gtk_property(dmat, :active_id, String) |> Symbol
    gas = get_gtk_property(dmag, :active_id, String) |> Symbol

    (column == :TSI) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    (column == :HFDMA) && ((r₁, r₂, l) = (0.05, 0.058, 0.6))
    (column == :RDMA) && ((r₁, r₂, l) = (2.4e-3, 50.4e-3, 10e-3))
    (column == :HELSINKI) && ((r₁, r₂, l) = (2.65e-2, 3.3e-2, 10.9e-2))
    (column == :VIENNASHORT) && ((r₁, r₂, l) = (25e-3, 33.5e-2, 0.11))
    (column == :VIENNAMEDIUM) && ((r₁, r₂, l) = (25e-3, 33.5e-2, 0.28))
    (column == :VIENNALONG) && ((r₁, r₂, l) = (25e-3, 33.5e-2, 0.50))

    form = (column == :RDMA) ? :radial : :cylindrical
    qsh = Q * lpm
    qsa = 0.1 * qsh
    t = T + 273.15
    p = 1013e2
    leff = 0.0
    polarity = :+

    Λ = DMAconfig(t, p, qsa, qsh, r₁, r₂, l, leff, polarity, 6, form, eval(Expr(:call, gas)))

    return Λ
end

calibrateVoltage(v) = getVdac((v*0.937 - 5.577), :+, true)

function getVdac(setV::Float64, polarity::Symbol, powerSwitch::Bool)
    (setV > 0.0) || (setV = 0.0)
    (setV < 10000.0) || (setV = 10000.0)

    if polarity == :-
        # Negative power supply +0.36V = -10kV, 5V = 0kV
        m = 10000.0 / (0.36 - 5.03)
        b = 10000.0 - m * 0.36
        setVdac = (setV - b) / m
        if setVdac < 0.36
            setVdac = 0.36
        elseif setVdac > 5.1
            setVdac = 5.1
        end
        if powerSwitch == false
            setVdac = 5.0
        end
    elseif polarity == :+
        # Positive power supply +0V = 0kV, 4.64V = 0kV
        m = 10000.0 / (4.64 - 0)
        b = 0
        setVdac = (setV - b) / m
        if setVdac < 0.0
            setVdac = 0.0
        elseif setVdac > 4.64
            setVdac = 4.64
        end
        if powerSwitch == false
            setVdac = 0.0
        end
    end
    return setVdac
end

function set_voltage(diam::GtkSpinButtonLeaf, destination::GtkEntryLeaf)
    D = get_gtk_property(diam, "value", Float64)
    mV = ztov(Λ.value, dtoz(Λ.value, D * 1e-9))
    if mV > 10000.0
        mV = 10000.0
        D = ztod(Λ.value, 1, vtoz(Λ.value, 10000.0))
        set_gtk_property!(diam, "value", round(D, digits = 0))
    elseif mV < 10.0
        mV = 10.0
        D = ztod(Λ.value, 1, vtoz(Λ.value, 10.0))
        set_gtk_property!(diam, "value", round(D, digits = 1))
    end
    set_gtk_property!(setV, :text, @sprintf("%0.0f", mV))
    push!(V, mV)
end

const diameterbox = gui["Diameter"]
const sheathbox = gui["SheathFlow"]
const dmatbox = gui["DMATemperature"]
const dmatype = gui["DMAType"]
const dmagas = gui["DMAGas"]
const setV = gui["setV"]

Λ = Signal(get_DMA_config(sheathbox, dmatbox, dmatype, dmagas))

const idA = signal_connect(sheathbox, "value-changed") do widget, others...
    push!(Λ, get_DMA_config(sheathbox, dmatbox, dmatype, dmagas))
end

const idB = signal_connect(dmatbox, "value-changed") do widget, others...
    push!(Λ, get_DMA_config(sheathbox, dmatbox, dmatype, dmagas))
end

const idC = signal_connect(dmatype, "changed") do widget, others...
    push!(Λ, get_DMA_config(sheathbox, dmatbox, dmatype, dmagas))
end

const idD = signal_connect(dmagas, "changed") do widget, others...
    push!(Λ, get_DMA_config(sheathbox, dmatbox, dmatype, dmagas))
end

const idE = signal_connect(diameterbox, "value-changed") do widget, others...
    set_voltage(diameterbox, setV)
end

const idF = map(_ -> set_voltage(diameterbox, setV), Λ)

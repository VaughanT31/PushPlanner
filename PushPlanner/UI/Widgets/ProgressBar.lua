-- PushPlanner - UI/Widgets/ProgressBar.lua
-- PP.Widgets.ProgressBar: current -> target rating bar with a target marker
-- tick. Built from flat colour textures, no StatusBar art required.

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.ProgressBar = {}
local ProgressBar = PP.Widgets.ProgressBar

function ProgressBar.New(parent, opts)
    opts = opts or {}
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(opts.width or 300, opts.height or 14)
    Theme:SkinPanel(frame, "panelAlt", "border")

    local fill = frame:CreateTexture(nil, "ARTWORK")
    fill:SetTexture(Theme.texture.white)
    fill:SetVertexColor(unpack(Theme.colors.good))
    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
    fill:SetWidth(1)

    local marker = frame:CreateTexture(nil, "OVERLAY")
    marker:SetTexture(Theme.texture.white)
    marker:SetVertexColor(unpack(Theme.colors.textTitle))
    marker:SetWidth(2)
    marker:SetPoint("TOP", frame, "TOP", 0, 2)
    marker:SetPoint("BOTTOM", frame, "BOTTOM", 0, -2)
    marker:Hide()

    frame.fill = fill
    frame.marker = marker

    local minValue, maxValue = 0, 1

    local function ClampPct(value)
        if maxValue <= minValue then return 0 end
        local pct = (value - minValue) / (maxValue - minValue)
        if pct < 0 then pct = 0 end
        if pct > 1 then pct = 1 end
        return pct
    end

    function frame:SetMinMax(newMin, newMax)
        minValue, maxValue = newMin, newMax
    end

    function frame:SetValue(value)
        local width = frame:GetWidth() - 2
        local pct = ClampPct(value)
        fill:SetWidth(math.max(width * pct, 1))
    end

    function frame:SetTarget(value)
        local width = frame:GetWidth() - 2
        local pct = ClampPct(value)
        marker:ClearAllPoints()
        marker:SetPoint("TOP", frame, "TOPLEFT", 1 + width * pct, 2)
        marker:SetPoint("BOTTOM", frame, "BOTTOMLEFT", 1 + width * pct, -2)
        marker:Show()
    end

    return frame
end

-- PushPlanner - UI/Widgets/StatCell.lua
-- PP.Widgets.StatCell: one of the summary chips (Current / Target / Gap).

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.StatCell = {}
local StatCell = PP.Widgets.StatCell

function StatCell.New(parent, opts)
    opts = opts or {}
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(opts.width or 120, opts.height or 46)
    Theme:SkinPanel(frame, "panel", "border")
    local strip = Theme:AccentStrip(frame, opts.accent or "borderAccent")

    local label = Theme:CreateFontString(frame, "sizeSmall", "textDim")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
    label:SetText(opts.label or "")

    local value = Theme:CreateFontString(frame, "sizeLarge", "text")
    value:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 6)
    value:SetText(opts.value or "-")

    frame.label = label
    frame.value = value
    frame.strip = strip

    -- The strip's colour; a { r, g, b } table or a theme colour key.
    function frame:SetAccent(color)
        local c = type(color) == "table" and color or Theme.colors[color] or Theme.colors.borderAccent
        strip:SetVertexColor(c[1], c[2], c[3], 1)
    end

    function frame:SetValue(text, colorKey)
        value:SetText(text)
        if colorKey then
            value:SetTextColor(unpack(Theme.colors[colorKey] or Theme.colors.text))
        end
    end

    return frame
end

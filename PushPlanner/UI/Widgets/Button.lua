-- PushPlanner - UI/Widgets/Button.lua
-- PP.Widgets.Button: a flat themed button with hover/pressed states.
-- Accent buttons (the primary call-to-action, e.g. Calculate) render as a
-- solid colour fill rather than a dark button with a coloured border.

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.Button = {}
local Button = PP.Widgets.Button

function Button.New(parent, opts)
    opts = opts or {}
    local accent = opts.accent
    local frame = CreateFrame("Button", nil, parent, "BackdropTemplate")
    frame:SetSize(opts.width or 100, opts.height or 22)

    local fillKey = accent and "accentFill" or "panelAlt"
    local hoverKey = accent and "accentFillHover" or "hover"
    local pressedKey = accent and "accentFillPressed" or "pressed"
    local textKey = accent and "textOnAccent" or "text"

    Theme:SkinPanel(frame, fillKey, fillKey)

    local text = Theme:CreateFontString(frame, "size", textKey)
    text:SetPoint("CENTER")
    text:SetText(opts.text or "")

    frame:SetScript("OnEnter", function() frame:SetBackdropColor(unpack(Theme.colors[hoverKey])) end)
    frame:SetScript("OnLeave", function() frame:SetBackdropColor(unpack(Theme.colors[fillKey])) end)
    frame:SetScript("OnMouseDown", function() frame:SetBackdropColor(unpack(Theme.colors[pressedKey])) end)
    frame:SetScript("OnMouseUp", function() frame:SetBackdropColor(unpack(Theme.colors[hoverKey])) end)

    if opts.onClick then
        frame:SetScript("OnClick", opts.onClick)
    end

    frame.text = text

    function frame:SetText(newText)
        text:SetText(newText)
    end

    function frame:SetEnabled(enabled)
        if enabled then
            frame:Enable()
            text:SetTextColor(unpack(Theme.colors[textKey]))
        else
            frame:Disable()
            text:SetTextColor(unpack(Theme.colors.textDim))
        end
    end

    return frame
end

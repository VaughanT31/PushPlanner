-- PushPlanner - UI/Widgets/Checkbox.lua
-- PP.Widgets.Checkbox: a small square toggle with a label, our own skin
-- (no UICheckButtonTemplate look).

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.Checkbox = {}
local Checkbox = PP.Widgets.Checkbox

local BOX_SIZE = 16

function Checkbox.New(parent, opts)
    opts = opts or {}

    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(opts.width or 160, BOX_SIZE)

    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetSize(BOX_SIZE, BOX_SIZE)
    box:SetPoint("LEFT", frame, "LEFT", 0, 0)
    Theme:SkinPanel(box, "panelAlt", "border")

    -- The game's own tick, in the title gold.
    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetPoint("CENTER", box, "CENTER", 1, 0)
    check:SetSize(BOX_SIZE + 4, BOX_SIZE + 4)
    check:SetVertexColor(unpack(Theme.colors.textTitle))
    check:Hide()

    local label = Theme:CreateFontString(frame, "size", "text")
    label:SetPoint("LEFT", box, "RIGHT", 6, 0)
    label:SetText(opts.label or "")

    local checked = opts.checked and true or false

    local function Refresh()
        if checked then
            check:Show()
            Theme:SkinPanel(box, "panelAlt", "borderAccent")
        else
            check:Hide()
            Theme:SkinPanel(box, "panelAlt", "border")
        end
    end
    Refresh()

    frame:SetScript("OnClick", function()
        checked = not checked
        Refresh()
        if opts.onChanged then
            opts.onChanged(checked)
        end
    end)

    frame:SetScript("OnEnter", function() label:SetTextColor(unpack(Theme.colors.textTitle)) end)
    frame:SetScript("OnLeave", function() label:SetTextColor(unpack(Theme.colors.text)) end)

    frame.box = box
    frame.label = label

    function frame:IsChecked()
        return checked
    end

    function frame:SetChecked(value)
        checked = value and true or false
        Refresh()
    end

    return frame
end

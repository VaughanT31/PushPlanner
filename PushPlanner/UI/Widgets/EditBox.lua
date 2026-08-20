-- PushPlanner - UI/Widgets/EditBox.lua
-- PP.Widgets.EditBox: a labelled text/number input ("Target Rating [___]").

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.EditBox = {}
local EditBox = PP.Widgets.EditBox

function EditBox.New(parent, opts)
    opts = opts or {}
    local width = opts.width or 140
    local height = opts.height or 40

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)

    local label = Theme:CreateFontString(frame, "sizeSmall", "textDim")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(opts.label or "")

    local box = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    box:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    box:SetHeight(22)
    Theme:SkinPanel(box, "panelAlt", "border")
    box:SetFont(Theme:GetFont(), Theme.font.size, "")
    box:SetTextColor(unpack(Theme.colors.text))
    box:SetTextInsets(6, 6, 0, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(opts.numeric and true or false)
    box:SetMaxLetters(opts.maxLetters or 8)

    if opts.text then
        box:SetText(tostring(opts.text))
    end

    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:SetText(opts.text or ""); self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function() Theme:SkinPanel(box, "panelAlt", "borderAccent") end)
    box:SetScript("OnEditFocusLost", function() Theme:SkinPanel(box, "panelAlt", "border") end)

    if opts.onChanged then
        box:SetScript("OnTextChanged", function(self, byUser)
            if byUser then
                opts.onChanged(self:GetText())
            end
        end)
    end

    frame.label = label
    frame.box = box

    function frame:GetValue()
        if opts.numeric then
            return tonumber(box:GetText()) or 0
        end
        return box:GetText()
    end

    function frame:SetValue(value)
        box:SetText(tostring(value))
    end

    return frame
end

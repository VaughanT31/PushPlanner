-- PushPlanner - UI/Widgets/Dropdown.lua
-- PP.Widgets.Dropdown: a custom multi-select dropdown (the "Avoid Dungeons"
-- selector). Not Blizzard's UIDropDownMenu - our own popout list of
-- checkboxes so it matches the house skin.

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.Dropdown = {}
local Dropdown = PP.Widgets.Dropdown

local ROW_HEIGHT = 20

local openDropdown = nil

-- Full-screen invisible catcher, shown only while a dropdown popout is open,
-- so a click anywhere outside the popout closes it. Sits below DIALOG
-- strata so the popout itself still receives its own clicks.
local catcher = CreateFrame("Button", nil, UIParent)
catcher:SetAllPoints(UIParent)
catcher:SetFrameStrata("HIGH")
catcher:Hide()

local function CloseOpenDropdown()
    if openDropdown then
        openDropdown.popout:Hide()
        openDropdown = nil
    end
    catcher:Hide()
end

catcher:SetScript("OnClick", CloseOpenDropdown)

function Dropdown.New(parent, opts)
    opts = opts or {}
    -- items: array of { value = ..., text = ... }
    local items = opts.items or {}
    local selected = {}
    for _, v in ipairs(opts.selected or {}) do
        selected[v] = true
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(opts.width or 160, 40)

    local label = Theme:CreateFontString(frame, "sizeSmall", "textDim")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    label:SetText(opts.label or "")

    local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
    button:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    button:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    button:SetHeight(22)
    Theme:SkinPanel(button, "panelAlt", "border")

    local buttonText = Theme:CreateFontString(button, "size", "text")
    buttonText:SetPoint("LEFT", button, "LEFT", 6, 0)
    buttonText:SetPoint("RIGHT", button, "RIGHT", -16, 0)
    buttonText:SetJustifyH("LEFT")
    buttonText:SetWordWrap(false)

    local arrow = Theme:CreateFontString(button, "sizeSmall", "textDim")
    arrow:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    arrow:SetText("v")

    local popout = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popout:SetFrameStrata("DIALOG")
    Theme:SkinPanel(popout, "panel", "borderAccent")
    popout:Hide()
    popout.rows = {}

    local function UpdateButtonText()
        local n = 0
        for _ in pairs(selected) do n = n + 1 end
        if n == 0 then
            buttonText:SetText(opts.emptyText or "None")
        elseif n == 1 then
            for _, item in ipairs(items) do
                if selected[item.value] then
                    buttonText:SetText(item.text)
                    break
                end
            end
        else
            buttonText:SetText(n .. " selected")
        end
    end

    local function BuildRows()
        popout:SetSize((opts.width or 160), #items * ROW_HEIGHT + 8)
        local prev
        for i, item in ipairs(items) do
            local row = popout.rows[i]
            if not row then
                row = PP.Widgets.Checkbox.New(popout, { label = item.text })
                row:SetPoint("LEFT", popout, "LEFT", 6, 0)
                popout.rows[i] = row
            end
            row.label:SetText(item.text)
            row:SetChecked(selected[item.value] and true or false)
            row:SetScript("OnClick", function(self)
                self:SetChecked(not self:IsChecked())
                selected[item.value] = self:IsChecked() or nil
                UpdateButtonText()
                if opts.onChanged then
                    opts.onChanged(selected)
                end
            end)
            row:ClearAllPoints()
            row:SetPoint("LEFT", popout, "LEFT", 6, 0)
            if prev then
                row:SetPoint("TOP", prev, "BOTTOM", 0, -2)
            else
                row:SetPoint("TOP", popout, "TOP", 0, -6)
            end
            row:Show()
            prev = row
        end
    end

    button:SetScript("OnClick", function()
        if popout:IsShown() then
            CloseOpenDropdown()
            return
        end
        CloseOpenDropdown()
        BuildRows()
        popout:ClearAllPoints()
        popout:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
        popout:Show()
        catcher:Show()
        openDropdown = frame
    end)

    UpdateButtonText()

    frame.button = button
    frame.popout = popout

    function frame:GetSelected()
        local out = {}
        for value, isSelected in pairs(selected) do
            if isSelected then
                table.insert(out, value)
            end
        end
        return out
    end

    function frame:SetSelected(list)
        selected = {}
        for _, v in ipairs(list or {}) do
            selected[v] = true
        end
        UpdateButtonText()
    end

    function frame:SetItems(newItems)
        items = newItems or {}
        for _, row in ipairs(popout.rows) do
            row:Hide()
        end
        UpdateButtonText()
    end

    return frame
end

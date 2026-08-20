-- PushPlanner - UI/Widgets/ListRow.lua
-- PP.Widgets.ListRow: a dungeon row (accent bar, name, sub-label, icon strip,
-- right-aligned value+delta). Also exposes the AccentBar, IconStrip and
-- ValueDelta building blocks used elsewhere (e.g. the ItemRow variant).

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.ListRow = {}
local ListRow = PP.Widgets.ListRow

local ACCENT_WIDTH = 3
local ICON_SIZE = 14

function ListRow.CreateAccentBar(parent, colorKey)
    local bar = parent:CreateTexture(nil, "ARTWORK")
    bar:SetTexture(Theme.texture.white)
    bar:SetWidth(ACCENT_WIDTH)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    bar:SetVertexColor(unpack(Theme.colors[colorKey or "accentDefault"]))
    return bar
end

-- icons: array of { texture = fileID/path, tooltip = text }
function ListRow.CreateIconStrip(parent)
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetHeight(ICON_SIZE)
    strip.icons = {}

    function strip:SetIcons(icons)
        for _, tex in ipairs(self.icons) do
            tex:Hide()
        end
        local prev
        for i, info in ipairs(icons or {}) do
            local tex = self.icons[i]
            if not tex then
                tex = strip:CreateTexture(nil, "ARTWORK")
                tex:SetSize(ICON_SIZE, ICON_SIZE)
                self.icons[i] = tex
            end
            tex:SetTexture(info.texture)
            tex:ClearAllPoints()
            if prev then
                tex:SetPoint("LEFT", prev, "RIGHT", 3, 0)
            else
                tex:SetPoint("LEFT", strip, "LEFT", 0, 0)
            end
            tex:Show()

            if info.tooltip then
                tex:EnableMouse(true)
                tex:SetScript("OnEnter", function() PP.ShowTip(tex, info.tooltip, "ANCHOR_TOP") end)
                tex:SetScript("OnLeave", function() PP.HideTip() end)
            end
            prev = tex
        end
        local width = (#icons or 0) * (ICON_SIZE + 3)
        self:SetWidth(math.max(width, 1))
    end

    return strip
end

-- Returns a fontstring showing "value / +delta" or "value / -delta" coloured
-- green/red, e.g. StatCell "288 / +3 over".
function ListRow.CreateValueDelta(parent)
    local fs = Theme:CreateFontString(parent, "size", "text")

    function fs:SetValueDelta(value, delta)
        local sign = delta >= 0 and "+" or ""
        local colorKey = delta >= 0 and "good" or "bad"
        local color = Theme.colors[colorKey]
        local hex = string.format("%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
        fs:SetText(string.format("%d  |cff%s%s%d|r", value, hex, sign, delta))
    end

    return fs
end

function ListRow.New(parent, opts)
    opts = opts or {}
    local height = opts.height or 26

    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(height)
    Theme:SkinPanel(row, "panel", "border")

    local accent = ListRow.CreateAccentBar(row, opts.accentColorKey)

    local name = Theme:CreateFontString(row, "size", "text")
    name:SetPoint("LEFT", row, "LEFT", ACCENT_WIDTH + 8, 6)

    local sub = Theme:CreateFontString(row, "sizeSmall", "textDim")
    sub:SetPoint("LEFT", row, "LEFT", ACCENT_WIDTH + 8, -6)

    local iconStrip = ListRow.CreateIconStrip(row)
    iconStrip:SetPoint("RIGHT", row, "RIGHT", -90, 0)

    local valueDelta = ListRow.CreateValueDelta(row)
    valueDelta:SetPoint("RIGHT", row, "RIGHT", -8, 0)

    row.accent = accent
    row.nameText = name
    row.subText = sub
    row.iconStrip = iconStrip
    row.valueDelta = valueDelta

    function row:SetAccentColor(colorKey)
        accent:SetVertexColor(unpack(Theme.colors[colorKey] or Theme.colors.accentDefault))
    end

    return row
end

# oUF_SwingTimer

swing timer support for oUF layouts

## Element: SwingTimer

Handles the visibility and updating of two status bar that tracks main-hand and off-hand swing timing.

### Widgets
	
- `SwingTimer`: A `Frame` to hold a `Button`s representing debuffs.

### Sub-Widgets

- `MainHand`: A `StatusBar` to represent mian-hand weapon swing.
- `OffHand`: A `StatusBar` to represent off-hand weapon swing.

### Example

```lua
local element = CreateFrame("Frame", nil, frame)
element:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
element:SetSize(200, 45)

do
    local statusbar = CreateFrame("StatusBar", nil, element)
    statusbar:SetSize(200, 20)
    statusbar:SetPoint("TOP", element, "TOP", 0, 0)
    statusbar:SetStatusBarTexture(texture)
    statusbar:SetStatusBarColor(0.8, 0.4, 0.4)
    statusbar:CreateBackdrop()

    local bg = statusbar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(statusbar)
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    statusbar.bg = bg

    local text = statusbar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("RIGHT", statusbar, "RIGHT", -5, 0)
    text:SetFontObject(fontObject)
    text:SetText("0.0s")
    statusbar.Text = text

    element.MainHand = statusbar
end

do
    local statusbar = CreateFrame("StatusBar", nil, element)
    statusbar:SetPoint("TOP", element.MainHand or element, "BOTTOM", 0, -5)
    statusbar:SetSize(200, 20)
    statusbar:SetStatusBarTexture(texture)
    statusbar:SetStatusBarColor(0.8, 0.4, 0.4)
    statusbar:CreateBackdrop()

    local bg = statusbar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(statusbar)
    bg:SetTexture(texture)
    bg.multiplier = C.general.background.multiplier or 0.15
    statusbar.bg = bg

    local text = statusbar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("RIGHT", statusbar, "RIGHT", -5, 0)
    text:SetFontObject(fontObject)
    text:SetText("0.0s")
    statusbar.Text = text

    element.OffHand = statusbar
end

-- register with oUF
self.SwingTimer = element
```

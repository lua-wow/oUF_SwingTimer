--[[
	# Element: SwingTimer

	Handles the visibility and updating of two status bar that tracks main-hand and off-hand swing timing.

	## Widgets
	
	SwingTimer		- A `Frame` to hold a `Button`s representing debuffs.
	
	## Sub-Widgets

	MainHand        - A `StatusBar` to represent mian-hand weapon swing.
	OffHand         - A `StatusBar` to represent off-hand weapon swing.
	
	## Example
        
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
--]]

local _, ns = ...
local oUF = ns.oUF
assert(oUF, "oUF_SwingTimer was unable to locate oUF install.")

local COLORS = {
    ["main-hand"] = oUF:CreateColor(0.80, 0.30, 0.10),
    ["off-hand"] = oUF:CreateColor(0.10, 0.10, 0.80)
}

local COMBAT_EVENTS = {
    ["SWING_DAMAGE"] = true,
    ["RANGE_DAMAGE"] = true,
    ["SWING_MISSED"] = true,
    ["RANGE_MISSED"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
}

local SWING_RESET_SPELLS = {
    [78] = true, -- Heroic Strike (Rank 1)
    [284] = true, -- Heroic Strike (Rank 2)
    -- Add more spell IDs as needed
}

local function UpdateColor(self, arg, ...)
	local element = self.SwingTimer

    local color = COLORS[arg or "none"]
    local frame = (arg == "main-hand") and element.MainHand or element.OffHand

	if frame and color then
		frame:SetStatusBarColor(color.r, color.g, color.b)

        local bg = frame.bg
        if bg then
            local mu = bg.multiplier or 1
            bg:SetVertexColor(color.r * mu, color.g * mu, color.b * mu)
        end
	end
end

local function OnUpdate(self, elapsed)
    self.updateInterval = (self.updateInterval or 0) - elapsed
    if self.updateInterval <= 0 then
        local now = GetTime()
        
        -- update main-hand bar
        do
            local statusbar = self.MainHand
            if statusbar:IsShown() then
                local max = statusbar.speed or 0
                local value = now - (statusbar.startTime or now)
                if value >= max then
                    value = 0
                    statusbar.startTime = now
                end

                statusbar:SetValue(value)

                if statusbar.Text then
                    statusbar.Text:SetFormattedText("%.1f / %.1f", value, max)
                end
            end
        end
        
        -- update off-hand bar
        do
            local statusbar = self.OffHand
            if statusbar:IsShown() then
                local max = statusbar.speed or 0
                local value = now - (statusbar.startTime or now)
                if value >= max then
                    value = 0
                    statusbar.startTime = now
                end

                statusbar:SetValue(value)

                if statusbar.Text then
                    statusbar.Text:SetFormattedText("%.1f / %.1f", value, max)
                end
            end
        end

        self.updateInterval = 0.01
    end
end

local function Reset(self, event, isOffHand)
    local element = self.SwingTimer
    if not element then return end

    local statusbar = isOffHand and element.OffHand or element.MainHand
    statusbar.startTime = GetTime()
    statusbar:SetValue(0)
end

local function Update(self, event, unit)
    local element = self.SwingTimer
    if not element then return end

    local mainhand = element.MainHand
    local offhand = element.OffHand

    if event == "UNIT_ATTACK_SPEED" or event == "ForceUpdate" then
        local mainSpeed, offSpeed = UnitAttackSpeed("player")
        local rangedSpeed, _, _, _, _, _ = UnitRangedDamage("player")
        
        mainhand.speed = mainSpeed or 0
        mainhand:SetMinMaxValues(0, mainhand.speed)
        
        if not mainhand.speed then
            mainhand:Hide()
        end

        offhand.speed = offSpeed or rangedSpeed or 0
        

        if not offhand.speed then
            offhand:Hide()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID, _, _, _, _ = CombatLogGetCurrentEventInfo()
        
        -- ignore events
        if not COMBAT_EVENTS[subevent] then return end

        -- ignore events not from player
        if sourceGUID ~= element.__guid then return end

        if subevent == "SWING_DAMAGE" or subevent == "RANGE_DAMAGE" then
            local index = (subevent == "RANGE_DAMAGE") and 15 or 12
            local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(index, CombatLogGetCurrentEventInfo())
            
            if (subevent == "RANGE_DAMAGE" and element.__class == "PRIEST") then
                isOffHand = true
            end

            Reset(self, event .. '.' .. subevent, isOffHand or false)
        elseif subevent == "SWING_MISSED" or subevent == "RANGE_MISSED" then
            local index = (subevent == "RANGE_MISSED") and 15 or 12
            local missType, isOffHand, amountMissed, critical = select(index, CombatLogGetCurrentEventInfo())
            
            if (subevent == "RANGE_MISSED" and element.__class == "PRIEST") then
                isOffHand = true
            end

            Reset(self, event .. '.' .. subevent, isOffHand or false)
        elseif subevent == "" then
            local spellID, spellName, spellSchool, _ = select(12, CombatLogGetCurrentEventInfo())
            if SWING_RESET_SPELLS[spellID] then
                Reset(self, event .. '.' .. subevent, false)
                Reset(self, event .. '.' .. subevent, true)
            end
        else
            return
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        element:Hide()
        element:SetScript("OnUpdate", nil)
    elseif event == "PLAYER_REGEN_DISABLED" then
        element:Show()
        element:SetScript("OnUpdate", OnUpdate)
    end

	--[[ Callback: SwingTimer:PreUpdate()
	Called before the element has been updated.

	* self - the SwingTimer element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

    local now = GetTime()
    mainhand:SetMinMaxValues(0, mainhand.speed)
    mainhand:SetValue(mainhand.startTime and (now - mainhand.startTime) or 0)

    offhand:SetMinMaxValues(0, offhand.speed)
    offhand:SetValue(offhand.startTime and (now - offhand.startTime) or 0)

	--[[ Callback: SwingTimer:PostUpdate(cur, max)
	Called after the element has been updated.

	* self - the SwingTimer element
	* cur  - the amount of staggered damage (number)
	* max  - the player's maximum possible health value (number)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(cur, max)
	end
end

local function Path(self, ...)
	--[[ Override: SwingTimer.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.SwingTimer.Override or Update)(self, ...);

	--[[ Override: SwingTimer.UpdateColor(self, event, unit)
	Used to completely override the internal function for updating the widgets' colors.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
    local fn = (self.SwingTimer.UpdateColor or UpdateColor)
	fn(self, "main-hand", ...)
	fn(self, "off-hand", ...)
end

local function Visibility(self, event, unit)
    local element = self.SwingTimer

    local _, class = UnitClass(unit)
    local mainSpeed, offSpeed = UnitAttackSpeed("player")
    local rangedSpeed, _, _, _, _, _ = UnitRangedDamage("player")
    
    element.MainHand.speed = mainSpeed
    element.OffHand.speed = offSpeed or rangedSpeed

    -- if offSpeed or rangedSpeed then
    --     element.OffHand:Show()
    -- else
    --     element.OffHand:Hide()
    -- end

    Path(self, event, unit)
end

local function VisibilityPath(self, ...)
	--[[ Override: SwingTimer.OverrideVisibility(self, event, unit)
	Used to completely override the internal visibility toggling function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.SwingTimer.OverrideVisibility or Visibility)(self, ...)
end

local function ForceUpdate(element)
	VisibilityPath(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.SwingTimer
	if element and UnitIsUnit(unit, "player") then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_ATTACK_SPEED", Path)
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", Path, true)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", Path, true)
		self:RegisterEvent("PLAYER_REGEN_DISABLED", Path, true)

        for _, frame in next, ({ element.MainHand, element.OffHand }) do
            if frame and frame:IsObjectType('StatusBar') and not frame:GetStatusBarTexture() then
                frame:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
            end
        end

        local _, class = UnitClass("player")
        element.__class = class
        element.__guid = UnitGUID("player")
        element.updateInterval = 0
        -- element:SetScript("OnUpdate", OnUpdate)
		element:Hide()

		return true
	end
end

local function Disable(self)
	local element = self.SwingTimer
	if element then
        element:SetScript("OnUpdate", nil)
		element:Hide()

		self:UnregisterEvent("UNIT_ATTACK_SPEED", Path)
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED", Path)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", Path)
		self:UnregisterEvent("PLAYER_REGEN_DISABLED", Path)
	end
end

oUF:AddElement("SwingTimer", VisibilityPath, Enable, Disable)

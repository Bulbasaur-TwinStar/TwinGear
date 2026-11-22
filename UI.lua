local _, TG = ...

local function ShortName(name)
    return name and string.match(name, "^([^-]+)") or name
end

local function CreateRow(parent, x, y, w)
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(w, 16)
    r:SetPoint("TOPLEFT", x, y)
    r.L = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    r.L:SetPoint("LEFT"); r.L:SetWordWrap(false)
    r.R = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.R:SetPoint("RIGHT")
    return r
end

local function CreateHeader(parent, text, x, y)
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", x, y)
    h:SetText("|cffffd100" .. text .. "|r")
    return h
end

function TG:ToggleHistoryMenu(anchor)
    local f = TG.Frame
    if not f.HistMenu then
        local hm = CreateFrame("Frame", nil, f)
        hm:SetSize(215, 235)
        hm:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
        hm:SetFrameStrata("FULLSCREEN_DIALOG")
        hm:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        hm:SetBackdropColor(0.05, 0.06, 0.09, 0.98)
        hm:Hide()

        local title = hm:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", 10, -8)
        title:SetText("|cffffd100Recent Scans (Last 12)|r")

        hm.Rows = {}
        for i = 1, 12 do
            local r = CreateFrame("Button", nil, hm)
            r:SetSize(195, 16)
            r:SetPoint("TOPLEFT", 10, -10 - (i * 17))
            r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            r.L = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            r.L:SetPoint("LEFT"); r.L:SetWordWrap(false)
            r.R = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            r.R:SetPoint("RIGHT")
            r:SetScript("OnClick", function(self)
                if self.targetName and TG.Cache[self.targetName] then
                    hm:Hide()
                    TG:UpdateUI(TG.Cache[self.targetName])
                end
            end)
            table.insert(hm.Rows, r)
        end
        f.HistMenu = hm
    end

    if f.HistMenu:IsShown() then
        f.HistMenu:Hide()
        return
    end

    for i = 1, 12 do
        local row = f.HistMenu.Rows[i]
        local name = TG.History and TG.History[i]
        local c = name and TG.Cache[name]
        if c then
            local cc = RAID_CLASS_COLORS[c.class] or { r = 1, g = 1, b = 1 }
            local hex = string.format("|cff%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)
            row.targetName = name
            row.L:SetText(hex .. ShortName(name) .. "|r")
            row.R:SetText("|cff00ff00" .. (c.ilvl or 0) .. "|r |cffaaaaaa" .. (c.spec or "") .. "|r")
            row:Show()
        else
            row.targetName = nil
            row:Hide()
        end
    end
    f.HistMenu:Show()
end

function TG:InitUI()
    local f = CreateFrame("Frame", "TwinGearFrame", UIParent)
    f:SetSize(640, 460)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, "TwinGearFrame")

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.06, 0.07, 0.10, 0.96)
    TG.Frame = f

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.Title:SetPoint("TOP", 46, -14)
    f.Sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.Sub:SetPoint("TOP", f.Title, "BOTTOM", 0, -2)

    local linkBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    linkBtn:SetSize(44, 20)
    linkBtn:SetPoint("TOPLEFT", 14, -14)
    linkBtn:SetText(TG:L("BTN_LINK"))
    linkBtn:SetScript("OnClick", function()
        if not TG.CurrentData then return end
        local d = TG.CurrentData
        local msg = string.format("[TwinGear] %s - %d iLvl (%s %s)", d.name, d.ilvl, d.spec, d.class or "")
        local eb = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend() or DEFAULT_CHAT_FRAME.editBox
        if eb then ChatEdit_ActivateChat(eb); eb:SetText(msg) end
    end)
    f.LinkBtn = linkBtn

    local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scanBtn:SetSize(58, 20)
    scanBtn:SetPoint("LEFT", linkBtn, "RIGHT", 3, 0)
    scanBtn:SetText(TG:L("BTN_RESCAN"))
    scanBtn:SetScript("OnClick", function()
        if UnitExists("target") and UnitIsPlayer("target") then TG:RequestInspect("target", true, true)
        else TG.InspectUnit = "player"; TG:ScanUnit("player", true) end
    end)
    f.ScanBtn = scanBtn

    local histBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    histBtn:SetSize(54, 20)
    histBtn:SetPoint("LEFT", scanBtn, "RIGHT", 3, 0)
    histBtn:SetText(TG:L("BTN_HISTORY"))
    histBtn:SetScript("OnClick", function(self) TG:ToggleHistoryMenu(self) end)
    f.HistBtn = histBtn

    f.Tab1 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.Tab1:SetSize(85, 22); f.Tab1:SetPoint("BOTTOMLEFT", 14, 12); f.Tab1:SetText(TG:L("TAB_SUMMARY"))
    f.Tab1:SetScript("OnClick", function() TG:SwitchTab(1) end)

    f.Tab2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.Tab2:SetSize(85, 22); f.Tab2:SetPoint("LEFT", f.Tab1, "RIGHT", 4, 0); f.Tab2:SetText(TG:L("TAB_EQUIP"))
    f.Tab2:SetScript("OnClick", function() TG:SwitchTab(2) end)

    f.Tab3 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.Tab3:SetSize(85, 22); f.Tab3:SetPoint("LEFT", f.Tab2, "RIGHT", 4, 0); f.Tab3:SetText(TG:L("TAB_GROUP"))
    f.Tab3:SetScript("OnClick", function() TG:SwitchTab(3) end)

    f.Tab4 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.Tab4:SetSize(92, 22); f.Tab4:SetPoint("LEFT", f.Tab3, "RIGHT", 4, 0); f.Tab4:SetText(TG:L("TAB_ALTS"))
    f.Tab4:SetScript("OnClick", function() TG:SwitchTab(4) end)

    local scMinus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scMinus:SetSize(22, 20); scMinus:SetPoint("BOTTOMRIGHT", -125, 13); scMinus:SetText("-")
    scMinus:SetScript("OnClick", function()
        TwinGearDB = TwinGearDB or {}
        TwinGearDB.scale = math.max(0.6, tonumber(string.format("%.2f", (TwinGearDB.scale or 1.0) - 0.05)))
        f:SetScale(TwinGearDB.scale)
    end)

    local scPlus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scPlus:SetSize(22, 20); scPlus:SetPoint("LEFT", scMinus, "RIGHT", 2, 0); scPlus:SetText("+")
    scPlus:SetScript("OnClick", function()
        TwinGearDB = TwinGearDB or {}
        TwinGearDB.scale = math.min(1.6, tonumber(string.format("%.2f", (TwinGearDB.scale or 1.0) + 0.05)))
        f:SetScale(TwinGearDB.scale)
    end)

    local ver = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ver:SetPoint("BOTTOMRIGHT", -14, 16)
    ver:SetText("|cffffd100Twin|r|cff00ff00Gear|r v2.2.3")
    f:SetScale(TwinGearDB and TwinGearDB.scale or 1.0)

    local p1 = CreateFrame("Frame", nil, f)
    p1:SetAllPoints()
    f.Page1 = p1

    f.AuditHeader = CreateHeader(p1, TG:L("SEC_AUDIT"), 20, -52)
    f.AuditRows = {}
    local aLabels = { TG:L("AUD_ILVL"), TG:L("AUD_CLOAK"), TG:L("AUD_SETS"), TG:L("AUD_UPG"), TG:L("AUD_GEMS"), TG:L("AUD_PVP"), TG:L("AUD_PROFS") }
    for i, lbl in ipairs(aLabels) do
        local r = CreateRow(p1, 20, -55 - (i * 18), 210)
        r.L:SetText(lbl)
        if i == 7 then
            r:EnableMouse(true)
            r:SetScript("OnEnter", function(self)
                if not self.profList or #self.profList == 0 then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetFrameStrata("TOOLTIP")
                GameTooltip:AddLine("|cffffd100Professions|r")
                for _, p in ipairs(self.profList) do
                    GameTooltip:AddDoubleLine(p.name .. "   ", "|cff00ff00" .. p.skill .. "|r", 0.85, 0.85, 0.85)
                end
                GameTooltip:Show()
            end)
            r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        table.insert(f.AuditRows, r)
    end

    f.RaidHeader = CreateHeader(p1, TG:L("SEC_RAIDS"), 20, -208)
    f.RaidRows = {}
    for i = 1, 5 do
        local r = CreateFrame("Button", nil, p1)
        r:SetSize(210, 16)
        r:SetPoint("TOPLEFT", 20, -211 - (i * 18))
        r:SetFrameLevel(f:GetFrameLevel() + 20)
        r.L = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.L:SetPoint("LEFT"); r.L:SetWordWrap(false)
        r.R = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.R:SetPoint("RIGHT")
        r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        r:SetScript("OnEnter", function(self)
            local rd = self.raidData
            if not rd then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetFrameStrata("TOOLTIP")
            GameTooltip:AddLine("|cffffd100" .. rd.name .. "|r")
            local function AddDiffLine(label, val, tot, col)
                local c = val == tot and "|cff00ff00" or (val > 0 and col or "|cff888888")
                GameTooltip:AddDoubleLine(label, c .. val .. " / " .. tot .. "|r", 0.8, 0.8, 0.8)
            end
            AddDiffLine("Heroic:", rd.hc or 0, rd.total, "|cffff8000")
            AddDiffLine("Normal:", rd.norm or 0, rd.total, "|cff00ccff")
            if rd.hasFlex then
                AddDiffLine("Flexible:", rd.flx or 0, rd.total, "|cff00ff00")
            end
            AddDiffLine("Raid Finder (LFR):", rd.lfr or 0, rd.total, "|cffffffff")
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(f.RaidRows, r)
    end

    f.CMRow = CreateFrame("Button", nil, p1)
    f.CMRow:SetSize(210, 16)
    f.CMRow:SetPoint("TOPLEFT", 20, -328)
    f.CMRow:SetFrameLevel(f:GetFrameLevel() + 20)
    f.CMRow.L = f.CMRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.CMRow.L:SetPoint("LEFT")
    f.CMRow.L:SetText("|cffffd100" .. TG:L("CM_TITLE") .. "|r")
    f.CMRow.R = f.CMRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.CMRow.R:SetPoint("RIGHT")
    f.CMRow:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    f.CMRow:SetScript("OnEnter", function(self)
        local list = self.cmList
        if not list or #list == 0 then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetFrameStrata("TOOLTIP")
        GameTooltip:AddLine("|cffffd100MoP Challenge Modes|r")
        local labels = { [0] = "|cff888888None|r", [1] = "|cffcd7f32Bronze|r", [2] = "|cffccccccSilver|r", [3] = "|cffffd100Gold|r" }
        for _, item in ipairs(list) do
            GameTooltip:AddDoubleLine(item.name, labels[item.tier or 0] or "|cff888888None|r", 0.85, 0.85, 0.85)
        end
        GameTooltip:Show()
    end)
    f.CMRow:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local model = CreateFrame("PlayerModel", "TwinGearModel", p1)
    model:SetSize(180, 305); model:SetPoint("TOP", 0, -56); model:SetUnit("player"); model:SetPosition(-0.28, 0, 0); model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self, btn) if btn == "LeftButton" then self.drag = true; self.x = GetCursorPosition() end end)
    model:SetScript("OnMouseUp", function(self) self.drag = false end)
    model:SetScript("OnUpdate", function(self)
        if self.drag then local cx = GetCursorPosition(); self:SetFacing(self:GetFacing() + (cx - self.x) * 0.02); self.x = cx end
    end)
    f.Model = model

    f.StatsHeader = CreateHeader(p1, "Character Stats", 415, -52)
    f.StatRows = {}
    for i = 1, 12 do
        local r = CreateRow(p1, 415, -54 - (i * 17), 205)
        table.insert(f.StatRows, r)
    end

    local p2 = CreateFrame("Frame", nil, f)
    p2:SetAllPoints(); p2:Hide(); f.Page2 = p2

    f.GearRows = {}
    for i = 1, 16 do
        local r = CreateFrame("Button", nil, p2)
        r:SetSize(600, 19); r:SetPoint("TOPLEFT", 20, -34 - (i * 20))
        r.Slot = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        r.Slot:SetPoint("LEFT", 0, 0); r.Slot:SetWidth(80); r.Slot:SetJustifyH("LEFT")
        r.Icon = r:CreateTexture(nil, "ARTWORK"); r.Icon:SetSize(17, 17); r.Icon:SetPoint("LEFT", 85, 0)
        r.Name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.Name:SetPoint("LEFT", 108, 0); r.Name:SetWidth(315); r.Name:SetJustifyH("LEFT")
        r.ILvl = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.ILvl:SetPoint("LEFT", 430, 0)
        r.Status = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.Status:SetPoint("RIGHT", 0, 0)
        r:SetScript("OnEnter", function(self) if self.link then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.link); GameTooltip:Show() end end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(f.GearRows, r)
    end

    local p3 = CreateFrame("Frame", nil, f)
    p3:SetAllPoints(); p3:Hide(); f.Page3 = p3

    local gScanBtn = CreateFrame("Button", nil, p3, "UIPanelButtonTemplate")
    gScanBtn:SetSize(115, 22); gScanBtn:SetPoint("TOPLEFT", 20, -48); gScanBtn:SetText(TG:L("BTN_SCAN_GRP"))
    gScanBtn:SetScript("OnClick", function() TG:RunGroupScan() end)
    f.GScanBtn = gScanBtn

    local repBtn = CreateFrame("Button", nil, p3, "UIPanelButtonTemplate")
    repBtn:SetSize(115, 22); repBtn:SetPoint("LEFT", gScanBtn, "RIGHT", 6, 0); repBtn:SetText(TG:L("BTN_REPORT"))
    repBtn:SetScript("OnClick", function() TG:ReportGroupToChat() end)
    repBtn:SetScript("OnEnter", function(self)
        local noFlask, noFood, scanned = TG:GetGroupConsumableReport()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("|cffffd100Raid Readiness Summary|r")
        GameTooltip:AddDoubleLine("Scanned Players:", "|cff00ff00" .. scanned .. "|r", 0.85, 0.85, 0.85)
        GameTooltip:AddDoubleLine("Missing Flask:", #noFlask == 0 and "|cff00ff000|r" or ("|cffff3333" .. #noFlask .. "|r"), 0.85, 0.85, 0.85)
        GameTooltip:AddDoubleLine("Missing Food:", #noFood == 0 and "|cff00ff000|r" or ("|cffff3333" .. #noFood .. "|r"), 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Click to announce in chat", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    repBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.RepBtn = repBtn

    f.GroupAvgText = p3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.GroupAvgText:SetPoint("RIGHT", p3, "TOPRIGHT", -22, -59)
    f.GroupAvgText:SetText("|cffffd100Avg iLvl:|r |cff888888-|r")

    local h3 = p3:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    h3:SetPoint("BOTTOM", p3, "BOTTOM", 0, 38)
    h3:SetText("|cff888888Supports up to 40 players (Use mouse wheel to scroll)|r")

    local gScroll = CreateFrame("ScrollFrame", nil, p3)
    gScroll:SetSize(610, 316); gScroll:SetPoint("TOPLEFT", 18, -82); gScroll:EnableMouseWheel(true)
    local gChild = CreateFrame("Frame", nil, gScroll); gChild:SetSize(610, 485)
    gScroll:SetScrollChild(gChild)
    gScroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(170, self:GetVerticalScroll() - (delta * 36))))
    end)

    local div = gChild:CreateTexture(nil, "ARTWORK"); div:SetSize(1, 480); div:SetPoint("TOP", gChild, "TOP", 0, -2); div:SetTexture(1, 0.82, 0, 0.25)

    f.GroupRows = {}
    for i = 1, 40 do
        local col = (i <= 20) and 0 or 1
        local rowIdx = (i <= 20) and i or (i - 20)
        local r = CreateFrame("Button", nil, gChild)
        r:SetSize(295, 22); r:SetPoint("TOPLEFT", (col == 0) and 2 or 308, 22 - (rowIdx * 24))
        r.Name = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.Name:SetPoint("TOPLEFT", 2, -1); r.Name:SetWidth(155); r.Name:SetJustifyH("LEFT")
        r.ILvl = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.ILvl:SetPoint("TOPRIGHT", -2, -1)
        r.Sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); r.Sub:SetPoint("BOTTOMLEFT", 2, 1)
        r.Audit = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); r.Audit:SetPoint("BOTTOMRIGHT", -2, 1)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r:SetScript("OnClick", function(self, btn)
            local c = self.playerName and TG.Cache[self.playerName]
            if not c then return end
            if btn == "RightButton" then
                local fl = c.hasFlask and "Flask:OK" or "NoFlask"
                local fd = c.hasFood and "Food:OK" or "NoFood"
                local totG = (c.missGems or 0) + (c.missBuckle and 1 or 0)
                local ge = (totG == 0 and (c.missEnch or 0) == 0 and (c.wrongArmor or 0) == 0) and "Gear:OK" or string.format("-%dG/-%dE", totG, c.missEnch or 0)
                local msg = string.format("[TwinGear] %s - %d iLvl (%s %s) [%s, %s, %s]", ShortName(c.name), c.ilvl or 0, c.spec or "", c.class or "", fl, fd, ge)
                local eb = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend() or DEFAULT_CHAT_FRAME.editBox
                if eb then ChatEdit_ActivateChat(eb); eb:SetText(msg) end
            else
                TG:UpdateUI(c); TG:SwitchTab(2)
            end
        end)
        table.insert(f.GroupRows, r)
    end
end

function TG:SwitchTab(id)
    local f = TG.Frame
    if not f then return end
    f.Page1:Hide(); f.Page2:Hide(); f.Page3:Hide()
    if f.Page4 then f.Page4:Hide() end
    if id == 1 then f.Page1:Show()
    elseif id == 2 then f.Page2:Show()
    elseif id == 3 then f.Page3:Show(); TG:RefreshGroupList()
    elseif id == 4 then TG:BuildPage4(f); TG:RefreshPage4(); f.Page4:Show() end
end

local function FormatCap(valStr, reqCap, lvl)
    if (lvl or 90) < 90 then return "|cff00ff00" .. tostring(valStr) .. "|r" end
    local num = tonumber(string.match(tostring(valStr or "0"), "([%d%.]+)")) or 0
    local col = (num + 0.05 >= reqCap) and "|cff00ff00" or "|cffff3333"
    return col .. tostring(valStr) .. "|r"
end

local function BuildStatRows(d)
    local s = d.stats or {}
    local cat = s.cat or "MELEE"
    local lvl = d.level or 90
    local isStr = (d.class == "WARRIOR" or d.class == "PALADIN" or d.class == "DEATHKNIGHT")
    local isInt = (cat == "CASTER" or cat == "HEALER")
    local primLbl = isInt and "Intellect:" or (isStr and "Strength:" or "Agility:")
    local primVal = isInt and (s.int or 0) or (isStr and (s.str or 0) or (s.agi or 0))

    local rows = {
        { "Health:", s.hp or 0 },
        { primLbl, primVal },
        { "Stamina:", s.sta or 0 },
    }
    local sid = d.specID or s.specID or 0
    local map = {
        C = { "Crit:", s.crit or "0%" }, H = { "Haste:", s.haste or "0%" }, M = { "Mastery:", s.mast or "0%" },
        SP = { "Spell Power:", s.sp or 0 }, AP = { (cat == "RANGED" and "Ranged AP:" or "Attack Power:"), s.ap or 0 },
        SPI = { "Spirit:", s.spi or 0 }, MP5 = (s.mp5 and s.mp5 > 0) and { "Combat Regen:", s.mp5 .. " MP5" } or nil,
        ARM = { "Armor:", s.armor or 0 }, DOD = { "Dodge:", s.dodge or "0%" }, PAR = { "Parry:", s.parry or "0%" },
        H15 = { "Hit:", FormatCap(s.hit or "0%", 15.0, lvl), true }, H75 = { "Hit:", FormatCap(s.hit or "0%", 7.5, lvl), true },
        E75 = { "Expertise:", FormatCap(s.exp or "0%", 7.5, lvl), true }, E15 = { "Expertise:", FormatCap(s.exp or "0%", 15.0, lvl), true },
    }
    local specOrder = {}
    rawset(specOrder, 250, {"ARM","H75","E15","M","PAR","DOD"})
    rawset(specOrder, 251, {"AP","H75","E75","M","H","C"})
    rawset(specOrder, 252, {"AP","H75","E75","M","C","H"})
    rawset(specOrder, 102, {"SP","H15","H","C","M"})
    rawset(specOrder, 103, {"AP","H75","E75","M","C","H"})
    rawset(specOrder, 104, {"ARM","H75","E15","C","M","DOD"})
    rawset(specOrder, 105, {"SP","SPI","H","M","C","MP5"})
    rawset(specOrder, 253, {"AP","H75","E75","C","H","M"})
    rawset(specOrder, 254, {"AP","H75","E75","C","H","M"})
    rawset(specOrder, 255, {"AP","H75","E75","C","H","M"})
    rawset(specOrder, 62, {"SP","H15","M","H","C"})
    rawset(specOrder, 63, {"SP","H15","C","M","H"})
    rawset(specOrder, 64, {"SP","H15","H","C","M"})
    rawset(specOrder, 268, {"ARM","H75","E15","H","C","M","DOD","PAR"})
    rawset(specOrder, 269, {"AP","H75","E75","H","C","M"})
    rawset(specOrder, 270, {"SP","SPI","H","C","M","MP5"})
    rawset(specOrder, 65, {"SP","SPI","M","H","C","MP5"})
    rawset(specOrder, 66, {"ARM","H75","E15","H","M","PAR","DOD"})
    rawset(specOrder, 70, {"AP","H75","E75","H","M","C"})
    rawset(specOrder, 256, {"SP","SPI","C","M","H","MP5"})
    rawset(specOrder, 257, {"SP","SPI","M","H","C","MP5"})
    rawset(specOrder, 258, {"SP","H15","H","C","M"})
    rawset(specOrder, 259, {"AP","H75","E75","M","H","C"})
    rawset(specOrder, 260, {"AP","H75","E75","H","M","C"})
    rawset(specOrder, 261, {"AP","H75","E75","M","H","C"})
    rawset(specOrder, 262, {"SP","H15","M","H","C"})
    rawset(specOrder, 263, {"AP","H75","E75","M","H","C"})
    rawset(specOrder, 264, {"SP","SPI","M","H","C","MP5"})
    rawset(specOrder, 265, {"SP","H15","M","H","C"})
    rawset(specOrder, 266, {"SP","H15","H","M","C"})
    rawset(specOrder, 267, {"SP","H15","M","H","C"})
    rawset(specOrder, 71, {"AP","H75","E75","C","M","H"})
    rawset(specOrder, 72, {"AP","H75","E75","C","M","H"})
    rawset(specOrder, 73, {"ARM","H75","E15","M","PAR","DOD"})
    local seq = rawget(specOrder, sid) or (cat == "CASTER" and {"SP","H15","H","C","M"} or (cat == "HEALER" and {"SP","SPI","M","H","C","MP5"} or (cat == "TANK" and {"ARM","H75","E15","M","PAR","DOD"} or {"AP","H75","E75","C","H","M"})))
    for _, k in ipairs(seq) do if map[k] then table.insert(rows, map[k]) end end
    if (cat == "CASTER" or cat == "HEALER") and TG.GetBreakpointSummary then
        local bp = TG:GetBreakpointSummary(s, d.unit)
        if bp then local l1, l2 = strsplit("\n", bp); if l1 and l1 ~= "" then table.insert(rows, { "Hit Advisor:", l1, true }) end; if l2 then table.insert(rows, { "Haste BP:", l2, true }) end end
    end
    if (d.pvp and d.pvp > 0) or (s.pvp and s.pvp ~= "0.00%" and s.pvp ~= "0%") then
        table.insert(rows, { "PvP Power:", s.pvp or "0%" })
        if s.resil and s.resil ~= "0.00%" and s.resil ~= "0%" then
            table.insert(rows, { "PvP Resilience:", s.resil })
        end
    end
    return rows
end

local function HasAnyBuffID(unit, ids)
    if not unit or not UnitExists(unit) then return false end
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, sId = UnitBuff(unit, i)
        if not name then break end
        if sId and ids[sId] then return true end
    end
    return false
end

local BUFF_STATS_IDS = { [20217]=true, [1126]=true, [115921]=true, [90363]=true }
local BUFF_STA_IDS   = { [21562]=true, [469]=true, [109773]=true, [90364]=true }
local BUFF_CRIT_IDS  = { [1459]=true, [61316]=true, [17007]=true, [116781]=true, [24604]=true, [90309]=true, [126309]=true }

function TG:UpdateUI(d)
    if not d then return end
    TG.CurrentData = d
    local f = TG.Frame
    local cc = RAID_CLASS_COLORS[d.class] or { r = 1, g = 1, b = 1 }
    local hex = string.format("|cff%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)

    f.Title:SetText(string.format("%s%s|r - |cffffd100Lvl|r %s%d|r (|cff00ff00%d iLvl|r) %s%s %s|r",
        hex, d.name, hex, d.level or 90, d.ilvl, hex, d.spec, d.class or ""))
    f.Sub:SetText(d.guild == "No Guild" and "|cff777777No Guild|r" or ("|cffffd100<" .. d.guild .. ">|r"))
    if d.unit and UnitExists(d.unit) then
        local g = UnitGUID(d.unit)
        if g and f.Model.lastGUID ~= g then
            f.Model.lastGUID = g
            TG:ApplyUnitModel(f.Model, d.unit)
        end
    end

    local ar = f.AuditRows
    ar[1].R:SetText("|cff00ff00" .. d.ilvl .. "|r")
    local clk = d.cloak == "None" and ("|cff888888" .. TG:L("NONE") .. "|r") or ("|cffff8000" .. d.cloak .. "|r")
    if d.hasMeta then clk = clk .. " |cff00ff00+Meta|r" end
    ar[2].R:SetText(clk)

    local tParts = {}
    local tiers = d.tiers or { T16 = d.t16 or 0 }
    for _, tKey in ipairs({"T16", "T15", "T14"}) do
        local cnt = tiers[tKey] or 0
        if cnt > 0 then
            local col = cnt >= 4 and "|cff00ff00" or (cnt >= 2 and "|cffffa500" or "|cffcccccc")
            table.insert(tParts, col .. tKey .. ":" .. cnt .. "/5|r")
        end
    end
    ar[3].R:SetText(#tParts > 0 and table.concat(tParts, " ") or "|cff8888880 / 5 pcs|r")

    local refTxt = (d.reforged and d.reforged > 0) and (" |cff00ccff(" .. d.reforged .. " Ref)|r") or ""
    ar[4].R:SetText("|cff00ff00" .. d.upgCur .. " / " .. d.upgMax .. "|r" .. refTxt)

    local auditIssues = {}
    if d.wrongArmor and d.wrongArmor > 0 then table.insert(auditIssues, "-" .. d.wrongArmor .. " Armor") end
    if d.missGems > 0 then table.insert(auditIssues, "-" .. d.missGems .. " Gem") end
    if d.missBuckle then table.insert(auditIssues, "-Belt Buckle") end
    if d.missEnch > 0 then table.insert(auditIssues, "-" .. d.missEnch .. " Ench") end
    local auditTxt = #auditIssues == 0 and ("|cff00ff00" .. TG:L("OK") .. " (Full)|r") or ("|cffff3333" .. table.concat(auditIssues, ", ") .. "|r")
    ar[5].R:SetText(auditTxt)
    ar[6].R:SetText(d.pvp == 0 and "|cff00ff000 (Pure PvE)|r" or ("|cffff3333" .. d.pvp .. " PvP pcs|r"))

    local shortProfMap = {
        ["Engineering"] = "Eng", ["Tailoring"] = "Tailor", ["Inscription"] = "Insc",
        ["Leatherworking"] = "LW", ["Blacksmithing"] = "BS", ["Jewelcrafting"] = "JC",
        ["Enchanting"] = "Ench", ["Alchemy"] = "Alch", ["Herbalism"] = "Herb",
        ["Mining"] = "Mine", ["Skinning"] = "Skin"
    }

    local pList, fullList = {}, {}
    if d.isSelf then
        for _, p in ipairs(TG:GetMyProfessions()) do
            local sName = shortProfMap[p.name] or p.name
            table.insert(pList, sName .. " (" .. p.rank .. ")")
            table.insert(fullList, { name = p.name, skill = p.rank .. " / " .. p.max })
        end
    elseif d.syncedProfs and #d.syncedProfs > 0 then
        for _, p in ipairs(d.syncedProfs) do
            local sName = shortProfMap[p.name] or p.name
            local rank = string.match(p.skill, "^(%d+)") or p.skill
            table.insert(pList, sName .. " (" .. rank .. ")")
            table.insert(fullList, { name = p.name, skill = string.gsub(p.skill, "/", " / ") })
        end
    else
        for _, k in ipairs({"Eng", "Tailor", "Insc", "LW", "BS", "JC", "Ench"}) do
            if d.profs and d.profs[k] then
                table.insert(pList, "[" .. k .. "]")
                table.insert(fullList, { name = k, skill = "Detected via gear" })
            end
        end
    end

    ar[7].profList = fullList
    ar[7].R:SetText(#pList > 0 and ("|cff00ccff" .. table.concat(pList, " ") .. "|r") or "|cff888888None detected|r")

    if d.isSelf or d.syncedRaids then
        if f.RaidHeader then f.RaidHeader:SetText("|cffffd100" .. TG:L("SEC_RAIDS") .. "|r" .. (d.syncedRaids and " |cff00ccff(Sync)|r" or "")) end
        local raids = d.isSelf and TG:GetMyRaids() or d.syncedRaids
        for i, r in ipairs(raids) do
            f.RaidRows[i].raidData = r
            f.RaidRows[i].L:SetText(r.name)
            local col = r.clr == r.total and "|cff00ff00" or (r.clr > 0 and "|cffffa500" or "|cff888888")
            f.RaidRows[i].R:SetText(col .. r.clr .. "/" .. r.total .. "|r (HC:" .. r.hc .. ")")
        end
        if f.CMRow then
            f.CMRow.L:SetText("|cffffd100" .. TG:L("CM_TITLE") .. "|r")
            if d.isSelf then
                local sum, list = TG:GetMyChallengeMode()
                f.CMRow.R:SetText(sum)
                f.CMRow.cmList = list
            else
                f.CMRow.R:SetText(d.syncedCM or "|cff888888-|r")
                f.CMRow.cmList = d.syncedCMList
            end
        end
    else
        if f.RaidHeader then f.RaidHeader:SetText("|cffffd100" .. TG:L("SEC_BUFFS") .. "|r") end
        for i = 1, 5 do f.RaidRows[i].raidData = nil end
        local u = d.unit
        local hasStats = HasAnyBuffID(u, BUFF_STATS_IDS)
        local hasSta   = HasAnyBuffID(u, BUFF_STA_IDS)
        local hasCrit  = HasAnyBuffID(u, BUFF_CRIT_IDS)

        f.RaidRows[1].L:SetText("Flask:"); f.RaidRows[1].R:SetText(d.hasFlask and "|cff00ff00Active|r" or "|cffff3333Missing|r")
        f.RaidRows[2].L:SetText("Well Fed (Food):"); f.RaidRows[2].R:SetText(d.hasFood and "|cff00ff00Active|r" or "|cffff3333Missing|r")
        f.RaidRows[3].L:SetText("5% Stats Buff:"); f.RaidRows[3].R:SetText(hasStats and "|cff00ff00Yes|r" or "|cff888888No|r")
        f.RaidRows[4].L:SetText("10% Stamina:"); f.RaidRows[4].R:SetText(hasSta and "|cff00ff00Yes|r" or "|cff888888No|r")
        f.RaidRows[5].L:SetText("5% Crit Buff:"); f.RaidRows[5].R:SetText(hasCrit and "|cff00ff00Yes|r" or "|cff888888No|r")
        if f.CMRow then f.CMRow.L:SetText(""); f.CMRow.R:SetText(""); f.CMRow.cmList = nil end
    end

    local catLabels = { TANK = "Tank Stats", HEALER = "Healer Stats", CASTER = "Spell Stats", RANGED = "Ranged Stats", MELEE = "Melee Stats" }
    local catTitle = catLabels[(d.stats and d.stats.cat) or "MELEE"] or "Character Stats"
    f.StatsHeader:SetText("|cffffd100" .. catTitle .. "|r " .. (d.isSynced and "|cff00ccff(Exact)|r" or "|cff888888(Est.)|r"))

    local stData = BuildStatRows(d)
    for i, row in ipairs(f.StatRows) do
        if stData[i] then
            local lbl, val, preColored = unpack(stData[i])
            row.L:SetText(lbl)
            row.R:SetText(preColored and tostring(val) or ("|cff00ff00" .. tostring(val) .. "|r"))
        else
            row.L:SetText("")
            row.R:SetText("")
        end
    end

    for i, r in ipairs(f.GearRows) do
        local it = d.items[i]
        if it and not it.empty then
            r.link = it.link; r.Slot:SetText(it.slotName); r.Icon:SetTexture(it.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); r.Name:SetText(it.link)
            r.ILvl:SetText(it.ilvl .. (it.upg ~= "" and (" |cffffd100(" .. it.upg .. ")|r") or ""))
            local w = {}
            if it.isWrongArmor then table.insert(w, "|cffff3333Armor!|r") end
            if it.profTag then table.insert(w, "|cff00ccff" .. it.profTag .. "|r") end
            if it.isReforged then table.insert(w, "|cffaaaaaa[Ref]|r") end
            if it.missGem then table.insert(w, "|cffff3333Gem|r") end
            if it.missBuckle then table.insert(w, "|cffff3333Buckle|r") end
            if it.missEnch then table.insert(w, "|cffff3333Ench|r") end
            r.Status:SetText(#w > 0 and table.concat(w, " ") or "|cff00ff00OK|r")
        elseif it then
            r.link = nil; r.Slot:SetText(it.slotName); r.Icon:SetTexture(nil); r.Name:SetText("|cff555555Empty|r"); r.ILvl:SetText(""); r.Status:SetText("")
        end
    end
end

function TG:RefreshGroupList()
    local rawUnits = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do table.insert(rawUnits, "raid" .. i) end
    else
        table.insert(rawUnits, "player")
        for i = 1, GetNumSubgroupMembers() do table.insert(rawUnits, "party" .. i) end
    end

    local entries = {}
    local sumILvl, scannedCount = 0, 0
    local tanks, heals, dps = 0, 0, 0

    for _, u in ipairs(rawUnits) do
        if UnitExists(u) then
            local name = GetUnitName(u, true)
            local short = UnitName(u)
            local c = TG.Cache[name] or (short and TG.Cache[short])
            local ilvl = (c and c.ilvl) or 0
            local role = (c and c.role) or (UnitGroupRolesAssigned and UnitGroupRolesAssigned(u)) or "DAMAGER"
            if role == "TANK" then tanks = tanks + 1
            elseif role == "HEALER" then heals = heals + 1
            else dps = dps + 1 end
            if ilvl > 0 then sumILvl = sumILvl + ilvl; scannedCount = scannedCount + 1 end
            table.insert(entries, { unit = u, name = name, ilvl = ilvl, role = role, cache = c })
        end
    end

    table.sort(entries, function(a, b)
        if a.ilvl ~= b.ilvl then return a.ilvl > b.ilvl end
        return (a.name or "") < (b.name or "")
    end)

    local roleTags = {
        TANK = "|cff3399ff[T]|r ",
        HEALER = "|cff00ff00[H]|r ",
        DAMAGER = "|cffff6666[D]|r ",
    }

    for i, r in ipairs(TG.Frame.GroupRows) do
        local e = entries[i]
        if e then
            local shortName = ShortName(e.name)
            local _, cls = UnitClass(e.unit)
            local cc = RAID_CLASS_COLORS[cls] or { r = 1, g = 1, b = 1 }
            local hex = string.format("|cff%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)
            local c = e.cache
            local rTag = roleTags[e.role] or ""

            r.playerName = e.name
            r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            r.Name:SetText(rTag .. hex .. shortName .. "|r")

            if c and c.ilvl and c.ilvl > 0 then
                r.ILvl:SetText("|cff00ff00" .. c.ilvl .. " iLvl|r")
                local fl = c.hasFlask and "|cff00ff00F|r" or "|cffff3333NoF|r"
                local fd = c.hasFood and "|cff00ff00W|r" or "|cffff3333NoW|r"
                r.Sub:SetText((c.spec ~= "" and c.spec or "") .. " [" .. fl .. "/" .. fd .. "]")
                local clk = (c.cloak ~= "None" and c.cloak ~= "Standard") and "|cffff8000[Leg]|r " or ""
                local arm = (c.wrongArmor and c.wrongArmor > 0) and ("|cffff3333-" .. c.wrongArmor .. "A|r ") or ""
                local totalG = c.missGems + (c.missBuckle and 1 or 0)
                local ge = (totalG == 0 and c.missEnch == 0 and (c.wrongArmor or 0) == 0) and "|cff00ff00OK|r" or (arm .. string.format("|cffff3333-%dG -%dE|r", totalG, c.missEnch))
                r.Audit:SetText(clk .. ge)
            elseif not UnitIsConnected(e.unit) then
                r.ILvl:SetText("|cff666666Offline|r"); r.Sub:SetText(""); r.Audit:SetText("")
            else
                r.ILvl:SetText("|cff888888Bot / Out of Range|r"); r.Sub:SetText(""); r.Audit:SetText("")
            end
        else
            r.playerName = nil; r:SetHighlightTexture(nil)
            r.Name:SetText(""); r.ILvl:SetText(""); r.Sub:SetText(""); r.Audit:SetText("")
        end
    end

    if not TG.IsScanningGroup then
        local comp = string.format("|cff3399ff%dT|r/|cff00ff00%dH|r/|cffff6666%dD|r", tanks, heals, dps)
        if scannedCount > 0 then
            local avg = math.floor((sumILvl / scannedCount) + 0.5)
            TG.Frame.GroupAvgText:SetText(string.format("%s  |cffffd100Avg:|r |cff00ff00%d|r (%d/%d)", comp, avg, scannedCount, #entries))
        else
            TG.Frame.GroupAvgText:SetText(comp .. "  |cffffd100Avg:|r |cff888888-|r")
        end
    end
end

function TG:RunGroupScan()
    if TG.IsScanningGroup then return end
    TG:ScanUnit("player", false)
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do table.insert(units, "raid" .. i) end
    else
        for i = 1, GetNumSubgroupMembers() do table.insert(units, "party" .. i) end
    end

    local toScan = {}
    for _, u in ipairs(units) do
        if UnitExists(u) and not UnitIsUnit(u, "player") and UnitIsConnected(u) and CanInspect(u) then
            table.insert(toScan, u)
        end
    end
    if #toScan == 0 then TG:RefreshGroupList(); return end

    TG.IsScanningGroup = true
    local delay = 0
    for idx, u in ipairs(toScan) do
        TG:After(delay, function()
            TG.Frame.GroupAvgText:SetText(string.format("|cffffd100Scanning:|r |cff00ccff%d / %d...|r", idx, #toScan))
            if UnitExists(u) and CanInspect(u) then TG:RequestInspect(u, false, true) end
            if idx == #toScan then
                TG:After(0.9, function() TG.IsScanningGroup = false; TG:RefreshGroupList() end)
            end
        end)
        delay = delay + 0.85
    end
    TG:RefreshGroupList()
end

function TG:GetGroupConsumableReport()
    local noFlask, noFood, scanned = {}, {}, 0
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do table.insert(units, "raid" .. i) end
    else
        table.insert(units, "player")
        for i = 1, GetNumSubgroupMembers() do table.insert(units, "party" .. i) end
    end
    for _, u in ipairs(units) do
        if UnitExists(u) then
            local name = GetUnitName(u, true)
            local shortName = ShortName(name)
            local short = UnitName(u)
            local c = TG.Cache[name] or (short and TG.Cache[short])
            if c and c.ilvl and c.ilvl > 0 then
                scanned = scanned + 1
                if not c.hasFlask then table.insert(noFlask, shortName) end
                if not c.hasFood then table.insert(noFood, shortName) end
            end
        end
    end
    return noFlask, noFood, scanned
end

function TG:ReportGroupToChat()
    local noFlask, noFood = TG:GetGroupConsumableReport()
    local chan = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or "SAY")
    local function SendSafe(p, l)
        local s = p
        for _, n in ipairs(l) do
            local sep = (s == p) and "" or ", "
            if (#s + #sep + #n) > 240 then SendChatMessage(s, chan); s = p .. n else s = s .. sep .. n end
        end
        if s ~= p then SendChatMessage(s, chan) end
    end
    if #noFlask == 0 and #noFood == 0 then SendChatMessage("[TwinGear] Raid Check: Everyone has Flask & Food!", chan); return end
    if #noFlask > 0 then SendSafe("[TwinGear] Missing Flask: ", noFlask) end
    if #noFood > 0 then SendSafe("[TwinGear] Missing Food: ", noFood) end
end

local inspHook = CreateFrame("Frame")
inspHook:RegisterEvent("ADDON_LOADED")
inspHook:SetScript("OnEvent", function(self, event, arg)
    if arg == "Blizzard_InspectUI" and InspectFrame and not InspectFrame.tgBtn then
        local b = CreateFrame("Button", nil, InspectFrame, "UIPanelButtonTemplate")
        b:SetSize(78, 20); b:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", -36, -4)
        b:SetText("|cffffd100Twin|r|cff00ff00Gear|r")
        b:SetScript("OnClick", function()
            if InspectFrame and not InCombatLockdown() then HideUIPanel(InspectFrame) end
            TG.Frame:Show()
            TG:SwitchTab(1)
            if UnitExists("target") and UnitIsPlayer("target") then
                TG.InspectUnit = "target"
                TG:ScanUnit("target", true)
                TG:RequestInspect("target", true, true)
            end
        end)
        InspectFrame.tgBtn = b
    end
end)

function TG:InitMinimap()
    if TwinGearMinimapButton then return end
    local btn = CreateFrame("Button", "TwinGearMinimapButton", UIParent)
    btn:SetSize(32, 32); btn:SetFrameStrata("HIGH"); btn:SetFrameLevel(15)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp"); btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54); overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); overlay:SetPoint("TOPLEFT")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20); icon:SetTexture("Interface\\Icons\\INV_Helmet_06"); icon:SetPoint("CENTER", 0, 1)

    local function UpdatePos()
        local angle = math.rad((TwinGearDB and TwinGearDB.minimapAngle) or 210)
        btn:ClearAllPoints(); btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 96, math.sin(angle) * 96)
    end

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            TwinGearDB = TwinGearDB or {}
            local mx, my = Minimap:GetCenter(); local cx, cy = GetCursorPosition(); local scale = Minimap:GetEffectiveScale()
            TwinGearDB.minimapAngle = math.deg(math.atan2((cy / scale) - my, (cx / scale) - mx))
            UpdatePos()
        end)
    end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if TG.Frame:IsShown() and TG.Frame.Page3:IsShown() then TG.Frame:Hide()
            else TG.Frame:Show(); TG:SwitchTab(3); TG:RunGroupScan() end
        else
            if TG.Frame:IsShown() then TG.Frame:Hide()
            else TG:SwitchTab(1); SlashCmdList["TWINGEAR"]("") end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffffd100Twin|r|cff00ff00Gear|r v2.2.3")
        GameTooltip:AddLine("|cffccccccLeft-Click:|r Toggle Window", 1, 1, 1)
        GameTooltip:AddLine("|cffccccccRight-Click:|r Scan Group / Raid", 1, 1, 1)
        GameTooltip:AddLine("|cffccccccDrag:|r Move Icon", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePos(); if TwinGearDB and TwinGearDB.hideMinimap then btn:Hide() else btn:Show() end
end

local mmInit = CreateFrame("Frame")
mmInit:RegisterEvent("PLAYER_ENTERING_WORLD")
mmInit:SetScript("OnEvent", function() TG:InitMinimap() end)

function TG:GetSecondaryProfsString()
    local _, _, arch, fish, cook, aid = GetProfessions()
    local list = {}
    for _, idx in ipairs({cook, fish, arch, aid}) do
        if idx then
            local n, _, r, m = GetProfessionInfo(idx)
            if n then
                local sCol = (r >= 600) and "|cff00ff00" or "|cffffd100"
                table.insert(list, string.format("|cffe6cc80%s:|r %s%d/%d|r", n, sCol, r, m))
            end
        end
    end
    return #list > 0 and table.concat(list, "  |  ") or nil
end

function TG:BuildPage4(f)
    if f.Page4 then return end
    local p4 = CreateFrame("Frame", nil, f); p4:SetAllPoints(); p4:Hide()
    f.Page4 = p4
    p4.Title = p4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p4.Title:SetPoint("TOPLEFT", 22, -46); p4.Title:SetWidth(580); p4.Title:SetJustifyH("LEFT")
    p4.Curr = p4:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p4.Curr:SetPoint("TOPLEFT", 22, -68); p4.Curr:SetWidth(605); p4.Curr:SetJustifyH("LEFT"); p4.Curr:SetSpacing(5)
    p4.WBHeader = p4:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p4.WBHeader:SetPoint("TOPLEFT", 22, -118); p4.WBHeader:SetWidth(605); p4.WBHeader:SetJustifyH("LEFT"); p4.WBHeader:SetSpacing(4)
    local aScroll = CreateFrame("ScrollFrame", nil, p4)
    aScroll:SetSize(608, 225); aScroll:SetPoint("TOPLEFT", 20, -172); aScroll:EnableMouseWheel(true)
    local aChild = CreateFrame("Frame", nil, aScroll); aChild:SetSize(605, 800)
    aScroll:SetScrollChild(aChild)
    aScroll:SetScript("OnMouseWheel", function(self, delta)
        local maxS = math.max(0, (p4.Alts:GetStringHeight() or 200) - 210)
        self:SetVerticalScroll(math.max(0, math.min(maxS, self:GetVerticalScroll() - (delta * 30))))
    end)
    p4.Alts = aChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p4.Alts:SetPoint("TOPLEFT", 2, -2); p4.Alts:SetWidth(600); p4.Alts:SetJustifyH("LEFT"); p4.Alts:SetSpacing(7)
    local h4 = p4:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    h4:SetPoint("BOTTOM", p4, "BOTTOM", 0, 38)
    h4:SetText("|cff888888Supports up to 50 account alts (Use mouse wheel to scroll)|r")
end

function TG:RefreshPage4()
    local f = TG.Frame; if not f then return end
    TG:BuildPage4(f)
    if TG.CurrentData and TG.CurrentData.isSelf and TG.SaveCurrentAlt then TG:SaveCurrentAlt(TG.CurrentData) end
    local p4 = f.Page4
    p4.Title:SetText("|cffffd100" .. TG:L("CURR_TITLE") .. "|r")
    local cParts = {}
    for _, item in ipairs(TG.GetMyCurrencies and TG:GetMyCurrencies() or {}) do
        local name, col, extraVal = item.label, "|cffaaaaaa", ""
        if item.id == 777 then name = "Timeless Coins"; col = "|cff00e676"
        elseif item.id == 396 then
            name = "Valor"; col = "|cffffd100"
            extraVal = string.format(" |cff999999(%d/%d)|r", math.floor((item.wk or 0)/100), (item.wkMax and item.wkMax > 0) and math.floor(item.wkMax/100) or 1000)
        elseif item.id == 395 then name = "Justice"; col = "|cff33aaff"
        elseif item.id == 776 then name = "Warforged Seal"; col = "|cffa335ee"
        elseif item.id == 738 then
            name = "Lesser Charm"; col = "|cff00ccff"
            if (UnitLevel("player") or 0) >= 90 and not (IsQuestFlaggedCompleted(33133) or IsQuestFlaggedCompleted(33134)) then extraVal = (item.amount >= 50) and " |cff00ff00(50+ OK)|r" or " |cffffaa00(/50)|r" end
        end
        table.insert(cParts, col .. name .. ":|r |cffffffff" .. item.amount .. "|r" .. extraVal)
    end
    local secP = TG:GetSecondaryProfsString()
    p4.Curr:SetText(table.concat(cParts, "  |cff555555•|r  ") .. (secP and ("\n|cff888888Secondary:|r " .. secP) or ""))
    local wbParts = {}
    for _, w in ipairs(TG.GetMyWorldBosses and TG:GetMyWorldBosses() or {}) do
        table.insert(wbParts, "|cffcccccc" .. w.name .. ":|r " .. (w.killed and "|cffff4444Killed|r" or "|cff00ff00Open|r"))
    end
    if #wbParts > 0 then
        local sealOk, _, cloakOk = false, false, false
        if TG.GetWeeklyExtras then sealOk, _, cloakOk = TG:GetWeeklyExtras() end
        p4.WBHeader:SetText("|cffffd100" .. TG:L("WB_TITLE") .. "|r " .. table.concat(wbParts, " |cff555555•|r ") .. string.format("  |cff555555•|r  |cffccccccBonus Roll:|r %s  |cff555555•|r  |cffccccccOrdos:|r %s", sealOk and "|cff00ff00Done|r" or "|cffffaa00Open|r", cloakOk and "|cffff8000Unlocked|r" or "|cff777777No Cloak|r"))
    end
    local lines, altList = { "|cff00e676" .. TG:L("ALT_HINT") .. "|r" }, {}
    for _, a in pairs((TwinGearDB and TwinGearDB.alts) or {}) do table.insert(altList, a) end
    table.sort(altList, function(x, y) return (x.ilvl or 0) > (y.ilvl or 0) end)
    for _, a in ipairs(altList) do
        local tok = a.classToken or string.upper(string.match(a.spec or "", "(%S+)$") or "WARRIOR")
        if tok == "KNIGHT" then tok = "DEATHKNIGHT" end
        local cc = (RAID_CLASS_COLORS and rawget(RAID_CLASS_COLORS, tok)) or { r = 1, g = 0.82, b = 0 }
        local ilvl = a.ilvl or 0
        local iCol = (ilvl >= 550 and "|cffff8000") or (ilvl >= 510 and "|cffa335ee") or (ilvl >= 460 and "|cff0070dd") or "|cff1eff00"
        local wbs = 0; for _, w in ipairs(a.wb or {}) do if w.killed then wbs = wbs + 1 end end
        local pr = {}; for _, x in ipairs(a.profs or {}) do table.insert(pr, "|cffcccccc" .. string.sub(x.name, 1, 4) .. ".|r |cffffd100" .. x.skill .. "|r") end
        local sealStr = ""
        if a.seals ~= nil then
            local sCol = a.seals > 0 and "|cffa335ee" or "|cffff4444"
            sealStr = string.format(" |cff555555•|r Seals: %s%d|r", sCol, a.seals)
        end
        local cdStr = (a.cds and #a.cds > 0) and (" |cff00ff00[" .. table.concat(a.cds, ", ") .. "]|r") or ""
        table.insert(lines, string.format("• |cff%02x%02x%02x%s|r |cff999999(%s, Lvl %d)|r — iLvl: %s%.1f|r |cff555555•|r WB: %s%d/6|r%s |cff555555•|r |cff33aaff%s|r |cff555555•|r %s%s",
            cc.r*255, cc.g*255, cc.b*255, a.name or "?", a.spec or "", a.level or 90, iCol, ilvl, (wbs >= 6) and "|cffff4444" or "|cff00ff00", wbs, sealStr, a.raid or "SoO 0/14", #pr > 0 and table.concat(pr, ", ") or "|cff777777No Profs|r", cdStr))
    end
    p4.Alts:SetText(table.concat(lines, "\n"))
    if p4.Alts:GetParent() then p4.Alts:GetParent():SetHeight(math.max(225, (p4.Alts:GetStringHeight() or 200) + 25)) end
end

local uiInitHook = CreateFrame("Frame")
uiInitHook:RegisterEvent("PLAYER_ENTERING_WORLD")
uiInitHook:SetScript("OnEvent", function()
    if PaperDollFrame and not PaperDollFrame.tgCharBtn then
        local b = CreateFrame("Button", nil, PaperDollFrame)
        b:SetSize(66, 18); b:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -34, -4)
        b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        b:SetBackdropColor(0.06, 0.06, 0.08, 0.94); b:SetBackdropBorderColor(0.80, 0.65, 0.22, 0.95)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); fs:SetPoint("CENTER"); fs:SetText("|cffffd100Twin|r|cff00ff00Gear|r")
        b:SetScript("OnClick", function() if TG.Frame and TG.Frame:IsShown() then TG.Frame:Hide() else TG.InspectUnit = "player"; if TG.ScanUnit then TG:ScanUnit("player", true) end; if TG.Frame then TG.Frame:Show(); TG:SwitchTab(1) end end end)
        PaperDollFrame.tgCharBtn = b
    end
end)

local modelSyncFrame = CreateFrame("Frame")
modelSyncFrame:RegisterEvent("UNIT_MODEL_CHANGED")
modelSyncFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
modelSyncFrame:SetScript("OnEvent", function(_, _, unit)
    if (not unit or unit == "player") and TG.Frame and TG.Frame:IsShown() and TG.CurrentData and TG.CurrentData.isSelf then
        TG:RefreshModel()
        if TG.After then TG:After(0.15, function() if TG.Frame and TG.Frame:IsShown() then TG:RefreshModel() end end) end
    end
end)

function TG:ApplyUnitModel(m, u)
    if not m or not u or not UnitExists(u) then return end
    m:ClearModel()
    m:SetUnit(u)
    if m.RefreshUnit then m:RefreshUnit() end
    m:SetPosition(-0.28, 0, 0)
end

function TG:RefreshModel()
    if TG.Frame and TG.Frame.Model then
        TG.Frame.Model.lastGUID = nil
        TG:ApplyUnitModel(TG.Frame.Model, (TG.CurrentData and TG.CurrentData.unit) or "player")
    end
end

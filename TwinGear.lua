BINDING_HEADER_TWINGEAR = "TwinGear 2.2.3"
BINDING_NAME_TWINGEAR_TOGGLE = "Toggle TwinGear Window"

local addonName, TG = ...
_G.TwinGear = TG
TG.Cache = {}
TG.History = {}
TG.LastInspect = 0

function TG:AddHistory(name)
    if not name then return end
    for i = #TG.History, 1, -1 do
        if TG.History[i] == name then table.remove(TG.History, i) end
    end
    table.insert(TG.History, 1, name)
    if #TG.History > 12 then table.remove(TG.History) end
end

local scanTip = CreateFrame("GameTooltip", "TwinGearScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function GetCloakName(id)
    if id == 102246 then return "Xing-Ho (Caster)"
    elseif id == 102247 then return "Jina-Kang (Healer)"
    elseif id == 102248 then return "Fen-Yu (Agi DPS)"
    elseif id == 102249 then return "Gong-Lu (Str DPS)"
    elseif id == 102245 then return "Qian-Le (Agi Tank)"
    elseif id == 102250 then return "Qian-Ying (Str Tank)" end
end

local function IsEnchantable(slot, loc)
    if slot == 3 or slot == 5 or slot == 7 or slot == 8 or slot == 9 or slot == 10 or slot == 15 or slot == 16 then
        return true
    end
    return (slot == 17 and loc and loc ~= "" and loc ~= "INVTYPE_HOLDABLE" and loc ~= "INVTYPE_SHIELD")
end

local function GetExpectedArmor(class)
    local _, cloth, leather, mail, plate = GetAuctionItemSubClasses(2)
    if class == "MAGE" or class == "PRIEST" or class == "WARLOCK" then return cloth
    elseif class == "ROGUE" or class == "DRUID" or class == "MONK" then return leather
    elseif class == "HUNTER" or class == "SHAMAN" then return mail
    elseif class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" then return plate end
    return nil
end

local ARMOR_SLOTS = { [1]=true, [3]=true, [5]=true, [6]=true, [7]=true, [8]=true, [9]=true, [10]=true }

local TIER_PREFIXES = {
    ["Cyclopean Dread"] = "T16", ["Shattered Vale"] = "T16", ["Unblinking Vigil"] = "T16",
    ["Chronomancer"] = "T16", ["Seven Sacred Seals"] = "T16", ["Winged Triumph"] = "T16",
    ["Ternion Glory"] = "T16", ["Barbed Assassin"] = "T16", ["Celestial Harmony"] = "T16",
    ["Horned Nightmare"] = "T16", ["Prehistoric Marauder"] = "T16",
    ["All-Consuming Maw"] = "T15", ["Haunted Forest"] = "T15", ["Saurok Stalker"] = "T15",
    ["Chromatic Hydra"] = "T15", ["Fire-Charm"] = "T15", ["Lightning Emperor"] = "T15",
    ["Exorcist"] = "T15", ["Nine-Tail"] = "T15", ["Witch Doctor"] = "T15",
    ["Thousandfold Hells"] = "T15", ["Last Mogu"] = "T15",
    ["Lost Catacomb"] = "T14", ["Eternal Blossom"] = "T14", ["Yaungol Slayer"] = "T14",
    ["Burning Scroll"] = "T14", ["Red Crane"] = "T14", ["White Tiger"] = "T14",
    ["Guardian Serpent"] = "T14", ["Thousandfold Blades"] = "T14", ["Firebird"] = "T14",
    ["Sha-Skin"] = "T14", ["Resounding Rings"] = "T14",
}

local function GetTierInfo(name, id)
    if id and TG.SET_LOOKUP and TG.SET_LOOKUP[id] then
        return TG.SET_LOOKUP[id]
    end
    if not name then return nil end
    for prefix, tier in pairs(TIER_PREFIXES) do
        if string.find(name, prefix, 1, true) then
            return tier
        end
    end
    return nil
end

local function GetSlotLabel(slot)
    local t = {
        "Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet",
        "Wrist", "Hands", "Ring 1", "Ring 2", "Trinket 1", "Trinket 2", "Back", "Main Hand", "Off Hand"
    }
    return t[slot] or ""
end

local function HasKilledStat(ids)
    for _, id in ipairs(ids) do
        local val = tonumber((GetStatistic(id)))
        if val and val > 0 then return true end
    end
    return false
end

function TG:GetMyRaids()
    local list = {
        { name = "Siege of Orgrimmar", total = 14, hasFlex = true,
          lfrWings = { {8458, 4}, {8459, 4}, {8461, 3}, {8462, 3} },
          bosses = {
              {8551,8552,8553,8554}, {8557,8558,8559,8560}, {8563,8564,8565,8566}, {8569,8570,8571,8573},
              {8576,8577,8578,8579}, {8582,8583,8584,8585}, {8588,8589,8590,8591}, {8594,8595,8596,8597},
              {8600,8601,8602,8603}, {8606,8607,8608,8609}, {8612,8613,8614,8615}, {8618,8619,8620,8621},
              {8624,8625,8626,8627}, {8630,8631,8632,8633}
          } },
        { name = "Throne of Thunder", total = 12,
          lfrWings = { {8069, 3}, {8070, 3}, {8071, 3}, {8072, 3} },
          bosses = {
              {8142,8143,8144}, {8149,8150,8151}, {8154,8155,8156}, {8159,8160,8162},
              {8164,8165,8166}, {8169,8170,8171}, {8174,8175,8176}, {8179,8180,8181},
              {8184,8185,8186}, {8189,8190,8191}, {8194,8195,8196}, {8199,8200,8201}
          } },
        { name = "Terrace of Endless Spring", total = 4,
          lfrWings = { {6689, 4} },
          bosses = { {6933,7967,7968}, {6934,7969,7970}, {6935,7971,7972}, {6936,7973,7974} } },
        { name = "Heart of Fear", total = 6,
          lfrWings = { {6718, 3}, {6845, 3} },
          bosses = { {6927,7954,7955}, {6928,7956,7957}, {6929,7958,7960}, {6930,7961,7962}, {6931,7963,7964}, {6932,7965,7966} } },
        { name = "Mogu'shan Vaults", total = 6,
          lfrWings = { {6458, 3}, {6844, 3} },
          bosses = { {6921,7914,7915}, {6922,7917,7918}, {6923,7919,7920}, {6924,7921,7922}, {6925,7923,7924}, {6926,7926,7927} } },
    }
    local out = {}
    local is90 = (UnitLevel("player") or 0) >= 90
    for _, r in ipairs(list) do
        local clr, lfrStat, flx, norm, hc = 0, 0, 0, 0, 0
        if is90 then
            for _, bStats in ipairs(r.bosses) do
                if HasKilledStat(bStats) then clr = clr + 1 end
                local s1, s2, s3, s4 = unpack(bStats)
                if r.hasFlex then
                    if (tonumber((GetStatistic(s1))) or 0) > 0 then lfrStat = lfrStat + 1 end
                    if (tonumber((GetStatistic(s2))) or 0) > 0 then flx = flx + 1 end
                    if (tonumber((GetStatistic(s3))) or 0) > 0 then norm = norm + 1 end
                    if (tonumber((GetStatistic(s4))) or 0) > 0 then hc = hc + 1 end
                else
                    if (tonumber((GetStatistic(s1))) or 0) > 0 then lfrStat = lfrStat + 1 end
                    if (tonumber((GetStatistic(s2))) or 0) > 0 then norm = norm + 1 end
                    if (tonumber((GetStatistic(s3))) or 0) > 0 then hc = hc + 1 end
                end
            end
        end
        local lfrAch = 0
        if is90 then
            for _, w in ipairs(r.lfrWings or {}) do
                local achId, bossCnt = unpack(w)
                local _, _, _, done, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(achId)
                if done and wasEarnedByMe then lfrAch = lfrAch + bossCnt end
            end
        end
        local lfr = math.max(lfrStat, lfrAch)
        clr = math.max(clr, lfr, flx, norm, hc)
        table.insert(out, {
            name = r.name, clr = clr, hc = hc, total = r.total,
            lfr = lfr, flx = flx, norm = norm, hasFlex = r.hasFlex
        })
    end
    return out
end

function TG:GetMyChallengeMode()
    local dungs = {
        { name = "Temple of the Jade Serpent", b = 6885, s = 6886, g = 6887 },
        { name = "Stormstout Brewery",         b = 6889, s = 6890, g = 6891 },
        { name = "Gate of the Setting Sun",    b = 6896, s = 6897, g = 6898 },
        { name = "Shado-Pan Monastery",        b = 6899, s = 6900, g = 6901 },
        { name = "Siege of Niuzao Temple",     b = 6902, s = 6903, g = 6904 },
        { name = "Mogu'shan Palace",           b = 6905, s = 6906, g = 6907 },
        { name = "Scholomance",                b = 6908, s = 6909, g = 6910 },
        { name = "Scarlet Halls",              b = 6911, s = 6912, g = 6913 },
        { name = "Scarlet Monastery",          b = 6914, s = 6915, g = 6916 },
    }
    local g, s, b = 0, 0, 0
    local list = {}
    for _, d in ipairs(dungs) do
        local tier = 0
        if (UnitLevel("player") or 0) >= 90 then
            if select(4, GetAchievementInfo(d.g)) then g = g + 1; s = s + 1; b = b + 1; tier = 3
            elseif select(4, GetAchievementInfo(d.s)) then s = s + 1; b = b + 1; tier = 2
            elseif select(4, GetAchievementInfo(d.b)) then b = b + 1; tier = 1 end
        end
        table.insert(list, { name = d.name, tier = tier })
    end
    local summary = "|cff8888880/9 None|r"
    if g == 9 then summary = "|cffffd1009/9 Gold|r"
    elseif g > 0 then summary = "|cffffd100" .. g .. "/9 Gold|r"
    elseif s > 0 then summary = "|cffcccccc" .. s .. "/9 Silver|r"
    elseif b > 0 then summary = "|cffcd7f32" .. b .. "/9 Bronze|r" end
    return summary, list
end

function TG:GetMyProfessions()
    local prof1, prof2 = GetProfessions()
    local out = {}
    for _, idx in ipairs({prof1, prof2}) do
        if idx then
            local name, _, rank, maxRank = GetProfessionInfo(idx)
            if name then
                table.insert(out, { name = name, rank = rank or 0, max = maxRank or 0 })
            end
        end
    end
    return out
end

local timerPool = {}
function TG:After(delay, func)
    local t = table.remove(timerPool) or CreateFrame("Frame")
    local el = 0
    t:Show()
    t:SetScript("OnUpdate", function(self, elapsed)
        el = el + elapsed
        if el >= delay then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            table.insert(timerPool, self)
            func()
        end
    end)
end

function TG:ScanUnit(unit, showUI)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local name = GetUnitName(unit, true)
    local isSelf = UnitIsUnit(unit, "player")
    local _, class = UnitClass(unit)
    local level = UnitLevel(unit)
    local guild = GetGuildInfo(unit) or "No Guild"

    local specName, specID, role = "", 0, "DAMAGER"
    if isSelf then
        local idx = GetSpecialization()
        if idx then
            specID, specName = GetSpecializationInfo(idx)
            role = GetSpecializationRole(idx) or "DAMAGER"
        end
    else
        specID = GetInspectSpecialization(unit) or 0
        if specID > 0 and GetSpecializationInfoByID then
            _, specName = GetSpecializationInfoByID(specID)
            if GetSpecializationRoleByID then role = GetSpecializationRoleByID(specID) or "DAMAGER" end
        end
    end

    local totalILvl, count, is2H = 0, 0, false
    local mh, oh = GetInventoryItemLink(unit, 16), GetInventoryItemLink(unit, 17)
    if mh then
        local _, _, _, _, _, _, _, _, loc = GetItemInfo(mh)
        if not oh and (loc == "INVTYPE_2HWEAPON" or loc == "INVTYPE_RANGED" or loc == "INVTYPE_RANGEDRIGHT") then is2H = true end
    end

    local hasFlask, hasFood = false, false
    for b = 1, 40 do
        local bName, _, bIcon, _, _, _, _, _, _, _, sId = UnitBuff(unit, b)
        if not bName then break end
        local lowName = string.lower(bName)
        local lowIcon = string.lower(bIcon or "")
        if string.find(lowName, "flask of") or string.find(lowIcon, "alchemy_flask") or string.find(lowIcon, "inv_alchemy_")
            or (sId and sId >= 105681 and sId <= 105696) or sId == 105617 or sId == 127230 or string.find(lowName, "elixir") then
            hasFlask = true
        end
        if string.find(lowName, "well fed") or string.find(lowIcon, "spell_misc_food") or string.find(lowIcon, "inv_misc_food") or string.find(lowIcon, "inv_cooking") or string.find(lowIcon, "inv_misc_fish")
            or (sId and ((sId >= 104264 and sId <= 104283) or (sId >= 124210 and sId <= 124221) or (sId >= 125070 and sId <= 125115) or (sId >= 146804 and sId <= 146809))) then
            hasFood = true
        end
    end

    local d = {
        hasFlask = hasFlask, hasFood = hasFood, unit = unit, name = name, class = class,
        level = level, guild = guild, spec = specName or "", specID = specID, role = role,
        isSelf = isSelf, time = GetTime(), ilvl = 0, cloak = "None", hasMeta = false,
        t16 = 0, tiers = { T14 = 0, T15 = 0, T16 = 0 },
        upgCur = 0, upgMax = 0, missGems = 0, missEnch = 0, missBuckle = false,
        wrongArmor = 0, reforged = 0, hasEng = false, profs = {}, pvp = 0, items = {}
    }
    local rawLines = {}
    local expArmor = GetExpectedArmor(class)
    local armorPieces = 0

    for _, slot in ipairs({1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17}) do
        local link = GetInventoryItemLink(unit, slot)
        if link then
            local iName, _, qual, baseLvl, _, iType, iSubType, _, loc, icon = GetItemInfo(link)
            local id = tonumber(string.match(link, "item:(%d+)")) or 0
            local realLvl, uCur, uMax, emptySoc, totSoc, isPvp, slotProf = baseLvl or 0, 0, 0, 0, 0, false, nil
            local itemParts = { strsplit(":", string.match(link, "item:([-%d:]+)") or "") }
            local isReforged = (tonumber(itemParts[11]) or 0) > 0
            local isWrongArmor = false

            local armorClass = select(2, GetAuctionItemClasses())
            if ARMOR_SLOTS[slot] and iType == armorClass and expArmor and iSubType then
                armorPieces = armorPieces + 1
                if iSubType ~= expArmor then
                    isWrongArmor = true
                    d.wrongArmor = d.wrongArmor + 1
                end
            end

            scanTip:ClearLines()
            for t = 1, 4 do
                local tex = _G["TwinGearScanTipTexture" .. t]
                if tex then tex:SetTexture(nil) end
            end
            scanTip:SetInventoryItem(unit, slot)

            for t = 1, 4 do
                local tex = _G["TwinGearScanTipTexture" .. t]
                local path = tex and tex:GetTexture()
                if path and path ~= "" then
                    totSoc = totSoc + 1
                    if string.find(path, "EmptySocket") then emptySoc = emptySoc + 1 end
                end
            end

            for line = 2, scanTip:NumLines() do
                local fs = _G["TwinGearScanTipTextLeft" .. line]; local txt = (fs and fs:GetText()) or ""; if fs then local r,g,b = fs:GetTextColor(); if g>0.9 and r<0.2 and b<0.2 then table.insert(rawLines, txt) end end
                local ilvlPat = ITEM_LEVEL and string.gsub(ITEM_LEVEL, "%%d", "(%%d+)") or "Item Level (%d+)"
                local m = string.match(txt, ilvlPat) or string.match(txt, "Item Level (%d+)")
                if m then realLvl = tonumber(m) end
                local upgPat = ITEM_UPGRADE_TOOLTIP_FORMAT and string.gsub(ITEM_UPGRADE_TOOLTIP_FORMAT, "%%d", "(%%d+)") or "Upgrade Level:%s*(%d+)%s*/%s*(%d+)"
                local c, mx = string.match(txt, upgPat)
                if not c and string.find(txt, "Upgrade", 1, true) then c, mx = string.match(txt, "(%d+)%s*/%s*(%d+)") end
                if c and mx and tonumber(mx) and tonumber(mx) <= 6 then uCur, uMax = tonumber(c), tonumber(mx) end
                if not isReforged and string.find(txt, "(Reforged from", 1, true) then isReforged = true end
                -- Profession detection handled via Enchant ID below
            end
            if isReforged then d.reforged = d.reforged + 1 end
            local pvpSt = GetItemStats and GetItemStats(link)
            if pvpSt and ((pvpSt["ITEM_MOD_PVP_POWER_SHORT"] or 0) > 0 or (pvpSt["ITEM_MOD_RESILIENCE_RATING_SHORT"] or 0) > 0 or (pvpSt["ITEM_MOD_PVP_RESILIENCE_SHORT"] or 0) > 0) then isPvp = true end

            if realLvl > 0 then
                totalILvl = totalILvl + realLvl
                count = count + 1
                if slot == 16 and not oh and (is2H or loc == "INVTYPE_2HWEAPON" or loc == "INVTYPE_RANGED" or loc == "INVTYPE_RANGEDRIGHT") then
                    totalILvl = totalILvl + realLvl
                    count = count + 1
                end
            end

            if slot == 15 then d.cloak = GetCloakName(id) or (qual == 5 and "Legendary Cloak" or "Standard") end
            if slot == 1 and GetItemGem then
                local PRIMAL_METAS = { [76879]=true,[76884]=true,[76885]=true,[76886]=true,[76888]=true,[76890]=true,[76895]=true,[76897]=true,[95344]=true,[95345]=true,[95346]=true,[95347]=true }
                for g = 1, 3 do
                    local _, gLink = GetItemGem(link, g)
                    local gId = gLink and tonumber(string.match(gLink, "item:(%d+)"))
                    if gId and PRIMAL_METAS[gId] then d.hasMeta = true end
                end
            end
            local tCode = GetTierInfo(iName, id)
            if tCode then
                d.tiers[tCode] = (d.tiers[tCode] or 0) + 1
                if tCode == "T16" then d.t16 = d.t16 + 1 end
            end
            if uMax > 0 then d.upgMax = d.upgMax + 1; if uCur > 0 then d.upgCur = d.upgCur + 1 end end

            d.missGems = d.missGems + emptySoc
            local slotMissBuckle = (slot == 6 and realLvl >= 417 and totSoc == 0)
            if slotMissBuckle then d.missBuckle = true end

            local enchId = tonumber(string.match(link, "item:%d+:(%d+)")) or 0
            local ENG_IDS    = { [4898]=true, [4179]=true, [4223]=true, [4697]=true, [4698]=true }
            local TAILOR_IDS = { [4892]=true, [4893]=true, [4894]=true }
            local INSC_IDS   = { [4912]=true, [4913]=true, [4914]=true, [4915]=true }
            local LW_IDS     = { [4873]=true, [4874]=true, [4875]=true, [4877]=true }
            if slot == 10 and ENG_IDS[enchId] then slotProf = "Eng"; d.hasEng = true; d.profs["Eng"] = true
            elseif slot == 15 and TAILOR_IDS[enchId] then slotProf = "Tailor"; d.profs["Tailor"] = true
            elseif slot == 3 and INSC_IDS[enchId] then slotProf = "Insc"; d.profs["Insc"] = true
            elseif slot == 9 and LW_IDS[enchId] then slotProf = "LW"; d.profs["LW"] = true
            elseif (slot == 11 or slot == 12) and enchId > 0 then slotProf = "Ench"; d.profs["Ench"] = true end
            if (slot == 9 or slot == 10) and totSoc > 0 then
                local baseSt = GetItemStats and GetItemStats("item:" .. id)
                local baseSoc = 0
                if baseSt then
                    for k, v in pairs(baseSt) do
                        if string.find(k, "EMPTY_SOCKET_") then baseSoc = baseSoc + v end
                    end
                end
                if totSoc > baseSoc then slotProf = slotProf or "BS"; d.profs["BS"] = true end
            end
            if GetItemGem then
                local JC_EYES = { [83141]=true,[83142]=true,[83143]=true,[83144]=true,[83145]=true,[83146]=true,[83147]=true,[83148]=true,[83149]=true,[83150]=true,[83151]=true,[83152]=true,[83153]=true,[83154]=true,[83155]=true }
                for g = 1, 3 do
                    local _, gLink = GetItemGem(link, g)
                    local gId = gLink and tonumber(string.match(gLink, "item:(%d+)"))
                    if gId and JC_EYES[gId] then
                        slotProf = slotProf or "JC"; d.profs["JC"] = true
                    end
                end
            end
            local missE = IsEnchantable(slot, loc) and enchId == 0
            if missE then d.missEnch = d.missEnch + 1 end
            if isPvp then d.pvp = d.pvp + 1 end

            table.insert(d.items, {
                slotName = GetSlotLabel(slot), link = link, icon = icon, ilvl = realLvl,
                upg = uMax > 0 and (uCur .. "/" .. uMax) or "",
                missGem = emptySoc > 0, missBuckle = slotMissBuckle, missEnch = missE,
                profTag = slotProf, isReforged = isReforged, isWrongArmor = isWrongArmor
            })
        else
            table.insert(d.items, { slotName = GetSlotLabel(slot), empty = true })
        end
    end

    if isSelf and GetAverageItemLevel then
        local _, eq = GetAverageItemLevel()
        d.ilvl = math.floor((eq or 0) + 0.5)
    elseif count > 0 then
        d.ilvl = math.floor((totalILvl / count) + 0.5)
    end

    local armorOk = (armorPieces > 0 and d.wrongArmor == 0)
    local prev = TG.Cache[name]
    if prev and prev.isSynced and not isSelf then
        d.stats, d.isSynced, d.syncedRaids, d.syncedCM, d.syncedCMList, d.syncedProfs = prev.stats, true, prev.syncedRaids, prev.syncedCM, prev.syncedCMList, prev.syncedProfs
    else
        d.stats = isSelf and TG:GetSelfStats() or TG:EstimateTargetStats(unit, class, specID, rawLines, armorOk)
        d.isSynced = isSelf
    end

    if not isSelf and d.ilvl == 0 and prev and prev.ilvl and prev.ilvl > 0 then
        prev.hasFlask = d.hasFlask
        prev.hasFood = d.hasFood
        prev.unit = unit
        if showUI and TG.UpdateUI then TG:UpdateUI(prev) end
        return
    end
    if d.ilvl > 0 or isSelf then
        TG.Cache[name] = d
        if d.ilvl > 0 then TG:AddHistory(name) end
    end
    if showUI and TG.UpdateUI then TG:UpdateUI(d) end
end

function TG:RequestInspect(unit, showUI, force)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    if UnitIsUnit(unit, "player") then TG:ScanUnit("player", showUI); return end

    local name = GetUnitName(unit, true)
    local c = TG.Cache[name]
    if c and (GetTime() - c.time) < 45 and not force then
        if showUI and TG.UpdateUI then TG:UpdateUI(c) end
        return
    end

    if not CanInspect(unit) or InCombatLockdown() or (InspectFrame and InspectFrame:IsShown()) then return end
    if not showUI and (GetTime() - TG.LastInspect) < 0.15 then return end

    TG.InspectQueue = TG.InspectQueue or {}
    local guid = UnitGUID(unit)
    if TG.Pending and TG.Pending.time and (GetTime() - TG.Pending.time) > 1.2 then TG.Pending = nil end
    if TG.Pending then
        if TG.Pending.guid == guid then TG.Pending.showUI = TG.Pending.showUI or showUI; return end
        if not showUI then
            for _, q in ipairs(TG.InspectQueue) do if q.guid == guid then return end end
            table.insert(TG.InspectQueue, { guid = guid, showUI = showUI, unit = unit }); return
        end
    end
    TG.LastInspect = GetTime()
    TG.Pending = { guid = guid, showUI = showUI, unit = unit, time = GetTime() }

    if showUI then
        TG.InspectUnit = unit
        local tGuid = UnitGUID(unit)
        TG:After(0.65, function()
            if TG.Pending and TG.Pending.guid == tGuid and TG.Frame and TG.Frame:IsShown() and UnitExists("target") and UnitGUID("target") == tGuid then
                if not TG.CurrentData or TG.CurrentData.name ~= GetUnitName("target", true) then
                    NotifyInspect("target")
                end
            end
        end)
    end

    NotifyInspect(unit)
    if TG.RequestSyncData then TG:RequestSyncData(unit) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("INSPECT_READY")
ev:RegisterEvent("GET_ITEM_INFO_RECEIVED")
ev:RegisterEvent("UNIT_INVENTORY_CHANGED")
ev:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
ev:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
ev:RegisterEvent("UNIT_STATS")
ev:RegisterEvent("UNIT_AURA")
ev:RegisterEvent("PLAYER_LOGOUT")

ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        TwinGearDB = TwinGearDB or { scale = 1.0, showTip = true }
        if TG.InitUI then TG:InitUI() end
        if TG.InitSync then TG:InitSync() end

    elseif event == "PLAYER_ENTERING_WORLD" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Twin|r|cff00ff00Gear|r v2.2.3 loaded. Type |cffffd100/tg|r to open or |cffffd100/tg help|r for commands.")
        TG:ScanUnit("player", false)
        if TG.SaveCurrentAlt and TG.Cache[GetUnitName("player", true)] then
            TG:SaveCurrentAlt(TG.Cache[GetUnitName("player", true)])
        end

    elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "ACTIVE_TALENT_GROUP_CHANGED" or (event == "UNIT_STATS" and arg1 == "player") then
        if (event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM") and TG.RefreshModel then TG:RefreshModel() end
        TG:ScanUnit("player", false)
        if TG.Frame and TG.Frame:IsShown() and TG.CurrentData and TG.CurrentData.isSelf then
            TG:ScanUnit("player", true)
        end

    elseif event == "PLAYER_LOGOUT" then
        TG:ScanUnit("player", false)
        if TG.SaveCurrentAlt and TG.Cache[GetUnitName("player", true)] then
            TG:SaveCurrentAlt(TG.Cache[GetUnitName("player", true)])
        end

    elseif event == "UNIT_AURA" then
        if TG.Frame and TG.Frame:IsShown() and TG.CurrentData then
            if arg1 == "player" and TG.CurrentData.isSelf then
                TG:ScanUnit("player", true)
            elseif arg1 == "target" and not TG.CurrentData.isSelf and UnitExists("target") then
                TG:ScanUnit("target", true)
            end
        end

    elseif event == "UPDATE_MOUSEOVER_UNIT" and TwinGearDB and TwinGearDB.showTip
        and UnitExists("mouseover") and UnitIsPlayer("mouseover") and not UnitIsUnit("mouseover", "player") then
        TG:RequestInspect("mouseover", false)

    elseif event == "PLAYER_TARGET_CHANGED" and TG.Frame and TG.Frame:IsShown() then
        if UnitExists("target") and UnitIsPlayer("target") then
            if CanInspect("target") or UnitIsUnit("target", "player") then
                TG.Frame.Title:SetText(GetUnitName("target", true) .. " - |cff888888Loading...|r")
                TG:RequestInspect("target", true, true)
            else
                TG.Frame.Title:SetText(GetUnitName("target", true) .. " - |cffff3333Out of range|r")
            end
        else
            TG.InspectUnit = "player"
            TG:ScanUnit("player", true)
        end

    elseif event == "GET_ITEM_INFO_RECEIVED" or (event == "UNIT_INVENTORY_CHANGED" and (arg1 == "target" or arg1 == "player")) then
        if event == "UNIT_INVENTORY_CHANGED" and TG.RefreshModel then TG:RefreshModel() end
        if arg1 == "player" then TG:ScanUnit("player", false) end
        local u = TG.InspectUnit or (TG.CurrentData and TG.CurrentData.unit)
        if TG.Frame and TG.Frame:IsShown() and u and UnitExists(u) and UnitIsPlayer(u) then
            TG:ScanUnit(u, true)
        end

    elseif event == "INSPECT_READY" and ((TG.Pending and arg1 == TG.Pending.guid) or (UnitExists("target") and UnitGUID("target") == arg1)) then
        local show = (TG.Pending and TG.Pending.showUI) or (TG.Frame and TG.Frame:IsShown() and UnitExists("target") and UnitGUID("target") == arg1)
        local guid = arg1
        TG.Pending = nil

        local u = (UnitExists("target") and UnitGUID("target") == guid and "target")
            or (UnitExists("mouseover") and UnitGUID("mouseover") == guid and "mouseover")
        if not u and IsInGroup() then
            local prefix = IsInRaid() and "raid" or "party"
            for i = 1, GetNumGroupMembers() do
                local gu = prefix .. i
                if UnitExists(gu) and UnitGUID(gu) == guid then u = gu; break end
            end
        end

        if u then
            TG:ScanUnit(u, show)
            if TG.Frame and TG.Frame.Page3 and TG.Frame.Page3:IsShown() then TG:RefreshGroupList() end
            if GameTooltip:IsShown() then
                local _, ttUnit = GameTooltip:GetUnit()
                if ttUnit and UnitGUID(ttUnit) == guid then GameTooltip:SetUnit(ttUnit) end
            end
            if show then
                TG:After(0.35, function()
                    if TG.Frame and TG.Frame:IsShown() and UnitExists("target") and UnitGUID("target") == guid then
                        TG:ScanUnit("target", true)
                    end
                    ClearInspectPlayer()
                end)
            elseif u == "mouseover" then
                TG:After(0.35, function()
                    if UnitExists("mouseover") and UnitGUID("mouseover") == guid then
                        TG:ScanUnit("mouseover", false)
                        if GameTooltip:IsShown() then
                            local _, ttUnit = GameTooltip:GetUnit()
                            if ttUnit and UnitGUID(ttUnit) == guid then GameTooltip:SetUnit(ttUnit) end
                        end
                    end
                    ClearInspectPlayer()
                end)
            else
                ClearInspectPlayer()
            end
        else
            ClearInspectPlayer()
        end
        if TG.InspectQueue and #TG.InspectQueue > 0 then
            local nxt = table.remove(TG.InspectQueue, 1)
            if nxt and nxt.unit and UnitExists(nxt.unit) and UnitGUID(nxt.unit) == nxt.guid then
                TG:After(0.15, function() TG:RequestInspect(nxt.unit, nxt.showUI) end)
            end
        end
    end
end)

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if TwinGearDB and not TwinGearDB.showTip then return end
    local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end
    if UnitIsUnit(unit, "player") then TG:ScanUnit("player", false) else TG:RequestInspect(unit, false) end
    local d = TG.Cache[GetUnitName(unit, true)]
    if d and d.ilvl > 0 then
        local me = TG.Cache[GetUnitName("player", true)]
        local diff = d.ilvl - (me and me.ilvl or d.ilvl)
        local col = diff >= 10 and "|cffff3333" or (diff >= 3 and "|cffff9900" or (diff <= -10 and "|cff00ff00" or "|cffffff00"))
        local spStr = (d.spec and d.spec ~= "") and (" |cffcccccc(" .. d.spec .. ")|r") or ""
        self:AddDoubleLine("|cffffd100Twin|r|cff00ff00Gear|r iLvl:", col .. d.ilvl .. "|r" .. spStr .. (d.isSynced and " |cff00ccff[Sync]|r" or ""))
        self:Show()
    end
end)

SLASH_TWINGEAR1 = "/tg"; SLASH_TWINGEAR2 = "/twingear"
SlashCmdList["TWINGEAR"] = function(msg)
    if not TG.Frame then return end
    local cmd = string.lower(strtrim(msg or ""))
    if cmd == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Twin|r|cff00ff00Gear|r v2.2.3 commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/tg|r - Toggle main window")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/tg scan|r - Open Group Scan & scan party/raid")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/tg tooltip|r - Toggle iLvl in player tooltip")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/tg minimap|r - Toggle minimap icon")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/tg reset|r - Reset window position & scale")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffd100/tgclearalts|r - Clear saved account alts roster")
    elseif cmd == "scan" then
        TG.Frame:Show(); TG:SwitchTab(3); TG:RunGroupScan()
    elseif cmd == "tooltip" then
        TwinGearDB = TwinGearDB or {}
        TwinGearDB.showTip = not TwinGearDB.showTip
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Twin|r|cff00ff00Gear|r tooltip: " .. (TwinGearDB.showTip and "|cff00ff00ON|r" or "|cffff3333OFF|r"))
    elseif cmd == "minimap" then
        TwinGearDB = TwinGearDB or {}
        TwinGearDB.hideMinimap = not TwinGearDB.hideMinimap
        if TwinGearMinimapButton then
            if TwinGearDB.hideMinimap then TwinGearMinimapButton:Hide() else TwinGearMinimapButton:Show() end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Twin|r|cff00ff00Gear|r minimap icon: " .. (TwinGearDB.hideMinimap and "|cffff3333Hidden|r" or "|cff00ff00Shown|r"))
    elseif cmd == "reset" then
        TwinGearDB = TwinGearDB or {}
        TwinGearDB.scale = 1.0
        TG.Frame:SetScale(1.0); TG.Frame:ClearAllPoints(); TG.Frame:SetPoint("CENTER")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Twin|r|cff00ff00Gear|r window position and scale reset.")
    else
        if TG.Frame:IsShown() then TG.Frame:Hide()
        else
            TG.Frame:Show()
            if UnitExists("target") and UnitIsPlayer("target") then TG:RequestInspect("target", true)
            else TG.InspectUnit = "player"; TG:ScanUnit("player", true) end
        end
    end
end

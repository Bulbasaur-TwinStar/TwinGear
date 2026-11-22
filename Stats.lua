local _, TG = ...

local function GetMasteryMult(specID)
    if specID == 250 then return 6.25
    elseif specID == 259 then return 3.5
    elseif specID == 103 then return 3.125
    elseif specID == 265 then return 3.1
    elseif specID == 261 or specID == 264 then return 3.0
    elseif specID == 252 then return 2.5
    elseif specID == 70 then return 2.1
    elseif specID == 258 then return 1.8
    elseif specID == 256 then return 1.6
    elseif specID == 63 or specID == 73 or specID == 104 or specID == 255 or specID == 270 then return 1.5
    elseif specID == 72 then return 1.4
    elseif specID == 65 or specID == 105 or specID == 257 or specID == 269 then return 1.25
    elseif specID == 66 or specID == 266 or specID == 267 or specID == 268 then return 1.0 end
    return 2.0
end

local function HasBuffID(unit, id)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, sId = UnitBuff(unit, i)
        if not name then break end
        if sId == id then return true end
    end
    return false
end

local function GetRoleCategory(class, specID, specIdx, unit)
    unit = unit or "player"
    if class == "HUNTER" then return "RANGED" end
    if specID == 104 or specID == 250 or specID == 66 or specID == 73 or specID == 268 then return "TANK" end
    if specID == 105 or specID == 264 or specID == 65 or specID == 270 or specID == 256 or specID == 257 then return "HEALER" end
    if specID == 102 or specID == 262 or specID == 258 or class == "MAGE" or class == "WARLOCK" then return "CASTER" end
    if specID == 103 or specID == 251 or specID == 252 or specID == 269 or specID == 70 or specID == 259 or specID == 260 or specID == 261 or specID == 263 or specID == 71 or specID == 72 then return "MELEE" end

    if class == "DRUID" then
        if HasBuffID(unit, 768) then return "MELEE" end
        if HasBuffID(unit, 5487) then return "TANK" end
        if HasBuffID(unit, 24858) then return "CASTER" end
    elseif class == "DEATHKNIGHT" then
        if HasBuffID(unit, 48263) then return "TANK" end
        if HasBuffID(unit, 48266) or HasBuffID(unit, 48265) then return "MELEE" end
    elseif class == "WARRIOR" then
        if HasBuffID(unit, 71) then return "TANK" end
        if HasBuffID(unit, 2457) or HasBuffID(unit, 2458) then return "MELEE" end
    elseif class == "MONK" then
        if HasBuffID(unit, 115069) then return "TANK" end
        if HasBuffID(unit, 103985) then return "MELEE" end
    end

    if specIdx and specIdx > 0 then
        local role = GetSpecializationRole(specIdx)
        if role == "TANK" then return "TANK" end
        if role == "HEALER" then return "HEALER" end
        if (class == "DRUID" and specIdx == 1) or (class == "SHAMAN" and specIdx == 1) or class == "PRIEST" then
            return "CASTER"
        end
    end
    return "MELEE"
end

function TG:GetSelfStats()
    local _, class = UnitClass("player")
    local specIdx = GetSpecialization() or 0
    local specID = specIdx > 0 and (GetSpecializationInfo(specIdx) or 0) or 0
    local cat = GetRoleCategory(class, specID, specIdx, "player")

    local str = select(2, UnitStat("player", 1)) or 0
    local agi = select(2, UnitStat("player", 2)) or 0
    local sta = select(2, UnitStat("player", 3)) or 0
    local int = select(2, UnitStat("player", 4)) or 0
    local spi = select(2, UnitStat("player", 5)) or 0
    local hp = UnitHealthMax("player") or 0
    local _, armor = UnitArmor("player")

    local ap = 0
    if cat == "RANGED" then
        local bR, pR, nR = UnitRangedAttackPower("player")
        ap = (bR or 0) + (pR or 0) + (nR or 0)
    else
        local bA, pA, nA = UnitAttackPower("player")
        ap = (bA or 0) + (pA or 0) + (nA or 0)
    end

    local sp, maxCrit = 0, 0
    for sch = 2, 7 do
        sp = math.max(sp, GetSpellBonusDamage(sch) or 0)
        maxCrit = math.max(maxCrit, GetSpellCritChance(sch) or 0)
    end
    if cat == "HEALER" then sp = math.max(sp, GetSpellBonusHealing() or 0) end

    local isSpell = (cat == "CASTER" or cat == "HEALER")
    local critVal = isSpell and maxCrit or (cat == "RANGED" and GetRangedCritChance() or GetCritChance())
    local hasteVal = isSpell and UnitSpellHaste("player") or (cat == "RANGED" and GetRangedHaste() or GetMeleeHaste())
    local mastVal = ((UnitLevel("player") or 0) >= 80) and (GetMasteryEffect() or 0) or 0
    local hitVal = isSpell and GetCombatRatingBonus(8) or (cat == "RANGED" and GetCombatRatingBonus(7) or GetCombatRatingBonus(6))
    local expVal = (cat == "RANGED" and select(2, GetExpertise()) or GetExpertise()) or 0
    local dodgeVal = GetDodgeChance() or 0
    local parryVal = GetParryChance() or 0
    local pvpPower = GetPvpPowerDamage and (GetPvpPowerDamage() or 0) or 0
    local resilVal = GetCombatRatingBonus and (GetCombatRatingBonus(16) or 0) or 0
    local _, combatRegen = GetManaRegen()
    local mp5Val = math.floor(((combatRegen or 0) * 5) + 0.5)

    return {
        cat = cat, specID = specID, hp = hp, armor = armor or 0,
        str = str, agi = agi, sta = sta, int = int, spi = spi, ap = ap, sp = sp, mp5 = mp5Val,
        crit = string.format("%.2f%%", critVal or 0),
        haste = string.format("%.2f%%", hasteVal or 0),
        mast = string.format("%.2f%%", mastVal),
        hit = string.format("%.2f%%", hitVal or 0),
        exp = string.format("%.2f%%", expVal),
        dodge = string.format("%.2f%%", dodgeVal),
        parry = string.format("%.2f%%", parryVal),
        pvp = string.format("%.2f%%", pvpPower),
        resil = string.format("%.2f%%", resilVal),
    }
end

local STAT_PATS = {
    { "^%+([%d%s%,%.]+)%s+Strength", "STR" },
    { "^%+([%d%s%,%.]+)%s+Agility", "AGI" },
    { "^%+([%d%s%,%.]+)%s+Stamina", "STA" },
    { "^%+([%d%s%,%.]+)%s+Intellect", "INT" },
    { "^%+([%d%s%,%.]+)%s+Spirit", "SPI" },
    { "^%+([%d%s%,%.]+)%s+Critical Strike", "CRIT" },
    { "^%+([%d%s%,%.]+)%s+Crit", "CRIT" },
    { "^%+([%d%s%,%.]+)%s+Haste", "HASTE" },
    { "^%+([%d%s%,%.]+)%s+Mastery", "MAST" },
    { "^%+([%d%s%,%.]+)%s+Hit", "HIT" },
    { "^%+([%d%s%,%.]+)%s+Expertise", "EXP" },
    { "^%+([%d%s%,%.]+)%s+Dodge", "DODGE" },
    { "^%+([%d%s%,%.]+)%s+Parry", "PARRY" },
    { "^%+([%d%s%,%.]+)%s+PvP Power", "PVP" },
    { "^%+([%d%s%,%.]+)%s+PvP Resilience", "RESIL" },
}

local function ParseNum(str)
    if not str then return 0 end
    return tonumber((str:gsub("[^%d]", ""))) or 0
end

local function ParseTooltipLines(s, lines)
    if not lines then return end
    for _, raw in ipairs(lines) do
        local clean = raw:gsub("^Enchanted:%s*", ""):gsub("^Socket Bonus:%s*", ""):gsub("%s*%b()", "")
        if not clean:find("^Equip:") and not clean:find("^Use:") and not clean:find("^Set:") and not clean:find("^Chance on hit:") then
            local arm = clean:match("^([%d%s%,%.]+)%s+Armor")
            if arm then
                s.ARMOR = s.ARMOR + ParseNum(arm)
            else
                local norm = clean:gsub(",%s*%+", "|+"):gsub("%s+and%s+%+", "|+")
                for part in norm:gmatch("[^|]+") do
                    part = part:match("^%s*(.-)%s*$")
                    if not part:match("^%+[%d%s%,%.]+%%") then
                        local allVal = part:match("^%+([%d%s%,%.]+)%s+All Stats")
                        if allVal then
                            local v = ParseNum(allVal)
                            s.STR = s.STR + v; s.AGI = s.AGI + v; s.STA = s.STA + v; s.INT = s.INT + v; s.SPI = s.SPI + v
                        else
                            for _, p in ipairs(STAT_PATS) do
                                local valStr = part:match(p[1])
                                if valStr then
                                    s[p[2]] = s[p[2]] + ParseNum(valStr)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function TG:EstimateTargetStats(unit, class, specID, lines)
    local cat = GetRoleCategory(class, specID, 0, unit)
    local _, race = UnitRace(unit)
    local s = { STA=0, INT=0, AGI=0, STR=0, SPI=0, CRIT=0, HASTE=0, MAST=0, HIT=0, EXP=0, DODGE=0, PARRY=0, ARMOR=0, PVP=0, RESIL=0 }
    ParseTooltipLines(s, lines)

    local hitBonus = (race == "Draenei") and 1.0 or 0
    local isSpell = (cat == "CASTER" or cat == "HEALER")
    local spiToHit = (specID == 102 or specID == 258 or specID == 262) and s.SPI or 0
    local hitPct = (((isSpell and (s.HIT + spiToHit) or s.HIT)) / 340) + hitBonus
    local expPct = s.EXP / 340
    local gobMult = (race == "Goblin") and 1.01 or 1.0
    local hastePct = ((1 + (s.HASTE / 425) / 100) * gobMult - 1) * 100

    return {
        isGearOnly = true,
        rawSpi = s.SPI, rawCrit = s.CRIT, rawHaste = s.HASTE, rawMast = s.MAST,
        rawHit = s.HIT, rawExp = s.EXP, rawDodge = s.DODGE, rawParry = s.PARRY,
        rawArmor = s.ARMOR, rawPvp = s.PVP, rawResil = s.RESIL,
        cat = cat, specID = specID, hp = UnitHealthMax(unit) or 0,
        haste = string.format("%.2f%%", hastePct),
        hit = string.format("%.2f%%", hitPct),
        exp = string.format("%.2f%%", expPct),
    }
end

local SPEC_HASTE_BPS = {}
rawset(SPEC_HASTE_BPS, 102, { 5273, 10289 })
rawset(SPEC_HASTE_BPS, 105, { 3043, 13163 })
rawset(SPEC_HASTE_BPS, 258, { 8085, 10124 })
rawset(SPEC_HASTE_BPS, 257, { 4721, 13163 })
rawset(SPEC_HASTE_BPS, 265, { 9778, 13737 })
rawset(SPEC_HASTE_BPS, 266, { 8064, 14873 })
rawset(SPEC_HASTE_BPS, 267, { 4717, 10124 })
rawset(SPEC_HASTE_BPS, 62,  { 9762, 13163 })
rawset(SPEC_HASTE_BPS, 63,  { 3056, 13163 })
rawset(SPEC_HASTE_BPS, 64,  { 9762, 14242 })
rawset(SPEC_HASTE_BPS, 264, { 3764, 7613 })
rawset(SPEC_HASTE_BPS, 262, { 8882, 13163 })
rawset(SPEC_HASTE_BPS, 65,  { 3506, 7170 })
rawset(SPEC_HASTE_BPS, 270, { 6141, 9158 })

function TG:GetBreakpointSummary(stats, unit)
    if not stats or (stats.cat ~= "CASTER" and stats.cat ~= "HEALER") then return nil end
    unit = unit or "player"

    local hitMsg = ""
    if stats.cat == "CASTER" then
        local hitNum = tonumber((string.match(tostring(stats.hit or "0"), "([%d%.]+)"))) or 0
        local diff = hitNum - 15.00
        hitMsg = (math.abs(diff) <= 0.15) and string.format("|cff00ff00OK (%.2f%%)|r", hitNum)
            or (diff > 0.15 and string.format("|cffffaa00+%.2f%% Over (-%d)|r", diff, math.floor(diff * 340))
            or string.format("|cffff4444-%.2f%% (+%d)|r", math.abs(diff), math.ceil(math.abs(diff) * 340)))
    end

    local hr = 0
    if UnitIsUnit(unit, "player") then
        hr = GetCombatRating(20) or 0
    else
        local hPct = tonumber((string.match(tostring(stats.haste or "0"), "([%d%.]+)"))) or 0
        local hasBuff = false
        for i = 1, 40 do
            local bName, _, _, _, _, _, _, _, _, _, sId = UnitBuff(unit, i)
            if not bName then break end
            if sId == 24907 or sId == 49868 or sId == 15473 or sId == 51470 then hasBuff = true break end
        end
        local _, rCheck = UnitRace(unit)
        local div = (hasBuff and 1.05 or 1.0) * (rCheck == "Goblin" and 1.01 or 1.0)
        if div > 1.0 then
            hPct = (((1 + hPct / 100) / div) - 1) * 100
        end
        hr = math.max(0, math.floor(hPct * 425))
    end

    local _, race = UnitRace(unit)
    local isGoblin = (race == "Goblin")
    local bps = rawget(SPEC_HASTE_BPS, stats.specID or 0)
    local bpMsg

    if bps then
        local bp1, bp2 = unpack(bps)
        if isGoblin then
            bp1 = math.max(0, bp1 - 445)
            bp2 = math.max(0, bp2 - 485)
        end
        if hr >= bp2 then
            bpMsg = string.format("|cff00ff00BP 2 (%d / %d)|r", hr, bp2)
        elseif hr >= bp1 then
            bpMsg = string.format("|cff00e676BP 1 (-%d to %d)|r", bp2 - hr, bp2)
        else
            bpMsg = string.format("|cffffaa00%d (-%d to %d)|r", hr, bp1 - hr, bp1)
        end
    else
        bpMsg = string.format("|cffaaaaaaNo fixed BP (%d)|r", hr)
    end

    return hitMsg .. "\n" .. bpMsg
end

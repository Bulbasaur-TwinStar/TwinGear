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

local PATS = {
    {"%+(%d+)%s+Strength","STR"},{"%+(%d+)%s+Agility","AGI"},{"%+(%d+)%s+Stamina","STA"},
    {"%+(%d+)%s+Intellect","INT"},{"%+(%d+)%s+Spirit","SPI"},{"%+(%d+)%s+Spell Power","SP"},
    {"%+(%d+)%s+Attack Power","AP"},{"%+(%d+)%s+Critical Strike","CRIT"},{"%+(%d+)%s+Crit","CRIT"},
    {"%+(%d+)%s+Haste","HASTE"},{"%+(%d+)%s+Mastery","MAST"},{"%+(%d+)%s+Hit","HIT"},
    {"%+(%d+)%s+Expertise","EXP"},{"%+(%d+)%s+Dodge","DODGE"},{"%+(%d+)%s+Parry","PARRY"},
    {"%+(%d+)%s+PvP Power","PVP"},{"%+(%d+)%s+PvP Resilience","RESIL"}
}
local function AddExtras(s, lines)
    if not lines then return end
    for _, l in ipairs(lines) do
        if not l:find("^Equip:") and not l:find("^Use:") and not l:find("^Set:") and not l:find("^%(") then
            for part in l:gmatch("[^,]+") do
                local a = part:match("%+(%d+)%s+All Stats")
                if a then local v = tonumber(a) or 0; s.STR=s.STR+v; s.AGI=s.AGI+v; s.STA=s.STA+v; s.INT=s.INT+v; s.SPI=s.SPI+v
                else for _, p in ipairs(PATS) do local v = part:match(p[1]); if v then s[p[2]] = s[p[2]] + (tonumber(v) or 0) end end end
            end
        end
    end
end

function TG:EstimateTargetStats(unit, class, specID, lines, armorOk)
    local cat = GetRoleCategory(class, specID, 0, unit)
    local _, race = UnitRace(unit)
    local s = { STA=150, INT=160, AGI=160, STR=160, SPI=160, SP=0, AP=0, CRIT=0, HASTE=0, MAST=0, HIT=0, EXP=0, DODGE=0, PARRY=0, ARMOR=0, PVP=0, RESIL=0 }

    local st = {}
    for _, slot in ipairs({1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17}) do
        local link = GetInventoryItemLink(unit, slot)
        if link and GetItemStats then
            wipe(st)
            GetItemStats(link, st)
            s.STA   = s.STA   + (st["ITEM_MOD_STAMINA_SHORT"] or 0)
            s.INT   = s.INT   + (st["ITEM_MOD_INTELLECT_SHORT"] or 0)
            s.AGI   = s.AGI   + (st["ITEM_MOD_AGILITY_SHORT"] or 0)
            s.STR   = s.STR   + (st["ITEM_MOD_STRENGTH_SHORT"] or 0)
            s.SPI   = s.SPI   + (st["ITEM_MOD_SPIRIT_SHORT"] or 0)
            s.SP    = s.SP    + (st["ITEM_MOD_SPELL_POWER_SHORT"] or 0)
            s.AP    = s.AP    + (st["ITEM_MOD_ATTACK_POWER_SHORT"] or 0)
            s.CRIT  = s.CRIT  + (st["ITEM_MOD_CRIT_RATING_SHORT"] or 0)
            s.HASTE = s.HASTE + (st["ITEM_MOD_HASTE_RATING_SHORT"] or 0)
            s.MAST  = s.MAST  + (st["ITEM_MOD_MASTERY_RATING_SHORT"] or 0)
            s.HIT   = s.HIT   + (st["ITEM_MOD_HIT_RATING_SHORT"] or 0)
            s.EXP   = s.EXP   + (st["ITEM_MOD_EXPERTISE_RATING_SHORT"] or 0)
            s.DODGE = s.DODGE + (st["ITEM_MOD_DODGE_RATING_SHORT"] or 0)
            s.PARRY = s.PARRY + (st["ITEM_MOD_PARRY_RATING_SHORT"] or 0)
            s.PVP   = s.PVP   + (st["ITEM_MOD_PVP_POWER_SHORT"] or 0)
            s.RESIL = s.RESIL + (st["ITEM_MOD_RESILIENCE_RATING_SHORT"] or 0)
            s.ARMOR = s.ARMOR + (st["RESISTANCE0_NAME"] or 0)
            if GetItemGem then
                for g = 1, 3 do
                    local _, gl = GetItemGem(link, g)
                    local gs = gl and GetItemStats(gl)
                    if gs then
                        for k, sk in pairs({ITEM_MOD_STAMINA_SHORT="STA",ITEM_MOD_INTELLECT_SHORT="INT",ITEM_MOD_AGILITY_SHORT="AGI",ITEM_MOD_STRENGTH_SHORT="STR",ITEM_MOD_SPIRIT_SHORT="SPI",ITEM_MOD_CRIT_RATING_SHORT="CRIT",ITEM_MOD_HASTE_RATING_SHORT="HASTE",ITEM_MOD_MASTERY_RATING_SHORT="MAST",ITEM_MOD_HIT_RATING_SHORT="HIT",ITEM_MOD_EXPERTISE_RATING_SHORT="EXP",ITEM_MOD_DODGE_RATING_SHORT="DODGE",ITEM_MOD_PARRY_RATING_SHORT="PARRY",ITEM_MOD_PVP_POWER_SHORT="PVP",ITEM_MOD_RESILIENCE_RATING_SHORT="RESIL"}) do
                            s[sk] = s[sk] + (gs[k] or 0)
                        end
                    end
                end
            end
        end
    end
    AddExtras(s, lines)

    local statMult, staMult, critBonus, mastBonus, armorMult = 1.0, 1.0, 0.0, 0, 1.0
    local apMult, spMult, meleeHasteMult, spellHasteMult = 1.0, 1.0, 1.0, 1.0

    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellId = UnitBuff(unit, i)
        if not name then break end
        if spellId == 20217 or spellId == 1126 or spellId == 115921 then statMult = 1.05
        elseif spellId == 21562 or spellId == 469 or spellId == 109773 then staMult = 1.10
        elseif spellId == 1459 or spellId == 61316 or spellId == 17007 or spellId == 116781 or spellId == 24604 or spellId == 90309 then critBonus = 5.0
        elseif spellId == 19740 or spellId == 116956 then mastBonus = 3000
        elseif spellId == 6673 or spellId == 57330 or spellId == 19506 then apMult = 1.10
        elseif spellId == 1459 or spellId == 61316 or spellId == 77747 or spellId == 109773 then spMult = 1.10
        elseif spellId == 30809 or spellId == 55610 or spellId == 113742 then meleeHasteMult = 1.10
        elseif spellId == 24907 or spellId == 49868 or spellId == 15473 or spellId == 51470 then spellHasteMult = 1.05
        elseif spellId == 5487 then staMult = staMult * 1.40; armorMult = 2.20
        elseif spellId == 48263 then staMult = staMult * 1.25; armorMult = 1.55
        end
    end

    local hitBonus = 0
    if race == "Worgen" then critBonus = critBonus + 1.0 end
    if race == "Draenei" then hitBonus = hitBonus + 1.0 end
    if race == "Human" then s.SPI = math.floor(s.SPI * 1.03) end

    local specPrimMult = (armorOk ~= false and (UnitLevel(unit) or 0) >= 50) and 1.05 or 1.0

    s.STR = math.floor(s.STR * statMult * specPrimMult)
    s.AGI = math.floor(s.AGI * statMult * specPrimMult)
    s.INT = math.floor(s.INT * statMult * specPrimMult)
    s.STA = math.floor(s.STA * statMult * staMult)
    s.ARMOR = math.floor(s.ARMOR * armorMult)
    s.MAST = s.MAST + mastBonus

    local isSpell = (cat == "CASTER" or cat == "HEALER")
    local isStr = (class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT")

    local primCrit = isSpell and (s.INT / 2533) or (not isStr and (s.AGI / 2533) or 0)
    local critPct = 5.0 + (s.CRIT / 600) + primCrit + critBonus
    local baseHaste = s.HASTE / 425
    local hastePct = isSpell and (((1 + baseHaste / 100) * spellHasteMult - 1) * 100) or (((1 + baseHaste / 100) * meleeHasteMult - 1) * 100)
    local mastPct = ((UnitLevel(unit) or 0) >= 80) and ((8.0 + (s.MAST / 600)) * GetMasteryMult(specID)) or 0
    local spiToHit = (specID == 102 or specID == 258 or specID == 262) and s.SPI or 0
    local hitPct = (((isSpell and (s.HIT + spiToHit) or s.HIT)) / 340) + hitBonus
    local expPct = s.EXP / 340
    local pvpPct = s.PVP / 400
    local resilPct = s.RESIL / 400
    local estMp5 = math.floor(1126 + (s.SPI * 0.56))

    local rawAP = s.AP + (isStr and s.STR * 2 or s.AGI * 2)
    local rawSP = s.SP + s.INT

    return {
        cat = cat, specID = specID, hp = UnitHealthMax(unit) or 0, armor = s.ARMOR,
        str = s.STR, agi = s.AGI, sta = s.STA, int = s.INT, spi = s.SPI, mp5 = estMp5,
        ap = math.floor(rawAP * apMult), sp = math.floor(rawSP * spMult),
        crit = string.format("%.2f%%", critPct), haste = string.format("%.2f%%", hastePct),
        mast = string.format("%.2f%%", mastPct), hit = string.format("%.2f%%", hitPct),
        exp = string.format("%.2f%%", expPct),
        dodge = string.format("%.2f%%", 3.0 + (s.DODGE / 600) + (s.AGI / 2533)),
        parry = string.format("%.2f%%", 3.0 + (s.PARRY / 600) + (isStr and (s.STR / 951) or 0)),
        pvp = string.format("%.2f%%", pvpPct),
        resil = string.format("%.2f%%", resilPct),
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
        if hasBuff then
            hPct = (((1 + hPct / 100) / 1.05) - 1) * 100
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

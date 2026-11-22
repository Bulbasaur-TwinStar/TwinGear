local _, TG = ...
local PREFIX = "TwinGear"
local lastReq = {}
local suppressErrorUntil = 0

local function ShortName(name)
    return name and string.match(name, "^([^-]+)") or name
end

local function SystemMsgFilter(_, _, msg)
    if GetTime() < suppressErrorUntil then
        if string.find(msg, "not found") or string.find(msg, "nenalezen") or string.find(msg, "is not playing") then
            return true
        end
    end
    return false
end

local function SerializeData(d)
    if not d or not d.stats then return nil end
    local s = d.stats
    local stStr = table.concat({
        s.cat or "MELEE", s.hp or 0, s.str or 0, s.agi or 0, s.sta or 0, s.int or 0, s.spi or 0,
        s.ap or 0, s.sp or 0, s.crit or "0%", s.haste or "0%", s.mast or "0%",
        s.hit or "0%", s.exp or "0%", s.dodge or "0%", s.parry or "0%", s.armor or 0,
        s.pvp or "0%", s.mp5 or 0, s.resil or "0%"
    }, ",")

    local raids = TG:GetMyRaids()
    local rParts = {}
    for _, r in ipairs(raids) do
        table.insert(rParts, r.clr .. ":" .. r.hc .. ":" .. r.lfr .. ":" .. r.flx .. ":" .. r.norm)
    end
    local cmStr, cmList = TG:GetMyChallengeMode()
    cmStr = string.gsub(string.gsub(cmStr or "", "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
    local cmTiers = {}
    for _, item in ipairs(cmList or {}) do table.insert(cmTiers, tostring(item.tier or 0)) end

    local profs = TG:GetMyProfessions()
    local pParts = {}
    for _, p in ipairs(profs) do
        table.insert(pParts, p.name .. ":" .. p.rank .. "/" .. p.max)
    end

    return "DATA2|" .. stStr .. "|" .. table.concat(rParts, ";") .. "|" .. cmStr .. "|" .. table.concat(cmTiers, ",") .. "|" .. table.concat(pParts, ";")
end

local function DeserializeAndApply(sender, payload)
    local stStr, rStr, cmStr, cmTierStr, pStr = string.match(payload, "^DATA2|([^|]+)|([^|]+)|([^|]+)|([^|]*)|?(.*)$")
    if not stStr then return end

    local v = { strsplit(",", stStr) }
    if #v < 18 then return end

    local stats = {
        cat = v[1], hp = tonumber(v[2]) or 0, str = tonumber(v[3]) or 0, agi = tonumber(v[4]) or 0,
        sta = tonumber(v[5]) or 0, int = tonumber(v[6]) or 0, spi = tonumber(v[7]) or 0,
        ap = tonumber(v[8]) or 0, sp = tonumber(v[9]) or 0, crit = v[10], haste = v[11],
        mast = v[12], hit = v[13], exp = v[14], dodge = v[15], parry = v[16],
        armor = tonumber(v[17]) or 0, pvp = v[18], mp5 = tonumber(v[19]) or 0, resil = v[20] or "0%"
    }

    local rNames = { "Siege of Orgrimmar", "Throne of Thunder", "Terrace of Endless Spring", "Heart of Fear", "Mogu'shan Vaults" }
    local rTotals = { 14, 12, 4, 6, 6 }
    local raids = {}
    local idx = 1
    for pair in string.gmatch(rStr, "[^;]+") do
        local c, h, lfr, flx, norm = string.match(pair, "(%d+):(%d+):(%d+):(%d+):(%d+)")
        if c and h and rNames[idx] then
            table.insert(raids, {
                name = rNames[idx], clr = tonumber(c), hc = tonumber(h), total = rTotals[idx],
                lfr = tonumber(lfr) or 0, flx = tonumber(flx) or 0, norm = tonumber(norm) or 0,
                hasFlex = (idx == 1)
            })
            idx = idx + 1
        end
    end

    local shortSender = ShortName(sender)
    local targetKey = TG.Cache[sender] and sender or (TG.Cache[shortSender] and shortSender or sender)
    local cached = TG.Cache[targetKey] or { name = targetKey, time = GetTime(), ilvl = 0, items = {}, cloak = "None", guild = "No Guild", spec = "", upgCur = 0, upgMax = 0, missGems = 0, missEnch = 0, pvp = 0 }

    cached.stats = stats
    cached.isSynced = true
    if #raids == 5 then cached.syncedRaids = raids end
    cached.syncedCM = cmStr
    if cmTierStr and cmTierStr ~= "" then
        local dNames = {
            "Temple of the Jade Serpent", "Stormstout Brewery", "Gate of the Setting Sun",
            "Shado-Pan Monastery", "Siege of Niuzao Temple", "Mogu'shan Palace",
            "Scholomance", "Scarlet Halls", "Scarlet Monastery"
        }
        local list = {}
        local i = 1
        for t in string.gmatch(cmTierStr, "(%d+)") do
            if dNames[i] then table.insert(list, { name = dNames[i], tier = tonumber(t) or 0 }); i = i + 1 end
        end
        if #list == 9 then cached.syncedCMList = list end
    end

    if pStr and pStr ~= "" then
        local sProfs = {}
        for item in string.gmatch(pStr, "[^;]+") do
            local pName, pSkill = string.match(item, "([^:]+):(.+)")
            if pName and pSkill then
                table.insert(sProfs, { name = pName, skill = pSkill })
            end
        end
        cached.syncedProfs = sProfs
    end

    TG.Cache[targetKey] = cached

    if TG.Frame and TG.Frame:IsShown() and TG.CurrentData and TG.CurrentData.name == targetKey then
        TG:UpdateUI(cached)
    end
end

function TG:RequestSyncData(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
    local name = GetUnitName(unit, true)
    if not name or (GetTime() - (lastReq[name] or 0)) < 15 then return end
    lastReq[name] = GetTime()

    if UnitInRaid(unit) then
        SendAddonMessage(PREFIX, "REQ:" .. ShortName(name), "RAID")
    elseif UnitInParty(unit) then
        SendAddonMessage(PREFIX, "REQ:" .. ShortName(name), "PARTY")
    elseif UnitFactionGroup(unit) == UnitFactionGroup("player") then
        suppressErrorUntil = GetTime() + 1.5
        SendAddonMessage(PREFIX, "REQ", "WHISPER", name)
        SendAddonMessage("TWINGEAR", "VER|" .. (GetAddOnMetadata("TwinGear", "Version") or "2.2.3"), "WHISPER", name)
    end
end

function TG:InitSync()
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(PREFIX) end
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix("TWINGEAR") end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMsgFilter)

    local sf = CreateFrame("Frame")
    sf:RegisterEvent("CHAT_MSG_ADDON")
    sf:SetScript("OnEvent", function(_, _, prefix, msg, channel, sender)
        if prefix ~= PREFIX then return end
        local me = GetUnitName("player", true)
        local myShort = UnitName("player")
        if sender == me or ShortName(sender) == myShort then return end

        if msg == "REQ" or msg == "REQ:" .. myShort or msg == "REQ:" .. me then
            TG:ScanUnit("player", false)
            local payload = SerializeData(TG.Cache[me])
            if payload then
                if channel == "RAID" or channel == "PARTY" or channel == "GUILD" then
                    SendAddonMessage(PREFIX, payload, channel)
                else
                    suppressErrorUntil = GetTime() + 1.5
                    SendAddonMessage(PREFIX, payload, "WHISPER", sender)
                end
            end
        elseif string.find(msg, "^DATA2|") then
            DeserializeAndApply(sender, msg)
        end
    end)
end

local MY_VER = GetAddOnMetadata("TwinGear", "Version") or "2.2.3"
local verNotified = false
local lastVerBroadcast = 0

local function ParseVer(v)
    local a, b, c = string.match(tostring(v or ""), "(%d+)%.(%d+)%.?(%d*)")
    return (tonumber(a) or 0) * 10000 + (tonumber(b) or 0) * 100 + (tonumber(c) or 0)
end

local function CheckRemoteVer(remoteVer)
    if verNotified or not remoteVer then return end
    if ParseVer(remoteVer) > ParseVer(MY_VER) then
        verNotified = true
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[TwinGear]|r New version |cff00ff00v" .. remoteVer .. "|r is available! Download at: |cff33aaffhttps://github.com/" .. "Bulbasaur-TwinStar/TwinGear|r")
    end
end

local verFrame = CreateFrame("Frame")
verFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
verFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
verFrame:RegisterEvent("CHAT_MSG_ADDON")
verFrame:SetScript("OnEvent", function(_, event, prefix, msg)
    if event == "CHAT_MSG_ADDON" and prefix == "TWINGEAR" and msg then
        local rv = string.match(msg, "^VER|([%d%.]+)")
        if rv then CheckRemoteVer(rv) end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        if (GetTime() - lastVerBroadcast) < 10 then return end
        lastVerBroadcast = GetTime()
        if IsInGuild() then SendAddonMessage("TWINGEAR", "VER|" .. MY_VER, "GUILD") end
        if IsInRaid() then SendAddonMessage("TWINGEAR", "VER|" .. MY_VER, "RAID")
        elseif IsInGroup() then SendAddonMessage("TWINGEAR", "VER|" .. MY_VER, "PARTY") end
    end
end)

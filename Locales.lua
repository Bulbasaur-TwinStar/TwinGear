local _, TG = ...

TG.Locales = {
    enUS = {
        TITLE = "TwinGear 2.2.2", SUBTITLE = "For TwinStar Helios & Persés",
        TAB_SUMMARY = "Summary", TAB_EQUIP = "Equipment", TAB_GROUP = "Group Scan", TAB_ALTS = "Alts & MoP",
        BTN_LINK = "Link", BTN_RESCAN = "Re-Scan", BTN_HISTORY = "History",
        BTN_SCAN_GRP = "Scan Group", BTN_REPORT = "Report to Chat",
        SEC_AUDIT = "Equipment Audit", SEC_RAIDS = "MoP Raiding Progression", SEC_BUFFS = "Target Buffs & Consumables",
        AUD_ILVL = "Equipped iLvl:", AUD_CLOAK = "Legendary Cloak:", AUD_SETS = "Tier Sets (T14-T16):",
        AUD_UPG = "Upgraded / Ref:", AUD_GEMS = "Gems / Ench:", AUD_PVP = "PvP Gear:", AUD_PROFS = "Professions:",
        CM_TITLE = "Challenge Mode:", OK = "OK", NONE = "None",
        CURR_TITLE = "Currencies & Secondary Professions", WB_TITLE = "Weekly World Bosses:",
        ALT_HINT = "Account Characters (Sorted by iLvl):", LANG_NAME = "EN",
        CAT_TANK = "Tank Stats", CAT_HEAL = "Healer Stats", CAT_CAST = "Spell Stats", CAT_RANG = "Ranged Stats", CAT_MELEE = "Melee Stats",
        EXACT = "(Exact)", EST = "(Est.)",
        STAT_HP = "Health:", STAT_STR = "Strength:", STAT_AGI = "Agility:", STAT_STA = "Stamina:",
        STAT_INT = "Intellect:", STAT_SPI = "Spirit:", STAT_AP = "Attack Power:", STAT_RAP = "Ranged AP:",
        STAT_SP = "Spell Power:", STAT_CRIT = "Crit:", STAT_HASTE = "Haste:", STAT_MAST = "Mastery:",
        STAT_HIT = "Hit:", STAT_EXP = "Expertise:", STAT_DODGE = "Dodge:", STAT_PARRY = "Parry:",
        STAT_ARMOR = "Armor:", STAT_REGEN = "Combat Regen:", STAT_PVP = "PvP Power:", STAT_RESIL = "PvP Resilience:",
        BUFF_FLASK = "Flask:", BUFF_FOOD = "Well Fed (Food):", BUFF_STATS = "5% Stats Buff:",
        BUFF_STA = "10% Stamina:", BUFF_CRIT = "5% Crit Buff:", ACTIVE = "Active", MISSING = "Missing", YES = "Yes", NO = "No",
        HINT_GRP = "Supports up to 40 players (Use mouse wheel to scroll)",
        HINT_ALTS = "Supports up to 50 account alts (Use mouse wheel to scroll)",
        WB_OPEN = "Open", WB_KILLED = "Killed", WB_DONE = "Done", WB_UNLOCKED = "Unlocked", WB_NOCLOAK = "No Cloak", EMPTY = "Empty"
    }
}

function TG:L(k)
    return TG.Locales.enUS[k] or k
end

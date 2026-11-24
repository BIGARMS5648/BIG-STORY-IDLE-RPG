#!/bin/sh
# Fails when addon code reads or writes a global that is neither Lua 5.1 / WoW API nor an allowed
# addon global (the headless WoW stub answers unknown names, so tests alone cannot catch these).
ALLOWED="pairs ipairs type tostring tonumber math string table select next unpack pcall error assert
setmetatable getmetatable rawget rawset print _G coroutine xpcall loadstring bit date time os debug tinsert tremove wipe
CreateFrame C_Item C_Spell C_Timer C_ChatInfo UnitName UnitSex UnitRace UnitClass GetTime GetItemIcon
Minimap DAMAGE_TEXT_FONT IsShiftKeyDown GameTooltip DEFAULT_CHAT_FRAME UIErrorsFrame SlashCmdList SendAddonMessage
RegisterAddonMessagePrefix JoinTemporaryChannel JoinChannelByName IsInRaid IsInGuild IsInGroup GetSpellInfo
GetServerTime GetRealmName GetNumRaidMembers GetNumPartyMembers GetChannelName ChatFrame_RemoveChannel
BackdropTemplateMixin UISpecialFrames UIParent StaticPopup_Show StaticPopupDialogs RAID_CLASS_COLORS
GetCursorPosition CUSTOM_CLASS_COLORS BigStoryIdleDB SLASH_BIGSTORYIDLE1 SLASH_BIGSTORYIDLE2 SLASH_BSI1 SLASH_BSI2"
bad=0
for f in $(find BigStoryIdleRPG -name '*.lua' ! -path '*/Data/*'); do
    for g in $(luac5.1 -l -p "$f" | grep -oE '(GET|SET)GLOBAL.*; [A-Za-z_][A-Za-z0-9_]*$' | awk '{print $NF}' | sort -u); do
        case " $(echo $ALLOWED) " in *" $g "*) ;; *) echo "unknown global '$g' in $f"; bad=1 ;; esac
    done
done
[ $bad -eq 0 ] && echo "globals ok" || exit 1

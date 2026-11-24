-- Base character stats (Lv1 stat window, KR screenshot; see Data/MapleRank.lua).
-- Character level does not raise base stats directly: every level-up gives 5 메이플 등급
-- points (Systems/MapleRank.lua), and level raises skill levels.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

D.BaseStats = {}

function D.BaseStats.Apply(hero, acc, job)
    for stat, v in pairs(D.BaseCharacter) do
        if v ~= 0 then acc:Add(stat, v) end
    end
end

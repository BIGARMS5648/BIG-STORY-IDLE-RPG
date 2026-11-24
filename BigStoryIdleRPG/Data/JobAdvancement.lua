-- 전직 시험 (Job Advancement Test): client 1.18.0 JobStepDungeon rows (maplestoryidle.info
-- target-context-model.json, chapterIndex 2000 + job index, dungeonIndex 1/2/3 = 2차/3차/4차).
-- Global wiki: "2nd Job Advancement Test at Level 30, the 3rd at Level 60, and the 4th at Level 100.
-- After Job Advancement, the class gets to unlock a new set of unique skills."
--
--   2차: ItemDropCount ["29","30"] in 180 s (item 29 x 30; Cygnus: item 60 x 30); 2 mob types,
--        HP 16,000 · ATK 300 · DEF 1,000 · avoid 22
--   3차: KillBoss 1 in 45 s - the job instructor's clone, HP 2억 · ATK 3,500 · DEF 1,000 · avoid 75
--   4차: KillBoss 2 in 120 s - 그리페 + 마뇽, HP 13조 each · ATK 150만 · DEF 1,000 · avoid 170
--        (Cygnus: 엘리노어 alone, HP 26조)
-- Jobs 15-16 have no rows in the dump; they use the Cygnus rows of 13-14.
-- Each mob row has spawnCount 1 (one of each alive, respawning) and RunSpeedMms 1,500.
-- ESTIMATE: every kill in the 2차 test drops one item (the drop rate is not in the dump).
-- Skin (WoW): monsters are taken from the WoW creatures already used by the chapter skins.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

local function mob(npcId, displayId, nameKo) return { npcId = npcId, displayId = displayId, nameKo = nameKo } end

-- WoW looks for the Maple test monsters
local M = {
    fireBoar = mob(157, 3027, "뿔엄니멧돼지"),            -- Fire Boar
    lupin = mob(1108, 843, "안개계곡고릴라"),              -- Lupin
    curseEye = mob(11480, 14253, "불가사의한 피조물"),      -- Curse Eye
    hornyMushroom = mob(5228, 682, "축축한 수액괴물"),      -- Horny Mushroom
    evilEye = mob(6427, 4629, "절규하는 환영"),            -- Evil Eye
    zombieMushroom = mob(1501, 10973, "넋 나간 좀비"),      -- Zombie Mushroom
    blueMushroom = mob(2656, 11137, "비취 수액괴물"),       -- Blue Mushroom
    coldEye = mob(7448, 10810, "서리바람 키메라"),          -- Cold Eye
    octoPirate = mob(1563, 796, "붉은해적단 칼잡이"),       -- OctoPirate
    tiguru = mob(11361, 11031, "줄리안 호랑이"),            -- Tiguru
    -- 3차: instructor clones
    warriorClone = mob(4302, 2460, "전사 교관의 분신"),     -- Dances with Balrog's Clone
    mageClone = mob(1867, 3767, "마법 교관의 분신"),        -- Grendel the Really Old's Clone
    archerClone = mob(4094, 9411, "사냥꾼 교관의 분신"),    -- Athena Pierce's Clone
    thiefClone = mob(2240, 3706, "도적 교관의 분신"),       -- Dark Lord's Clone
    pirateClone = mob(657, 2347, "해적 교관의 분신"),       -- Kyrin's Clone
    baroq = mob(3725, 4255, "암흑이교도 제사장"),           -- Baroq
    -- 4차
    griffey = mob(5300, 3210, "공작날개 히포그리프"),       -- Griffey
    manon = mob(12260, 6369, "오닉시아의 비룡"),           -- Manon
    eleanor = mob(5930, 10875, "마녀 리벤"),               -- Eleanor
}

local function tests(m1, m2, clone, item, cygnus)
    return {
        [2] = { kind = "collect", timeSec = 180, item = item, need = 30, alive = m2 and 2 or 1,
                mobs = { { look = m1, hp = 16000, atk = 300, def = 1000, avoid = 22, speed = 1500 },
                         m2 and { look = m2, hp = 16000, atk = 300, def = 1000, avoid = 22, speed = 1500 } or nil } },
        [3] = { kind = "boss", timeSec = 45,
                bosses = { { look = clone, hp = 200000000, atk = 3500, def = 1000, avoid = 75 } } },
        [4] = { kind = "boss", timeSec = 120,
                bosses = cygnus and { { look = M.eleanor, hp = 26000000000000, atk = 1500000, def = 1000, avoid = 170 } }
                    or { { look = M.griffey, hp = 13000000000000, atk = 1500000, def = 1000, avoid = 170 },
                         { look = M.manon, hp = 13000000000000, atk = 1500000, def = 1000, avoid = 170 } } },
    }
end

local WARRIOR = tests(M.fireBoar, M.lupin, M.warriorClone, "어둠의 구슬")
local MAGE = tests(M.curseEye, M.hornyMushroom, M.mageClone, "어둠의 구슬")
local ARCHER = tests(M.evilEye, M.zombieMushroom, M.archerClone, "어둠의 구슬")
local THIEF = tests(M.blueMushroom, M.coldEye, M.thiefClone, "어둠의 구슬")
local PIRATE = tests(M.octoPirate, nil, M.pirateClone, "어둠의 구슬")
local CYGNUS = tests(M.tiguru, nil, M.baroq, "검은 날개의 증표", true)

D.JobAdvancement = {
    levels = { [2] = 30, [3] = 60, [4] = 100 },
    stepNames = { [1] = "1차", [2] = "2차", [3] = "3차", [4] = "4차" },
    -- by job index (D.Jobs[].index)
    byJob = {
        [1] = WARRIOR, [2] = WARRIOR, [3] = WARRIOR,
        [4] = MAGE, [5] = MAGE, [6] = MAGE,
        [7] = ARCHER, [8] = ARCHER,
        [9] = THIEF, [10] = THIEF,
        [11] = PIRATE, [12] = PIRATE,
        [13] = CYGNUS, [14] = CYGNUS, [15] = CYGNUS, [16] = CYGNUS,
    },
}

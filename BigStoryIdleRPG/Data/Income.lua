-- Free income sources (research/spec/research-income.md, KR unless noted).
-- Paid tracks / hot deals / memberships are removed; ad rewards become free daily claims.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

-- 데일리 배틀 패스, free track: kills today -> red diamonds (1,500 a day)
D.DailyPass = {
    { kills = 500, redDia = 100 }, { kills = 1000, redDia = 100 }, { kills = 1500, redDia = 100 },
    { kills = 2200, redDia = 100 }, { kills = 2900, redDia = 100 }, { kills = 3600, redDia = 100 },
    { kills = 4300, redDia = 100 }, { kills = 5000, redDia = 800 },
}

-- 월간 출석 (unlock: chapter 3-2 cleared; a day is claimable after the daily-mission 8/8 clear;
-- resets on the 1st, unclaimed days are lost)
D.Attendance = {
    unlock = { ch = 3, st = 2 },
    days = {
        { "weaponTicket", 100 }, { "companionTicket", 40 }, { "expDungeonKey", 3 }, { "spellTrace", 2000 },
        { "burningBooster", 2 }, { "eliteSummonPoint", 1000 }, { "honorMedal", 20000 }, { "weaponTicket", 150 },
        { "companionTicket", 60 }, { "explorationTicket", 3 }, { "spellTrace", 3000 }, { "burningBooster", 3 },
        { "eliteSummonPoint", 1500 }, { "cubeMiracle", 30 }, { "weaponTicket", 200 }, { "companionTicket", 80 },
        { "bossRaidTicket", 3 }, { "spellTrace", 4000 }, { "burningBooster", 4 }, { "eliteSummonPoint", 2000 },
        { "starforceScroll", 60 }, { "weaponTicket", 300 }, { "companionTicket", 120 }, { "memorialScroll", 20 },
        { "starforceScroll", 10 }, { "cubeMiracle", 5 }, { "artifactChest", 4 }, { "legendaryArtifactSummon", 1 },
    },
}

-- 일일 미션 clear reward (8 missions): known exactly
D.DailyMissionClear = { need = 8, rewards = { weaponTicket = 100, redDia = 5000 } }
-- PROVISIONAL: the individual daily missions are not published. Placeholder list whose
-- rewards sum to the community total (7,400 - 5,000 = 2,400 red diamonds a day).
-- Will be replaced by the researched list.
D.DailyMissions = {
    { id = "kill", text = "몬스터 %d마리 처치", track = "kill", goal = 1000, rewards = { redDia = 300 } },
    { id = "weaponSummon", text = "무기 소환 %d회", track = "summon_weapon", goal = 10, rewards = { redDia = 300 } },
    { id = "companionSummon", text = "동료 소환 %d회", track = "summon_companion", goal = 10, rewards = { redDia = 300 } },
    { id = "dungeon", text = "성장 던전 %d회 클리어", track = "dungeon", goal = 3, rewards = { redDia = 300 } },
    { id = "elite", text = "엘리트 몬스터 소환 %d회", track = "elite", goal = 10, rewards = { redDia = 300 } },
    { id = "arena", text = "결투장 %d회 참여", track = "arena", goal = 3, rewards = { redDia = 300 } },
    { id = "worldBoss", text = "월드 보스 %d회 도전", track = "worldboss", goal = 1, rewards = { redDia = 300 } },
    { id = "quickHunt", text = "빠른 사냥 %d회", track = "quickhunt", goal = 1, rewards = { redDia = 300 } },
}
-- 주간 미션: weekly gauge filled by daily missions; total 15,500 red diamonds a week and a
-- 500 weapon-ticket stage are known. PROVISIONAL split into 5 stages.
D.WeeklyMission = {
    perDailyMission = 1,
    stages = {
        { need = 10, rewards = { redDia = 2500 } },
        { need = 20, rewards = { redDia = 3000 } },
        { need = 30, rewards = { redDia = 3000, weaponTicket = 500 } },
        { need = 40, rewards = { redDia = 3500 } },
        { need = 50, rewards = { redDia = 3500 } },
    },
}

-- ad rewards -> one free claim a day each
D.FreeDaily = {
    { id = "dia", text = "레드 다이아 1,000", rewards = { redDia = 1000 } },
    { id = "weaponSummon", text = "무료 무기 소환 10회", summon = "weapon", count = 10 },
    { id = "companionSummon", text = "무료 동료 소환 10회", summon = "companion", count = 10 },
    { id = "booster", text = "부스터 (경험치 +100%, 골드 +150%, 20분)", booster = { seconds = 1200, exp = 1000, gold = 1500 } },
    -- 30-minute speed-up x3 for mastery / elite level-up -> time-skip tickets
    { id = "speedup", text = "학습·강화 가속 30분 ×3", rewards = { timeSkip1m = 90 } },
}

-- weekly red-diamond shop (KR 1.18.0 rows that cost red diamonds)
D.RedShop = {
    { name = "명예의 훈장 1,000개", price = 1500, limit = 5, items = { honorMedal = 1000 } },
    { name = "챕터 돌파 선물", price = 100, limit = 1, once = true, unlock = { 4, 10 }, items = { meso = 50000, spellTrace = 1500, redDia = 1000 } },
    { name = "무기 소환권 100개", price = 1000, limit = 1, unlock = { 5, 10 }, items = { weaponTicket = 100 } },
    { name = "동료 소환권 30개", price = 750, limit = 1, unlock = { 6, 10 }, items = { companionTicket = 30 } },
    { name = "주문의 흔적 1,000개", price = 1000, limit = 1, unlock = { 7, 10 }, items = { spellTrace = 1000 } },
    { name = "스타포스 강화 주문서 5개", price = 1500, limit = 3, items = { starforceScroll = 5 } },
    { name = "미라클 큐브 1개", price = 1000, limit = 5, items = { cubeMiracle = 1 } },
    { name = "유물 상자", price = 1500, limit = 5, items = { artifactChest = 1 } },
    { name = "유물 성장 지원", price = 7500, limit = 1, once = true, items = { artifactChest = 5, artifactStone = 15000 } },
    { name = "에디셔널 큐브 1개", price = 1500, limit = 3, items = { cubeAdditional = 1 } },
    { name = "300,000 골드", price = 1500, limit = nil, unlock = { 8, 10 }, items = { meso = 300000 } },
    { name = "여정의 기운 1개", price = 1000, limit = 5, unlock = { 20, 10 }, items = { journeyEnergy = 1 } },
}

-- 14일 특별 미션 (newcomer): 10 weapon tickets per mission + a daily all-clear reward;
-- 79 missions -> a unique companion. Conditions are parsed by Systems/Income.lua.
D.Newcomer14 = {
    perMission = { weaponTicket = 10 },
    finalAt = 79,
    days = {
        { m = { "kill:4000", "level:30", "elite:7", "summonLv_weapon:4", "free:펫 산책로 방문하기" }, clear = { weaponTicket = 150 } },
        { m = { "kill:10000", "dungeon_weapon:15", "summonLv_companion:3", "ability:2", "worldboss:4" }, clear = { companionTicket = 60 } },
        { m = { "kill:10000", "dungeon_gear:15", "enchant:5", "summonLv_weapon:8", "chapterBoss:6" }, clear = { spellTrace = 1500 } },
        { m = { "free:파티 퀘스트 반지 장착", "star:3", "dungeon_weapon:22", "dungeon_exp:20", "worldboss:5" }, clear = { starforceScroll = 6 } },
        { m = { "free:길드원에게 도움 요청", "arena:5", "summonLv_weapon:9", "summonLv_companion:4", "chapterBoss:8" }, clear = { eliteSummonPoint = 2000 } },
        { m = { "kill:10000", "dungeon_gear:20", "dungeon_enhance:18", "elite:15", "heroPower:3" }, clear = { honorMedal = 2500 } },
        { m = { "kill:10000", "worldboss:6", "free:길드 토벌전 참여", "potential:3", "chapterBoss:9" }, clear = { cubeMiracle = 3 } },
        { m = { "kill:10000", "level:60", "elite:16", "summonLv_weapon:10", "summonLv_companion:5" }, clear = { weaponTicket = 250 } },
        { m = { "dungeon_weapon:30", "dungeon_exp:25", "ability:3", "enchant:10", "worldboss:7" }, clear = { companionTicket = 80 } },
        { m = { "kill:20000", "dungeon_gear:30", "dungeon_enhance:25", "star:7", "arenaTier:4" }, clear = { spellTrace = 2500 } },
        { m = { "kill:10000", "potentialGrade:2", "dungeon_weapon:35", "dungeon_exp:30", "free:MP 물약 6단계" }, clear = { starforceScroll = 10 } },
        { m = { "free:길드 토벌전 1,000만점", "arenaTier:5", "summonLv_weapon:12", "ability:4", "summonLv_companion:6" }, clear = { eliteSummonPoint = 2500 } },
        { m = { "free:길드 토벌전 1,500만점", "potentialGrade:3", "companionGrade:3", "heroPower:4", "elite:20" }, clear = { honorMedal = 3000 } },
        { m = { "kill:20000", "dungeon_gear:33", "arenaTier:6", "worldboss:8", "star:10" }, clear = { cubeMiracle = 5 } },
    },
}

-- 특별 의뢰 (Special Requests): one-time town quests (global wiki "Quests" + KR, research-income §3.9).
-- A request opens at its gate (chapter-stage reached / level / guide quest number); counted goals
-- (kills, summons, scrolls ...) count from the moment the request opens, state goals (level, summon
-- level, chapter boss, world boss stage) are checked directly.
-- ADAPTED: the original has guide-quest gates (GQ 48/56/59/147); the guide quest chain is not
-- published, so those requests open from the start (GQ 147 at chapter 5).
-- ADAPTED: "Cloy's Costume Proposal" (check costumes) and "Mrs. Ming Ming's Request 2" (check Royal
-- Style) point at paid style shops, which are removed; they ask to look at the 장비 / 훈장 windows.
-- Not included: 펫 산책로 jump quests and minigame quests (no such content).
-- NPC names are the WoW-skin quest givers; `maple` is the original NPC / quest.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

D.SpecialRequests = {
    { id = "henesysBoss", npc = "보안관 마셜 듀간", maple = "2. 헤네시스 - 보스", text = "2챕터 보스 처치",
      goal = { "chapterBoss", 2 }, rewards = { exp = 400000, weaponTicket = 50 } },
    { id = "eliteX5", npc = "대장장이 아르겐트", maple = "엘리트 몬스터 5회 소환", text = "엘리트 몬스터 5회 소환",
      goal = { "count", "elite", 5 }, rewards = { exp = 130000, redDia = 600 }, gear = { code = "GEAR_10_1_BELT", level = 15 } },
    { id = "worldBoss1", npc = "사령관 아모스", maple = "월드 보스 1단계 클리어", text = "월드 보스 1단계 클리어",
      goal = { "worldBoss", 1 }, rewards = { exp = 1000000, weaponStone = 50000, redDia = 1000 } },
    { id = "level60", npc = "왕실 연대기 학자", maple = "Lv.60 달성", text = "60 레벨 달성", gate = { level = 58 },
      goal = { "level", 60 }, rewards = { redDia = 10000 } },
    { id = "stan1", npc = "보안관 그리안 스톰윈드", maple = "스탄 촌장의 부탁", text = "몬스터 1,000마리 처치", gate = { ch = 3, st = 3 },
      goal = { "count", "kill", 1000 }, rewards = { weaponTicket = 30 } },
    { id = "cassandra1", npc = "점술가 마담 에바", maple = "카산드라의 수정구 1", text = "무기 소환 10회", gate = { ch = 3, st = 3 },
      goal = { "count", "summon_weapon", 10 }, rewards = { weaponTicket = 20 } },
    { id = "mingming1", npc = "여관주인 파렐리", maple = "밍밍 부인의 부탁", text = "동료 소환 레벨 3 달성", gate = { ch = 4, st = 1 },
      goal = { "summonLevel", "companion", 3 }, rewards = { companionTicket = 30 } },
    { id = "cloy", npc = "재단사 루시", maple = "클로이의 코스튬 제안", text = "장비 창 확인하기", gate = { ch = 4, st = 7 },
      goal = { "visit", "equipment" }, rewards = { eliteSummonPoint = 100 } },
    { id = "bruce1", npc = "마법사 지니 깃파이어", maple = "브루스의 주문서 연구 1", text = "주문서 3회 사용", gate = { ch = 5, st = 1 },
      goal = { "count", "scroll", 3 }, rewards = { spellTrace = 750 } },
    { id = "useScroll", npc = "마법사 지니 깃파이어", maple = "주문서 사용하기", text = "주문서 1회 사용", gate = { ch = 5, st = 1 },
      goal = { "count", "scroll", 1 }, rewards = { scrollNormal = 2 } },
    { id = "camilaParty", npc = "음유시인 켈란", maple = "카밀라의 생일 파티", text = "동료 소환 30회", gate = { ch = 6, st = 1 },
      goal = { "count", "summon_companion", 30 }, rewards = { spellTrace = 300 } },
    { id = "cassandra2", npc = "점술가 마담 에바", maple = "카산드라의 수정구 2", text = "무기 소환 100회", gate = { ch = 6, st = 1 },
      goal = { "count", "summon_weapon", 100 }, rewards = { weaponTicket = 30 } },
    { id = "bruce2", npc = "마법사 지니 깃파이어", maple = "브루스의 주문서 연구 2", text = "주문서 5회 사용", gate = { ch = 7, st = 1 },
      goal = { "count", "scroll", 5 }, rewards = { spellTrace = 300 } },
    { id = "camilaStar1", npc = "음유시인 켈란", maple = "카밀라의 반짝이는 별 1", text = "스타포스 강화 3회", gate = { ch = 7, st = 1 },
      goal = { "count", "starforce", 3 }, rewards = { starforceScroll = 2 } },
    { id = "mingming2", npc = "여관주인 파렐리", maple = "밍밍 부인의 부탁 2", text = "훈장 창 확인하기", gate = { ch = 7, st = 1 },
      goal = { "visit", "medals" }, rewards = { starforceScroll = 2 } },
    { id = "cloyPq", npc = "재단사 루시", maple = "클로이의 연구 자료", text = "첫 번째 동행 클리어", gate = { ch = 7, st = 5 },
      goal = { "count", "pq_first", 1 }, rewards = { spellTrace = 300 } },
    { id = "bruce3", npc = "마법사 지니 깃파이어", maple = "브루스의 주문서 연구 3", text = "주문서 7회 사용", gate = { ch = 8, st = 1 },
      goal = { "count", "scroll", 7 }, rewards = { spellTrace = 300 } },
    { id = "cassandra3", npc = "점술가 마담 에바", maple = "카산드라의 수정구 3", text = "동료 소환 100회", gate = { ch = 8, st = 1 },
      goal = { "count", "summon_companion", 100 }, rewards = { starforceScroll = 3 } },
    { id = "bruceAbility", npc = "마법사 지니 깃파이어", maple = "브루스의 어빌리티 연구", text = "어빌리티 변환 100회", gate = { ch = 8, st = 1 },
      goal = { "count", "ability", 100 }, rewards = { spellTrace = 500 } },
    { id = "camilaStar2", npc = "음유시인 켈란", maple = "카밀라의 반짝이는 별 2", text = "스타포스 강화 3회", gate = { ch = 9, st = 5 },
      goal = { "count", "starforce", 3 }, rewards = { starforceScroll = 2 } },
    { id = "stan2", npc = "보안관 그리안 스톰윈드", maple = "스탄 촌장의 부탁 2", text = "잠재능력 재설정 3회", gate = { ch = 9, st = 5 },
      goal = { "count", "potential", 3 }, rewards = { cubeMiracle = 3 } },
    { id = "casey", npc = "탐험가 협회 브란 브론즈비어드", maple = "케이시의 제안", text = "무기 소환 1회", gate = { ch = 10, st = 1 },
      goal = { "count", "summon_weapon", 1 }, rewards = { spellTrace = 500 } },
}

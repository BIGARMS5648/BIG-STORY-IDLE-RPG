-- 훈장 (Medals): 보유 효과 apply once a medal is obtained (claimed); one medal can be worn and is
-- shown under the name. Main Stat from medals is capped at 1,500.
-- Sources:
--   global wiki "Medals" (growth / battle / boss / other lists, Main Stat +30 each, cap 1,500)
--   KR 9/22 patch notes: 20 new medals (유물의 대가, 미스틱의 경지·정점·완성·극의, 소환의 명장, 소울메이트,
--     특별한·찬란한·완성된 여정, 어린양의 수호자, 쾌속 항해·비행, 무적의 나, 전설의 나, 125층·150층 용사, 인기도 3종)
--   KR star force rework: 23/24/25★ medals became 24/26/28★, new 기적 27★, 지존 29★, ★★★ 30★,
--     핑크빈 헌터 (핑크빈 어려움 5회, 보스 몬스터 데미지 10%); later 혼테일 파괴자
--   KR notices: 오르비스 방범대 (여신의 흔적 50회), 마가티아 평화주의자 (로미오와 줄리엣 50회),
--     핑크빈 슬레이어 (길드 레이드 핑크빈, 최종 데미지 +3%), 팀 플레이어 (길드 레이드 자쿰, 최종 데미지 +3%)
-- Not included: costume / royal hair / royal face medals (paid styles), 인기도 (fame), pet walkway,
--   event and ranking medals.
-- ADAPTED: guild raid medals are earned by the top difficulty of the boss raid (guild content was
--   removed, see Systems/RelocatedRewards.lua); "도전 모드 MVP" raid medals count party-mode raid clears.
-- ESTIMATE: 혼테일 파괴자 condition / effect (KR notice names it only) = 카오스 5회, 보스 몬스터 데미지 10%.
-- Names: `name` is the WoW-skin title, `maple` the original (KR where published, otherwise the
-- global English name translated).
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

local MS = { MainStat = 30 }
local BOSS = { AttackPowerToBoss = 100 }
local FD = { FinalDamage = 30 }

D.MedalMainStatCap = 1500
D.MedalCategories = { "성장", "전투", "보스", "기타" }

D.Medals = {
    -- 성장
    { id = "awak25", cat = 1, name = "고고학자", maple = "아키올로지스트", cond = { "awakening", 25 }, text = "유물 총 각성 25단계 달성", eff = MS },
    { id = "awak45", cat = 1, name = "유물 감정가", maple = "아티팩트 감정가", cond = { "awakening", 45 }, text = "유물 총 각성 45단계 달성", eff = MS },
    { id = "awak70", cat = 1, name = "고대 유물의 수호자", maple = "유물의 대가", cond = { "awakening", 70 }, text = "유물 총 각성 70단계 달성", eff = MS },
    { id = "job3", cat = 1, name = "숙련된 모험가", maple = "세 번째 여정", cond = { "jobStep", 3 }, text = "3차 전직 완료", eff = MS },
    { id = "job4", cat = 1, name = "전설의 모험가", maple = "네 번째 여정", cond = { "jobStep", 4 }, text = "4차 전직 완료", eff = MS },
    { id = "pot5x2", cat = 1, name = "매우 우호적", maple = "존경받는", cond = { "potLines", 5, 2 }, text = "레전드리 잠재 옵션 2개 이상", eff = MS },
    { id = "pot6x2", cat = 1, name = "신비로운", maple = "미스테리어스", cond = { "potLines", 6, 2 }, text = "미스틱 잠재 옵션 2개 이상", eff = MS },
    { id = "pot6x5", cat = 1, name = "비전의 경지", maple = "미스틱의 경지", cond = { "potLines", 6, 5 }, text = "미스틱 잠재 옵션 5개 이상", eff = MS },
    { id = "pot6x10", cat = 1, name = "비전의 정점", maple = "미스틱의 정점", cond = { "potLines", 6, 10 }, text = "미스틱 잠재 옵션 10개 이상", eff = MS },
    { id = "add5x2", cat = 1, name = "전설적인", maple = "레전더리", cond = { "addLines", 5, 2 }, text = "레전드리 에디셔널 잠재 옵션 2개 이상", eff = MS },
    { id = "add6x2", cat = 1, name = "신비술사", maple = "미스틱", cond = { "addLines", 6, 2 }, text = "미스틱 에디셔널 잠재 옵션 2개 이상", eff = MS },
    { id = "add6x5", cat = 1, name = "비전의 완성", maple = "미스틱의 완성", cond = { "addLines", 6, 5 }, text = "미스틱 에디셔널 잠재 옵션 5개 이상", eff = MS },
    { id = "add6x10", cat = 1, name = "비전의 극의", maple = "미스틱의 극의", cond = { "addLines", 6, 10 }, text = "미스틱 에디셔널 잠재 옵션 10개 이상", eff = MS },
    { id = "star15", cat = 1, name = "15성 장인", maple = "15성", cond = { "starSlots", 15, 2 }, text = "장비 슬롯 2개 이상 스타포스 15단계", eff = MS },
    { id = "star18", cat = 1, name = "18성 장인", maple = "18성", cond = { "starSlots", 18, 2 }, text = "장비 슬롯 2개 이상 스타포스 18단계", eff = MS },
    { id = "star20", cat = 1, name = "20성 장인", maple = "20성", cond = { "starSlots", 20, 2 }, text = "장비 슬롯 2개 이상 스타포스 20단계", eff = MS },
    { id = "star22", cat = 1, name = "22성 장인", maple = "22성", cond = { "starSlots", 22, 2 }, text = "장비 슬롯 2개 이상 스타포스 22단계", eff = MS },
    { id = "star24", cat = 1, name = "한계 돌파", maple = "한계를 넘어선", cond = { "starSlots", 24, 1 }, text = "스타포스 24단계 달성", eff = MS },
    { id = "star26", cat = 1, name = "행운아", maple = "럭키", cond = { "starSlots", 26, 1 }, text = "스타포스 26단계 달성", eff = MS },
    { id = "star27", cat = 1, name = "기적", maple = "기적", cond = { "starSlots", 27, 1 }, text = "스타포스 27단계 달성", eff = MS },
    { id = "star28", cat = 1, name = "미지의 영역", maple = "????", cond = { "starSlots", 28, 1 }, text = "스타포스 28단계 달성", eff = MS },
    { id = "star29", cat = 1, name = "지존", maple = "지존", cond = { "starSlots", 29, 1 }, text = "스타포스 29단계 달성", eff = MS },
    { id = "star30", cat = 1, name = "별의 주인", maple = "★★★", cond = { "starSlots", 30, 1 }, text = "스타포스 30단계 달성", eff = MS },
    { id = "hp6", cat = 1, name = "용사의 기운", maple = "메이플러의 아우라", cond = { "heroPower", 6 }, text = "용사의 힘 6단계 달성", eff = MS },
    { id = "hp7", cat = 1, name = "용사의 위엄", maple = "메이플러의 카리스마", cond = { "heroPower", 7 }, text = "용사의 힘 7단계 달성", eff = MS },
    { id = "elite20", cat = 1, name = "소환 전문가", maple = "소환 전문가", cond = { "elite", 20 }, text = "엘리트 몬스터 레벨 20 달성", eff = MS },
    { id = "elite30", cat = 1, name = "소환의 달인", maple = "소환 에이스", cond = { "elite", 30 }, text = "엘리트 몬스터 레벨 30 달성", eff = MS },
    { id = "elite40", cat = 1, name = "소환의 명장", maple = "소환의 명장", cond = { "elite", 40 }, text = "엘리트 몬스터 레벨 40 달성", eff = MS },
    { id = "comp4x8", cat = 1, name = "하이파이브", maple = "하이파이브", cond = { "companions", 4, 8 }, text = "유니크 동료 8개 이상 보유", eff = MS },
    { id = "comp5x8", cat = 1, name = "베스트프렌드", maple = "베스트프랜드", cond = { "companions", 5, 8 }, text = "레전드리 동료 8개 이상 보유", eff = MS },
    { id = "comp5x14", cat = 1, name = "소울메이트", maple = "소울메이트", cond = { "companions", 5, 14 }, text = "레전드리 동료 14개 이상 보유", eff = MS },
    { id = "jour1", cat = 1, name = "특별한 여정", maple = "특별한 여정", cond = { "journeySpecial", 1 }, text = "용사의 여정 특수 옵션 1회 오픈", eff = MS },
    { id = "jour7", cat = 1, name = "찬란한 여정", maple = "찬란한 여정", cond = { "journeySpecial", 7 }, text = "용사의 여정 특수 옵션 7회 오픈", eff = MS },
    { id = "jour15", cat = 1, name = "완성된 여정", maple = "완성된 여정", cond = { "journeySpecial", 15 }, text = "용사의 여정 특수 옵션 15회 오픈", eff = MS },
    -- 전투
    { id = "ch9", cat = 2, name = "재능 있는", maple = "재능 있는", cond = { "chapterBoss", 9 }, text = "9챕터 보스 처치", eff = MS },
    { id = "pq1", cat = 2, name = "스톰윈드 해결사", maple = "커닝시티 해결사", cond = { "pq", "first", 50 }, text = "첫 번째 동행 50회 클리어", eff = MS },
    { id = "pq2", cat = 2, name = "아이언포지 보안관", maple = "루디브리엄 보안관", cond = { "pq", "dimensional", 50 }, text = "차원의 균열 50회 클리어", eff = MS },
    { id = "pq3", cat = 2, name = "다르나서스 방범대", maple = "오르비스 방범대", cond = { "pq", "goddess", 50 }, text = "여신의 흔적 50회 클리어", eff = MS },
    { id = "pq4", cat = 2, name = "썬더 블러프 평화주의자", maple = "마가티아 평화주의자", cond = { "pq", "romeo", 50 }, text = "로미오와 줄리엣 50회 클리어", eff = MS },
    { id = "floor50", cat = 2, name = "50층 용사", maple = "50층 메이플러", cond = { "growthAll", 50 }, text = "모든 성장 던전 50단계 클리어", eff = MS },
    { id = "floor70", cat = 2, name = "70층 용사", maple = "70층 메이플러", cond = { "growthAll", 70 }, text = "모든 성장 던전 70단계 클리어", eff = MS },
    { id = "floor100", cat = 2, name = "100층 용사", maple = "100층 메이플러", cond = { "growthAll", 100 }, text = "모든 성장 던전 100단계 클리어", eff = MS },
    { id = "floor125", cat = 2, name = "125층 용사", maple = "125층 용사", cond = { "growthAll", 125 }, text = "모든 성장 던전 125단계 클리어", eff = MS },
    { id = "floor150", cat = 2, name = "150층 용사", maple = "150층 용사", cond = { "growthAll", 150 }, text = "모든 성장 던전 150단계 클리어", eff = MS },
    { id = "arena100", cat = 2, name = "풋내기 검투사", maple = "아직은 귀여운", cond = { "arenaWins", 100 }, text = "결투장 공격 누적 100승", eff = MS },
    { id = "arena500", cat = 2, name = "단련된 검투사", maple = "파워 업", cond = { "arenaWins", 500 }, text = "결투장 공격 누적 500승", eff = MS },
    { id = "arena1000", cat = 2, name = "압도적인 검투사", maple = "압도적 존재감", cond = { "arenaWins", 1000 }, text = "결투장 공격 누적 1,000승", eff = MS },
    { id = "arena2000", cat = 2, name = "무적의 검투사", maple = "무적의 나", cond = { "arenaWins", 2000 }, text = "결투장 공격 누적 2,000승", eff = MS },
    { id = "arena3000", cat = 2, name = "전설의 검투사", maple = "전설의 나", cond = { "arenaWins", 3000 }, text = "결투장 공격 누적 3,000승", eff = MS },
    { id = "raidParty10", cat = 2, name = "어린양의 수호자", maple = "어린양의 수호자", cond = { "raidParty", 10 }, text = "보스 레이드 파티 모드 누적 10회 클리어", eff = MS },
    { id = "raidParty100", cat = 2, name = "쾌속 항해", maple = "쾌속 항해", cond = { "raidParty", 100 }, text = "보스 레이드 파티 모드 누적 100회 클리어", eff = MS },
    { id = "raidParty500", cat = 2, name = "쾌속 비행", maple = "쾌속 비행", cond = { "raidParty", 500 }, text = "보스 레이드 파티 모드 누적 500회 클리어", eff = MS },
    -- 보스
    { id = "zakumTop", cat = 3, name = "라그나로스 파괴자", maple = "자쿰 파괴자", cond = { "raidTop", "zakum", 5 }, text = "자쿰 카오스 5회 클리어", eff = BOSS },
    { id = "horntailTop", cat = 3, name = "오닉시아 파괴자", maple = "혼테일 파괴자", cond = { "raidTop", "horntail", 5 }, text = "혼테일 카오스 5회 클리어", eff = BOSS },
    { id = "pinkbeanTop", cat = 3, name = "쑨 사냥꾼", maple = "핑크빈 헌터", cond = { "raidTop", "pinkbean", 5 }, text = "핑크빈 어려움 5회 클리어", eff = BOSS },
    { id = "zakumGuild", cat = 3, name = "팀 플레이어", maple = "팀 플레이어", cond = { "guildRaid", "zakum" }, text = "자쿰 최고 난이도 클리어 (구 길드 레이드)", eff = FD },
    { id = "horntailGuild", cat = 3, name = "검은용 토벌대", maple = "길드 레이드: 혼테일", cond = { "guildRaid", "horntail" }, text = "혼테일 최고 난이도 클리어 (구 길드 레이드)", eff = FD },
    { id = "pinkbeanGuild", cat = 3, name = "쑨 슬레이어", maple = "핑크빈 슬레이어", cond = { "guildRaid", "pinkbean" }, text = "핑크빈 최고 난이도 클리어 (구 길드 레이드)", eff = FD },
}

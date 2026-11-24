-- WoW-skin display names for everything that carries a 메이플 키우기 proper noun in the game data.
-- Systems/Skin.lua (S.ApplyNames) writes these over the loaded data at startup and keeps the original
-- in `mapleName` (never shown). Numbers and keys are untouched.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

D.SkinNames = {
    -- WoW class names (class token -> Korean)
    classKo = { WARRIOR = "전사", PALADIN = "성기사", HUNTER = "사냥꾼", ROGUE = "도적", PRIEST = "사제",
        SHAMAN = "주술사", MAGE = "마법사", WARLOCK = "흑마법사", DRUID = "드루이드" },
    -- companion grade -> title (grade 1 = beginner of the class, 2..5 = after 1st..4th job advancement)
    companionTitle = { [1] = "수련생", [2] = "견습", [3] = "숙련", [4] = "정예", [5] = "영웅" },

    -- content
    partyQuests = {
        first = { name = "통곡의 동굴 원정", region = "불모의 땅 파티 퀘스트" },
        dimensional = { name = "놈리건의 균열", region = "던 모로 파티 퀘스트" },
        goddess = { name = "엘룬의 흔적", region = "잿빛 골짜기 파티 퀘스트" },
        romeo = { name = "스칼로맨스의 연금술사", region = "서부 역병지대 파티 퀘스트" },
    },
    difficulty = { ["카오스"] = "격노" },
    balrog = "남작 게돈",
    monsterPark = "구루바시 투기장",
    growth = { training = "영웅의 수련장" },

    -- 유물 (artifacts) by id
    artifacts = {
        [301] = "포세이큰의 부적", [302] = "멧돼지 갈기 리본", [303] = "점술가의 수정구", [304] = "어둠의 서약서",
        [401] = "무지갯빛 거북 등껍질", [402] = "육각 비전 수정 목걸이", [403] = "엘룬의 유리 구두",
        [404] = "포자버섯 군주의 갓", [405] = "달샘의 맑은 물", [406] = "알레리아의 낡은 장갑",
        [407] = "라그나로스의 용암 조각", [408] = "오닉시아의 비늘", [409] = "쑨의 촉수",
        [501] = "고대 성배", [502] = "낡은 노움 오르골", [503] = "은빛 펜던트", [504] = "별의 파편",
        [505] = "고대 마법서", [506] = "달빛 정령", [507] = "화염초", [508] = "영혼 계약서", [509] = "타오르는 등불",
        [510] = "영혼의 주머니", [511] = "고대 문서 조각", [512] = "서리 영혼석", [513] = "끓어오르는 용암",
        [514] = "세나리우스의 목걸이", [515] = "기억의 물병", [516] = "세계수의 명약", [517] = "검은 양초",
        [518] = "맹약의 증표", [519] = "전쟁 뿔피리", [520] = "저주받은 부두 인형", [521] = "겨울 순록의 창",
        [522] = "해적의 비밀 지도", [523] = "청동용군단의 고리",
    },

    -- raid gear by its original name
    gear = {
        ["데아 시두스 이어링"] = "검은용의 귀걸이",
        ["혼테일의 목걸이"] = "오닉시아 비늘 목걸이",
        ["카오스 혼테일의 목걸이"] = "격노한 오닉시아 비늘 목걸이",
        ["블랙빈 마크"] = "공허의 표식",
        ["카오스 핑크빈 마크"] = "격노한 쑨의 표식",
        ["핑크빛 성배"] = "고대 신의 성배",
        ["자쿰의 투구"] = "라그나로스의 투구",
        ["카오스 자쿰의 투구"] = "격노한 라그나로스의 투구",
        ["아쿠아틱 레터 눈장식"] = "용암 문자 눈장식",
    },
}

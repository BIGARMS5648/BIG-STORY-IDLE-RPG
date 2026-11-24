-- Wallet keys (currencies, tickets, materials).
-- maple = original 메이플 키우기 name (reference), name = WoW-skin display name, icon = client icon.
-- Every system uses these keys with ns.Hero.Add/Spend/Count.
local ADDON, ns = ...
ns.Data = ns.Data or {}
local D = ns.Data

D.Currencies = {
    meso              = { maple = "메소", name = "골드", icon = "Interface\\Icons\\INV_Misc_Coin_01", order = 1 },
    redDia            = { maple = "레드 다이아", name = "붉은 다이아", icon = "Interface\\Icons\\INV_Misc_Gem_Ruby_01", order = 2 },
    weaponTicket      = { maple = "무기 소환권", name = "무기 소환서", icon = "Interface\\Icons\\INV_Scroll_03", order = 10 },
    companionTicket   = { maple = "동료 소환권", name = "동료 소환서", icon = "Interface\\Icons\\INV_Scroll_05", order = 11 },
    companionTicket3  = { maple = "3차 전직 동료 소환권", name = "정예 동료 소환서", icon = "Interface\\Icons\\INV_Scroll_06", order = 12 },
    companionTicket4  = { maple = "4차 전직 동료 소환권", name = "영웅 동료 소환서", icon = "Interface\\Icons\\INV_Scroll_04", order = 13 },
    weaponStone       = { maple = "무기 강화석", name = "무기 연마석", icon = "Interface\\Icons\\INV_Stone_SharpeningStone_05", order = 20 },
    cubeMiracle       = { maple = "미라클 큐브", name = "잠재 큐브", icon = "Interface\\Icons\\INV_Misc_Gem_Variety_01", order = 21 },
    cubeAdditional    = { maple = "에디셔널 큐브", name = "추가 잠재 큐브", icon = "Interface\\Icons\\INV_Misc_Gem_Variety_02", order = 22 },
    starforceScroll   = { maple = "스타포스 강화 주문서", name = "별의 주문서", icon = "Interface\\Icons\\INV_Scroll_02", order = 23 },
    spellTrace        = { maple = "주문의 흔적", name = "마력의 흔적", icon = "Interface\\Icons\\INV_Enchant_DustArcane", order = 24 },
    honorMedal        = { maple = "명예의 훈장", name = "명예 훈장", icon = "Interface\\Icons\\INV_Jewelry_Talisman_01", order = 25 },
    heroToken         = { maple = "용사의 증표", name = "영웅의 증표", icon = "Interface\\Icons\\INV_Misc_Rune_01", order = 26 },
    artifactChest     = { maple = "유물상자", name = "유물 상자", icon = "Interface\\Icons\\INV_Box_02", order = 27 },
    artifactStone     = { maple = "유물 강화석", name = "유물 연마석", icon = "Interface\\Icons\\INV_Stone_15", order = 28 },
    eliteSummonPoint  = { maple = "엘리트 몬스터 소환 포인트", name = "정예 소환 포인트", icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", order = 29 },
    subOptionStone    = { maple = "장비 부 옵션 변환석", name = "옵션 변환석", icon = "Interface\\Icons\\INV_Stone_02", order = 30 },
    gearStone         = { maple = "장비 강화석", name = "방어구 연마석", icon = "Interface\\Icons\\INV_Stone_WeightStone_04", order = 35 },
    enchantPouch      = { maple = "마법 부여 주머니", name = "마법 부여 주머니", icon = "Interface\\Icons\\INV_Misc_Bag_10", order = 31 },
    scrollNormal      = { maple = "노말 강화 주문서", name = "일반 강화 주문서", icon = "Interface\\Icons\\INV_Scroll_01", order = 32 },
    scrollRare        = { maple = "레어 강화 주문서", name = "희귀 강화 주문서", icon = "Interface\\Icons\\INV_Scroll_01", order = 33 },
    scrollEpic        = { maple = "에픽 강화 주문서", name = "영웅 강화 주문서", icon = "Interface\\Icons\\INV_Scroll_01", order = 34 },
    -- Systems/Scrolls.lua: scrollNormal = 노말(40%), scrollRare = 레어(40%), scrollEpic = 에픽(70%); the other variants:
    scrollRare25      = { maple = "레어 강화 주문서(25%)", name = "희귀 강화 주문서(25%)", icon = "Interface\\Icons\\INV_Scroll_01", order = 35 },
    scrollEpic30      = { maple = "에픽 강화 주문서(30%)", name = "영웅 강화 주문서(30%)", icon = "Interface\\Icons\\INV_Scroll_01", order = 36 },
    scrollEpic15      = { maple = "에픽 강화 주문서(15%)", name = "영웅 강화 주문서(15%)", icon = "Interface\\Icons\\INV_Scroll_01", order = 37 },
    scrollMystery     = { maple = "알쏭달쏭 주문서", name = "수수께끼 주문서", icon = "Interface\\Icons\\INV_Scroll_07", order = 38 },
    scrollCertainty   = { maple = "확신의 주문서", name = "확신의 주문서", icon = "Interface\\Icons\\INV_Scroll_08", order = 39 },
    scrollZakum1      = { maple = "자쿰의 주문서(하급)", name = "화염 군주의 주문서(하급)", icon = "Interface\\Icons\\INV_Scroll_06", order = 80 },
    scrollZakum2      = { maple = "자쿰의 주문서(중급)", name = "화염 군주의 주문서(중급)", icon = "Interface\\Icons\\INV_Scroll_06", order = 81 },
    scrollHorntail1   = { maple = "혼테일의 주문서(하급)", name = "검은 용의 주문서(하급)", icon = "Interface\\Icons\\INV_Scroll_05", order = 82 },
    scrollHorntail2   = { maple = "혼테일의 주문서(중급)", name = "검은 용의 주문서(중급)", icon = "Interface\\Icons\\INV_Scroll_05", order = 83 },
    scrollPinkBean1   = { maple = "핑크빈의 주문서(하급)", name = "분홍 신의 주문서(하급)", icon = "Interface\\Icons\\INV_Scroll_04", order = 84 },
    scrollPinkBean2   = { maple = "핑크빈의 주문서(중급)", name = "분홍 신의 주문서(중급)", icon = "Interface\\Icons\\INV_Scroll_04", order = 85 },
    scrollBruce1      = { maple = "브루스의 주문서(하급)", name = "브루스의 주문서(하급)", icon = "Interface\\Icons\\INV_Scroll_03", order = 86 },
    scrollBruce2      = { maple = "브루스의 주문서(중급)", name = "브루스의 주문서(중급)", icon = "Interface\\Icons\\INV_Scroll_03", order = 87 },
    scrollBruce3      = { maple = "브루스의 주문서(상급)", name = "브루스의 주문서(상급)", icon = "Interface\\Icons\\INV_Scroll_03", order = 88 },
    -- enchantPouch (above) is the 하급 pouch; the higher pouches:
    enchantPouchMid   = { maple = "중급 마법 부여 주머니", name = "중급 마법 부여 주머니", icon = "Interface\\Icons\\INV_Misc_Bag_09", order = 89 },
    enchantPouchHigh  = { maple = "상급 마법 부여 주머니", name = "상급 마법 부여 주머니", icon = "Interface\\Icons\\INV_Misc_Bag_11", order = 90 },
    enchantPouchTop   = { maple = "최상급 마법 부여 주머니", name = "최상급 마법 부여 주머니", icon = "Interface\\Icons\\INV_Misc_Bag_17", order = 91 },
    quickHuntTicket   = { maple = "빠른 사냥 티켓", name = "빠른 사냥권", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", order = 40 },
    expBooster        = { maple = "경험치 부스터(100%)", name = "경험의 비약", icon = "Interface\\Icons\\INV_Potion_43", order = 41 },
    burningBooster    = { maple = "버닝 필드 부스터", name = "불타는 전장 부스터", icon = "Interface\\Icons\\Spell_Fire_Fire", order = 42 },
    timeSkip1m        = { maple = "시간 단축 티켓(1분)", name = "시간 단축권(1분)", icon = "Interface\\Icons\\INV_Misc_PocketWatch_02", order = 43 },
    bossRaidTicket    = { maple = "보스 레이드 입장권", name = "공격대 입장권", icon = "Interface\\Icons\\INV_Misc_Key_03", order = 50 },
    explorationTicket = { maple = "탐험 티켓", name = "탐험 허가증", icon = "Interface\\Icons\\INV_Misc_Note_01", order = 51 },
    monsterParkTicket = { maple = "몬스터파크 익스트림 입장권", name = "투기장 입장권", icon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Furies", order = 52 },
    expDungeonKey     = { maple = "경험치 던전 열쇠", name = "경험의 열쇠", icon = "Interface\\Icons\\INV_Misc_Key_04", order = 53 },
    weaponDungeonKey  = { maple = "무기 던전 열쇠", name = "무기고 열쇠", icon = "Interface\\Icons\\INV_Misc_Key_10", order = 54 },
    gearDungeonKey    = { maple = "장비 던전 열쇠", name = "장비고 열쇠", icon = "Interface\\Icons\\INV_Misc_Key_11", order = 55 },
    enhanceDungeonKey = { maple = "강화 던전 열쇠", name = "강화의 열쇠", icon = "Interface\\Icons\\INV_Misc_Key_12", order = 56 },
    heroPowerDungeonKey = { maple = "성장던전 입장권: 용사의 힘", name = "수련장 입장권", icon = "Interface\\Icons\\INV_Misc_Key_13", order = 57 },
    arenaTicket       = { maple = "아레나 입장권", name = "결투장 입장권", icon = "Interface\\Icons\\INV_Sword_27", order = 58 },
    journeyKey        = { maple = "여정의 상자 열쇠", name = "여정의 열쇠", icon = "Interface\\Icons\\INV_Misc_Key_14", order = 60 },
    journeyToken      = { maple = "여정의 증표", name = "여정의 증표", icon = "Interface\\Icons\\INV_Misc_Token_ScarletCrusade", order = 61 },
    journeyEnergy     = { maple = "여정의 기운", name = "여정의 기운", icon = "Interface\\Icons\\Spell_Nature_WispSplode", order = 62 },
    memorialScroll    = { maple = "메모리얼 스크롤", name = "추억의 주문서", icon = "Interface\\Icons\\INV_Scroll_07", order = 35 },
    legendaryArtifactSummon = { maple = "레전드리 유물 소환", name = "전설 유물 소환권", icon = "Interface\\Icons\\INV_Misc_Rune_06", order = 36 },
    worldBossCoin     = { maple = "월드보스 코인", name = "세계 우두머리 주화", icon = "Interface\\Icons\\INV_Misc_Coin_04", order = 70 },
    arenaCoin         = { maple = "아레나 코인", name = "결투장 주화", icon = "Interface\\Icons\\INV_Misc_Coin_05", order = 71 },
    guildCoin         = { maple = "길드 코인", name = "길드 주화", icon = "Interface\\Icons\\INV_Misc_Coin_06", order = 72 },
    -- Systems/Content*.lua (현상수배 weekly rank / 마왕 발록 challenge boss)
    wolfCoin          = { maple = "불꽃 늑대 코인", name = "화염 늑대 주화", icon = "Interface\\Icons\\INV_Misc_Coin_07", order = 73 },
    balrogTicket      = { maple = "마왕 발록 입장권", name = "마왕 도전권", icon = "Interface\\Icons\\INV_Misc_Key_15", order = 59 },
}

function D.CurrencyName(key)
    local c = D.Currencies[key]
    return c and c.name or key
end

function D.CurrencyIcon(key)
    local c = D.Currencies[key]
    return c and c.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

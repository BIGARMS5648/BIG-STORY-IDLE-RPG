from common import src, fkr, SOURCES

# ---- mapleidleindex.com (KR community data library; decoded KR PC client tables) ----
src("MII_LEVEL_EXP", "https://mapleidleindex.com/data/level-experience-117.json", "mapleidleindex.com", "client_table_dump",
    "KR PC client 1.18.0 (verifiedAt 2026-11-05; provenance 1.17)", "KR", "2026-11-05",
    "level-experience-117.json (levels, experienceDungeon, chapters)", "mdb/raw/level-experience-117.json",
    "Used by /leveling/ and /growth/ EXP-sweep calculators; Playwright run reproduced the values.")
src("MII_GROWTH", "https://mapleidleindex.com/growth/", "mapleidleindex.com", "client_table_dump",
    "KR PC client 1.18.0", "KR", "2026-11-05", "성장 던전 정보 (inline WEAPON_ROWS/EXP_ROWS/GEAR_ROWS/TRAINING_ROWS/ENHANCE_ROWS + 강화 주문서 드랍률)",
    "mdb/raw/growth.html", "Page states: 클라이언트 1.18.0 기준; monster stats = base × stage multiplier.")
src("MII_HERO_ABILITY", "https://mapleidleindex.com/data/hero-ability-information-117.json", "mapleidleindex.com", "client_table_dump",
    "KR PC client 1.18.0 (provenance 1.17.0)", "KR", "2026-11-05", "용사의 힘 1~9단계 + 어빌리티", "mdb/raw/mii/hero-ability-information-117.json")
src("MII_SUMMON_LEVELS", "https://mapleidleindex.com/data/summon-levels.json", "mapleidleindex.com", "client_table_dump",
    "KR PC client 1.18.0", "KR", "2026-11-05", "무기/동료/어빌리티 소환 레벨 요구량 (GachaLevelTable)", "mdb/raw/mii/summon-levels.json")
src("MII_COMP_SUMMON", "https://mapleidleindex.com/data/companion-summon-rewards.json", "mapleidleindex.com", "client_table_dump",
    "KR PC client 1.18.0", "KR", "2026-11-05", "동료 소환 레벨별 확률·천장", "mdb/raw/mii/companion-summon-rewards.json")
src("MII_HOTDEAL", "https://mapleidleindex.com/assets/hotdeal-catalog.json", "mapleidleindex.com", "client_table_dump",
    "KR PC client 1.18.0", "KR", "2026-11-05", "핫딜/상점 카탈로그 (250 deals, 76 baselines)", "mdb/raw/mii/hotdeal-catalog.json")
src("MII_BOSS", "https://mapleidleindex.com/boss/", "mapleidleindex.com", "client_table_dump",
    "KR PC client 1.18", "KR", "2026-11-05", "보스 컨텐츠 (핑크빈 석상 공격 입력식 A/H, 마왕 발록)", "web/text/boss.txt")

# ---- maplestoryidle.info (global fan site; decoded client tables from a 1.14.0 snapshot) ----
MSI_SNAP = "client 1.14.0 (versionCode 10003329; snapshot 2026-08-13_09-41-16)"
src("MSI_HERO_TOKEN", "https://maplestoryidle.info/assets/data/hero-token-calculator.json", "maplestoryidle.info", "client_table_dump",
    MSI_SNAP, "global", "2026-08-13", "Hero Token Calculator data (HeroPowerSlotLevelTable, DungeonTable, RewardTable, StaminaTable)",
    "mdb/raw/msi-hero-token-calculator.json", "Calculator at /hero-token-calculator.html run in Playwright; outputs match.")
src("MSI_GAMEDATA", "https://maplestoryidle.info/assets/data/game-data-library.json", "maplestoryidle.info", "client_table_dump",
    MSI_SNAP, "global", "2026-08-13", "Game Data Library (1858 stages incl. 5 growth dungeons x 140; jobs)", "mdb/raw/msi-game-data-library.json")
src("MSI_STATRULES", "https://maplestoryidle.info/assets/data/game-stat-rules.json", "maplestoryidle.info", "client_table_dump",
    MSI_SNAP, "global", "2026-08-13", "game-stat-rules.json (StatTypeTable caps, IL2CPP calculators, StatGapValueTable)", "mdb/raw/msi/game-stat-rules.json")
src("MSI_TARGET", "https://maplestoryidle.info/assets/data/target-context-model.json", "maplestoryidle.info", "client_table_dump",
    MSI_SNAP, "global", "2026-08-13", "target-context-model.json (1989 targets; growth dungeons have no reward rows)", "mdb/raw/msi/target-context-model.json")
src("MSI_GUIDE_DMG", "https://maplestoryidle.info/guides/battle-system/damage-calculation/", "maplestoryidle.info", "secondary_summary_of_official",
    "official Guide reviewed 2026-08-06", "global", "2026-08-06", "Damage calculation order (MSI reading of official Guide)", "mdb/raw/msi/guides/battle-system_damage-calculation.html")
src("MSI_GUIDE_CONTENT", "https://maplestoryidle.info/guides/battle-system/content-battle-rules/", "maplestoryidle.info", "secondary_summary_of_official",
    "official Guide reviewed 2026-08-06", "global", "2026-08-06", "Content-specific battle rules", "mdb/raw/msi/guides/battle-system_content-battle-rules.html")
src("MSI_GUIDE_PVP", "https://maplestoryidle.info/guides/battle-system/pvp-defense-adjustment/", "maplestoryidle.info", "secondary_summary_of_official",
    "official Guide reviewed 2026-08-06", "global", "2026-08-06", "PvP defense adjustment", "mdb/raw/msi/guides/battle-system_pvp-defense-adjustment.html")
src("MSI_GUIDE_DEF", "https://maplestoryidle.info/guides/stat-dictionary/defense-and-hit/", "maplestoryidle.info", "secondary_summary_of_official",
    "official Guide reviewed 2026-08-06", "global", "2026-08-06", "Defense & hit stats", "mdb/raw/msi/guides/stat-dictionary_defense-and-hit.html")
src("NX_GUIDE_OFFICIAL", "https://maplestoryidle.nexon.com/ko/guide", "Nexon", "official_guide",
    "unknown", "KR", "n/a", "넥슨 공식 전투 가이드 (NOT RETRIEVED: HTTP 403 bot wall)", "mdb/raw/nexon-guide.html",
    "Fetched once 2026-11-24 -> 403 '<title>NEXON</title>' interstitial; not circumvented. Content known only via MSI summaries.")

# ---- global wiki ----
def wiki(sid, page, ts, notes=""):
    return src(sid, "https://idle.maplestorywiki.net/w/" + page.replace(" ", "_"), "idle.maplestorywiki.net (community wiki)",
               "community_wiki", "global wiki rev " + ts, "global", ts, page, "mdb/raw/wiki/" + page.replace(" ", "_") + ".wiki", notes)

wiki("WIKI_CHARSTATS", "Character Stats", "2025-12-21")
wiki("WIKI_GROWTH", "Growth Dungeon", "2025-11-08")
wiki("WIKI_WEAPON_DG", "Weapon Dungeon", "2025-11-06")
wiki("WIKI_EQUIP_DG", "Equipment Dungeon", "2025-11-20")
wiki("WIKI_ENH_DG", "Enhancement Dungeon", "2026-02-18")
wiki("WIKI_EXP_DG", "EXP Dungeon", "2025-11-20")
wiki("WIKI_GQ", "Guide Quest", "2026-08-11")
wiki("WIKI_QUESTS", "Quests", "2025-11-23")
wiki("WIKI_MEDALS", "Medals", "2026-03-11")
wiki("WIKI_CLASSES", "Classes", "dump 2026-11-24")
wiki("WIKI_EXP_MODULE", "Module:Experience/data.json", "dump 2026-11-24")
wiki("WIKI_COMP_TICKET", "Companion Summoning Ticket", "2025-11-15")
wiki("WIKI_3RD_TICKET", "3rd Job Companion Summoning Ticket", "2025-11-12")
wiki("WIKI_SUMMON_COMP", "Summon Companions", "2025-12-03")
wiki("WIKI_ADREM", "Ad Removal Package", "dump 2026-11-24")
wiki("WIKI_BOWMASTER", "Bowmaster", "dump 2026-11-24", "Mentions 'level-up stat points' (unverified lead for an AP system)")

# ---- official KR forum (Nexon) ----
fkr("NX_PVP_FORMULA", 6633, 3483504, "아레나/콜로세움 수치 적용 오류 수정 및 계산식 변경 안내", "2026-06-25",
    "Written by the development director; gives the full PvP damage formula incl. base damage chain 5000/(6000+DEF×(1-pierce)).")
fkr("NX_ARENA_0622", 6633, 3480968, "아레나/콜로세움 수치 적용 오류 및 사과 보상 안내", "2026-06-22")
fkr("NX_PN_0702", 6698, 3490212, "(추가) 7/2(목) 패치노트", "2026-07-02")
fkr("NX_PN_1114", 6698, 3224718, "11/14(금) 패치노트", "2025-11-13")
fkr("NX_PN_1205", 6698, 3296265, "12/5(금) 패치노트", "2025-12-04")
fkr("NX_PN_0108", 6698, 3339428, "1/8(목) 패치노트", "2026-01-07")
fkr("NX_PN_0212", 6698, 3374751, "2/12(목) 패치노트", "2026-02-11")
fkr("NX_PN_0409", 6698, 3419376, "4/9(목) 패치노트", "2026-04-09")
fkr("NX_PN_0611", 6698, 3473998, "(추가) 6/11(목) 패치노트", "2026-06-11")
fkr("NX_PN_0723", 6698, 3506485, "7/23(목) 패치노트", "2026-07-23")
fkr("NX_PN_0813", 6698, 3521991, "(추가) 8/13(목) 패치노트", "2026-08-13")
fkr("NX_PN_0903", 6698, 3535860, "9/3(목) 패치노트", "2026-09-03")
fkr("NX_PN_0922", 6698, 3550026, "9/22(화) 패치노트", "2026-09-22")
fkr("NX_PN_1105", 6698, 3574353, "11/5(목) 패치노트", "2026-11-05")
fkr("NX_PREVIEW_1126", 6633, 3583715, "11/26(목) 업데이트 미리보기", "2026-11-19", "Preview only: growth dungeons to 160 stages, chapters 48-50 (not yet live on 2026-11-24).")
src("NX_GL_PN_0813", "https://forum.nexon.com/maplestoryidle/board_view?board=6675&thread=3522342", "Nexon (official global forum)",
    "official_notice", "live global at 2026-08-13", "global", "2026-08-13", "August 13 Patch Notes", "mdb/raw/forum/g-3522342.json")
# events / notices with companion tickets or missions
fkr("NX_MONTHLY_ATT", 6697, 3505299, "월간 출석 이벤트", "2026-07-31")
fkr("NX_CHALLENGE_1105", 6697, 3574351, "신규 용사 성장 챌린지 (~12/16)", "2026-11-05")
fkr("NX_ANNIV_POINTS", 6697, 3574348, "1주년 메키 살롱 포인트 보상 (~12/16)", "2026-11-05")
fkr("NX_ANNIV_MISSION", 6697, 3575652, "1주년 메키 살롱 특별 미션 (~12/16)", "2026-11-05")
fkr("NX_ANNIV_SHOP", 6697, 3575655, "1주년 상점 (~12/18)", "2026-11-05")
fkr("NX_ANNIV_SPECIAL_SHOP", 6697, 3575654, "1주년 메키 살롱 스페셜 상점 (~12/18)", "2026-11-05")
fkr("NX_ANNIV_COUPON2", 6697, 3575645, "💌(2탄) 1주년 기념 레벨별 쿠폰 선물!", "2026-11-06")
fkr("NX_NEWCHAR1_1105", 6697, 3575656, "신규 캐릭터 성장 이벤트 1 (~1/6)", "2026-11-05")
fkr("NX_NEWCHAR2_1105", 6697, 3575657, "신규 캐릭터 성장 이벤트 2 (~1/6)", "2026-11-05")
fkr("NX_RING_WORKSHOP", 6697, 3574350, "(수정) 메키 살롱 반지 공방 (~12/16)", "2026-11-05")
fkr("NX_DMB_1119", 7418, 3575660, "일일 미션 부스트 (~11/19)", "2026-11-05")
fkr("NX_DMB_0722", 7418, 3490081, "일일 미션 부스트 (~7/22)", "2026-07-08")
fkr("NX_DMB_HALF", 7418, 3436536, "반주년 메키 페스티벌 일일 미션 부스트 (~5/20)", "2026-05-06")
fkr("NX_COUPON_1D", 7418, 3252827, "🎉 1일차 감사 쿠폰 공개! (~12/17까지)", "2025-11-18")
fkr("NX_LEAF_SHOP", 7418, 3274126, "슈가의 단풍잎 상점", "2025-11-26")
fkr("NX_XMAS_SHOP", 7418, 3310752, "크리스마스 특별 미션 이벤트, 크리스마스 상점", "2025-12-17")
fkr("NX_XMAS_COUPON", 7418, 3323106, "메이플 키우기의 첫 크리스마스! 특별 선물 안내", "2025-12-24")
fkr("NX_NEWCHAR_0129", 7418, 3359520, "신규 캐릭터 성장 이벤트", "2026-01-29")
fkr("NX_SEOL", 7418, 3359521, "설맞이 특별 미션 & 상점 이벤트", "2026-01-29")
fkr("NX_100DAYS", 7418, 3372425, "메이플 키우기 정식 오픈 100일 기념 - 감사 쿠폰 안내", "2026-02-13")
fkr("NX_SPRING", 7418, 3387379, "15일 간 쑥쑥! 봄날의 성장 이벤트", "2026-02-26")
fkr("NX_NEWCHAR_0430", 7418, 3433587, "신규 캐릭터 성장 이벤트 (~7/1)", "2026-04-30")
fkr("NX_HALF_POINTS", 7418, 3433589, "반주년 메키 페스티벌 포인트 보상 이벤트 안내", "2026-04-30")
fkr("NX_HALF_COUPON", 7418, 3433590, "(추가) 메이플 키우기 반주년 기념 특별 선물", "2026-04-30")
fkr("NX_HALF_COUPON2", 7418, 3440884, "메이플 키우기 반주년 기념 쿠폰 깜짝 선물", "2026-05-07")
fkr("NX_HALF_STAMP", 7418, 3448581, "반주년 스탬프 미션 (~6/10)", "2026-05-21")
fkr("NX_GIFT300", 7418, 3506500, "업데이트 기념 깜짝 쿠폰 선물 (~9/2)", "2026-07-23")
fkr("NX_RELIC_DIG", 7418, 3521780, "유물 발굴 대작전!(~9/2)", "2026-08-13")
fkr("NX_PINKBEAN_COUPON", 7418, 3536440, "핑크빈 맞이 깜짝 쿠폰 선물 (~10/14)", "2026-09-03")
fkr("NX_HANGAWI", 7418, 3549924, "한가위 풍성한 출석 (~9/29)", "2026-09-22")
fkr("NX_OCT", 7418, 3563015, "신비한 10월,메키와 함께 (~11/4)", "2026-10-15")
fkr("NX_BP_APOLOGY", 6633, 3394412, "(추가) 배틀 패스 부스트 이벤트 관련 처리 방향 안내", "2026-03-05")
fkr("NX_7DAY", 6697, 3339445, "7일 특별 미션 이벤트!", "2026-01-08")

# ---- community (KR) ----
src("DC48415", "https://gall.dcinside.com/mgallery/board/view/?id=maplerpg&no=48415", "dcinside 메이플 키우기 갤러리", "community_post",
    "live KR 2025-11", "KR", "2025-11-22", "[정보] 14일 특별 미션 정리", "web/research/income/dc (earlier repo research)")
src("MEKI_14D", "https://www.mekifun.com/en/info/14-day-special-mission", "mekifun.com", "community_site", "live KR 2025-11", "KR",
    "n/a", "14-day special mission", "web/research/income/mekifun/14-day-special-mission.html")
src("MEKI_RD", "https://www.mekifun.com/en/info/red-diamond-priority", "mekifun.com", "community_site", "live KR", "KR", "n/a",
    "Red Diamond Priority & Sources", "web/research/income/mekifun (earlier repo research)")
src("IV731", "https://www.inven.co.kr/board/mapleidle/6554/731", "Inven 메이플 키우기", "community_post", "live KR", "KR", "2026-10-26",
    "1주년 전까지 동료뽑기 얼마나 모을 수 있을까?", "earlier repo research (research-income.md)")
src("DC435362", "https://gall.dcinside.com/mgallery/board/view/?id=maplerpg&no=435362", "dcinside 메이플 키우기 갤러리", "community_post",
    "live KR", "KR", "2026-11-06", "광고 10 / 주간미션 500 (무기 소환권)", "earlier repo research (research-income.md)")
src("IV114", "https://www.inven.co.kr/board/mapleidle/6554/114", "Inven 메이플 키우기", "community_post", "live KR", "KR", "2026-09-02",
    "일일·주간 숙제 체크 리스트", "earlier repo research")
src("IV398", "https://www.inven.co.kr/board/mapleidle/6554/398", "Inven 메이플 키우기", "community_post", "live KR", "KR", "2026-09-10",
    "콘텐츠/장비 슬롯 해금 순서 정리 (가이드 퀘스트 번호)", "earlier repo research")
src("REPO_INCOME", "research-income.md (repo scratchpad spec, built 2026-11-24)", "earlier repo research", "derived_summary",
    "mixed", "KR", "2026-11-24", "research-income.md sections 2-3", "scratchpad/spec/research-income.md")
src("REPO_PROGRESSION", "research/spec/research-progression.md", "earlier repo research", "derived_summary", "mixed", "KR/global",
    "2026-11-24", "research-progression.md §6, §9", "research/spec/research-progression.md")

# ---- checked but no usable data ----
src("SLIPPA", "https://www.slippa.dev/case-study/", "slippa.dev", "case_study", "n/a", "n/a", "n/a",
    "I took apart MapleStory Idle (case study)", "mdb/raw/slippa/", "States the model is private and built on Nexon data 'which isn't mine to publish'; no data files.")
src("GH_OPTIMIZER", "https://github.com/yanivgoft/MapleStoryIdleOptimizer", "GitHub (yanivgoft)", "public_repo", "n/a", "global", "2026-11",
    "MapleStoryIdleOptimizer README/CLAUDE.md", "mdb/raw/gh/", "Outgoing DPS only; no base stats, incoming damage or dungeon reward tables.")
src("PLAYWRIGHT_RUN", "local Playwright run of https://mapleidleindex.com/growth/#exp and https://maplestoryidle.info/hero-token-calculator.html",
    "this research", "calculator_execution", "as served 2026-11-24", "KR/global", "2026-11-24", "Calculator output capture",
    "mdb/raw/playwright_calculator_outputs.json")

# ---- hosts / pages that could not be used (documented for completeness)
src("NAMU_SYSTEM", "https://namu.wiki/w/메이플%20키우기/시스템", "namu.wiki", "not_accessible", "n/a", "KR", "n/a",
    "메이플 키우기/시스템 (seen only as web-search snippets)", "-", "Cloudflare challenge per brief; fetch not attempted/denied. Snippets mention 능력치 포인트 / 메이플 등급 and weapon dungeon 'max 50 tickets'.")
src("BLUESTACKS_GUIDE", "https://www.bluestacks.com/blog/game-guides/maplestory-idle-rpg/mpsir-beginners-guide-en.html", "bluestacks.com", "not_accessible",
    "n/a", "global", "n/a", "Beginner's Guide (mentions 'Maple Rank')", "-", "Host not on the allowlist; known only from web-search snippet.")
src("MAPLEIDLEGG", "https://mapleidle.gg/", "mapleidle.gg", "not_accessible", "n/a", "KR", "n/a", "mapleidle.gg", "web/research/progression/mapleidlegg/index.html",
    "Vercel Security Checkpoint ('We're verifying your browser') - bot wall, not circumvented.")

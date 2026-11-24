# 스킬 스킨 맵 (메이플 키우기 → WoW: Forever)

규칙: 계수·수치는 그대로, 이름/아이콘만 교체. 애드온은 `GetSpellInfo(wowSpellId)`로 현지화 이름·아이콘을 가져오고 실패 시 `nameKo`/`icon` 사용.
confidence = 주문 ID 신뢰도 (high/medium/low). 숙련(mastery) source: talent = 실제 특성(1랭크 ID, 이름 뒤 숫자=순번), talentExtraRank = 실제 최대 랭크 초과 순번, generated = "<매핑된 주문> 숙련 N".

| 메이플 직업 | 표시명 | classToken | classIcon | specIcon |
|---|---|---|---|---|
| 히어로 (`hero`) | 무기 전사 | WARRIOR | ClassIcon_Warrior | Ability_Rogue_Eviscerate |
| 팔라딘 (`paladin`) | 보호 성기사 | PALADIN | ClassIcon_Paladin | Spell_Holy_DevotionAura |
| 다크나이트 (`darkKnight`) | 분노 전사 | WARRIOR | ClassIcon_Warrior | Ability_Warrior_InnerRage |
| 아크메이지(썬·콜) (`archMageIL`) | 정기 주술사 | SHAMAN | ClassIcon_Shaman | Spell_Nature_Lightning |
| 아크메이지(불·독) (`archMageFP`) | 파괴 흑마법사 | WARLOCK | ClassIcon_Warlock | Spell_Shadow_RainOfFire |
| 비숍 (`bishop`) | 신성 사제 | PRIEST | ClassIcon_Priest | Spell_Holy_HolyBolt |
| 보우마스터 (`bowMaster`) | 냉기 마법사 | MAGE | ClassIcon_Mage | Spell_Frost_FrostBolt02 |
| 신궁 (`marksman`) | 사격 사냥꾼 | HUNTER | ClassIcon_Hunter | Ability_Marksmanship |
| 나이트로드 (`nightLord`) | 암살 도적 | ROGUE | ClassIcon_Rogue | Ability_Rogue_Eviscerate |
| 섀도어 (`shadower`) | 악마 흑마법사 | WARLOCK | ClassIcon_Warlock | Spell_Shadow_Metamorphosis |
| 바이퍼 (`viper`) | 야성 드루이드 | DRUID | ClassIcon_Druid | Ability_Druid_CatForm |
| 캡틴 (`captain`) | 야수 사냥꾼 | HUNTER | ClassIcon_Hunter | Ability_Hunter_BeastTaming |
| 나이트워커 (`nightWalker`) | 암흑 사제 | PRIEST | ClassIcon_Priest | Spell_Shadow_ShadowWordPain |
| 윈드브레이커 (`windBreaker`) | 조화 드루이드 | DRUID | ClassIcon_Druid | Spell_Nature_StarFall |
| 플레임위자드 (`flameWizard`) | 화염 마법사 | MAGE | ClassIcon_Mage | Spell_Fire_FireBolt02 |
| 소울마스터 (`soulMaster`) | 징벌 성기사 | PALADIN | ClassIcon_Paladin | Spell_Holy_AuraOfLight |

## 히어로 → 무기 전사 (Arms Warrior)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 11010 | 슬래시 블러스트 | 1차 BA | 영웅의 일격 | Heroic Strike | 78 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 광폭화 | Berserker Rage | 18499 | high |
| 11020 | 워리어 리프 | 1차 passive | 봉쇄 | Intercept | 20252 | high |
| 11030 | 아이언 바디 | 1차 passive | 튕겨내기 | Deflection | 16462 | medium |
| 11040 | 워리어 마스터리 | 1차 passive | 전투 태세 | Battle Stance | 2457 | high |
| 12010 | 브랜디쉬 | 2차 BA | 회전베기 | Cleave | 845 | high |
| 12060 | 웨폰 액셀레이션 | 2차 passive | 질풍 | Flurry | 12319 | high |
| 12020 | 플래시 슬래시 | 2차 active | 천둥벼락 | Thunder Clap | 6343 | high |
| 12080 | 피지컬 트레이닝 | 2차 passive | 양손 무기 전문화 | Two-Handed Weapon Specialization | 12163 | high |
| 12040 | 스피릿 블레이드 | 2차 buff | 전투의 외침 | Battle Shout | 6673 | high |
| 12050 | 웨폰 마스터리 | 2차 passive | 장창 전문화 | Polearm Specialization | 12165 | medium |
| 12030 | 콤보 어택 | 2차 passive | 분노 조절 | Anger Management | 12296 | high |
| 12070 | 파이널 어택 | 2차 passive | 도검 전문화 | Sword Specialization | 12281 | medium |
| 13010 | 브레이브 슬래시 | 3차 BA | 격돌 | Slam | 1464 | high |
| 13060 | 셀프 리커버리 | 3차 passive | 피의 분노 | Bloodrage | 2687 | high |
| 13030 | 돌진 | 3차 active | 돌진 | Charge | 100 | high |
| 13040 | 스카링 소드 | 3차 buff | 방어구 가르기 | Sunder Armor | 7386 | high |
| 13020 | 오라 블레이드 | 3차 active | 소용돌이 | Whirlwind | 1680 | high |
| 13070 | 찬스 어택 | 3차 passive | 도끼 전문화 | Axe Specialization | 12700 | medium |
| 13080 | 인듀어 | 3차 passive | 강철 의지 | Iron Will | 12300 | medium |
| 13050 | 콤보 시너지 | 3차 passive | 전술 숙련 | Tactical Mastery | 12295 | high |
| 14010 | 레이징 블로우 | 4차 BA | 필사의 일격 | Mortal Strike | 12294 | high |
| 14100 | 메이플 용사 | 4차 passive | 꿰뚫기 | Impale | 16493 | high |
| 14030 | 인사이징 | 4차 active | 분쇄 | Rend | 772 | high |
| 14080 | 어드밴스드 파이널 어택 | 4차 passive | 둔기 전문화 | Mace Specialization | 12284 | medium |
| 14020 | 인핸스 레이징 블로우 | 4차 active | 마무리 일격 | Execute | 5308 | high |
| 14060 | 어드밴스드 콤보 | 4차 passive | 격노 | Enrage | 12317 | high |
| 14050 | 인레이지 | 4차 passive | 죽음의 소원 | Death Wish | 12328 | high |
| 14040 | 매직 크래쉬 | 4차 active | 제압 | Overpower | 7384 | high |
| 14090 | 컴뱃 마스터리 | 4차 passive | 휩쓸기 일격 | Sweeping Strikes | 12292 | high |
| 14070 | 스탠스 | 4차 passive | 광폭 태세 | Berserker Stance | 2458 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 10010 | 슬래시 블러스트 - 피해 | 12 | 영웅의 일격 연마 1 | 12282 | high | talent |
| 10020 | 슬래시 블러스트 - 대상 | 15 | 영웅의 일격 연마 2 | 12282 | high | talent |
| 10030 | 슬래시 블러스트 - 피해 | 19 | 영웅의 일격 연마 3 | 12282 | high | talent |
| 10040 | 슬래시 블러스트 - 대상 | 22 | 영웅의 일격 연마 4 | 12282 | high | talentExtraRank |
| 10050 | 슬래시 블러스트 - 피해 | 26 | 영웅의 일격 연마 5 | 12282 | high | talentExtraRank |
| 10060 | 브랜디쉬 - 피해 | 32 | 회전베기 연마 1 | 12329 | high | talent |
| 10070 | 브랜디쉬 - 대상 | 37 | 회전베기 연마 2 | 12329 | high | talent |
| 10080 | 브랜디쉬 - 피해 | 42 | 회전베기 연마 3 | 12329 | high | talent |
| 10090 | 브랜디쉬 - 보스 몬스터 피해 | 47 | 회전베기 연마 4 | 12329 | high | talentExtraRank |
| 10100 | 브랜디쉬 - 피해 | 52 | 회전베기 연마 5 | 12329 | high | talentExtraRank |
| 10110 | 브랜디쉬 - 타격 | 56 | 회전베기 연마 6 | 12329 | high | talentExtraRank |
| 10120 | 브레이브 슬래시 - 피해 | 62 | 격돌 연마 1 | 12862 | medium | talent |
| 10130 | 브레이브 슬래시 - 피해 | 66 | 격돌 연마 2 | 12862 | medium | talent |
| 10140 | 브레이브 슬래시 - 보스 몬스터 피해 | 71 | 격돌 연마 3 | 12862 | medium | talent |
| 10150 | 브레이브 슬래시 - 피해 | 76 | 격돌 연마 4 | 12862 | medium | talent |
| 10160 | 브레이브 슬래시 - 피해 | 80 | 격돌 연마 5 | 12862 | medium | talent |
| 10170 | 브레이브 슬래시 - 보스 몬스터 피해 | 84 | 격돌 연마 6 | 12862 | medium | talentExtraRank |
| 10180 | 브레이브 슬래시 - 피해 | 88 | 격돌 연마 7 | 12862 | medium | talentExtraRank |
| 10190 | 브레이브 슬래시 - 피해 | 92 | 격돌 연마 8 | 12862 | medium | talentExtraRank |
| 10200 | 브레이브 슬래시 - 타격 | 96 | 격돌 연마 9 | 12862 | medium | talentExtraRank |
| 10210 | 레이징 블로우 - 피해 | 102 | 필사의 일격 숙련 1 | 12294 | high | generated |
| 10220 | 레이징 블로우 - 피해 | 106 | 필사의 일격 숙련 2 | 12294 | high | generated |
| 10230 | 레이징 블로우 - 보스 몬스터 피해 | 111 | 필사의 일격 숙련 3 | 12294 | high | generated |
| 10240 | 레이징 블로우 - 피해 | 116 | 필사의 일격 숙련 4 | 12294 | high | generated |
| 10250 | 레이징 블로우 - 피해 | 120 | 필사의 일격 숙련 5 | 12294 | high | generated |
| 10260 | 레이징 블로우 - 보스 몬스터 피해 | 124 | 필사의 일격 숙련 6 | 12294 | high | generated |
| 10270 | 레이징 블로우 - 피해 | 128 | 필사의 일격 숙련 7 | 12294 | high | generated |
| 10280 | 레이징 블로우 - 피해 | 132 | 필사의 일격 숙련 8 | 12294 | high | generated |
| 10290 | 레이징 블로우 - 타격 | 136 | 필사의 일격 숙련 9 | 12294 | high | generated |
| 10015 | 주스탯 강화 | 14 | 강인함 | 12299 | medium | talent |
| 10025 | 크리티컬 확률 강화 | 17 | 잔혹성 | 12320 | high | talent |
| 10035 | 아이언 바디 - 방어력 | 21 | 튕겨내기 숙련 | 16462 | medium | generated |
| 10045 | 워리어 마스터리 - 속도 | 24 | 전투 태세 숙련 | 2457 | high | generated |
| 10055 | 기본 공격 데미지 강화 | 28 | 피의 광기 | 16487 | medium | talent |
| 10065 | 명중 강화 | 34 | 제압 연마 | 12290 | high | talent |
| 10075 | 플래시 슬래시 - 피해 | 39 | 천둥벼락 연마 | 12287 | high | talent |
| 10085 | 스피릿 블레이드 - 재사용 | 44 | 전투의 외침 연마 | 12318 | medium | talent |
| 10095 | 콤보 어택 - 공격력 | 49 | 분노 조절 숙련 | 12296 | high | generated |
| 10105 | 파이널 어택 - 피해 | 54 | 도검 전문화 숙련 | 12281 | medium | generated |
| 10115 | 최대 데미지 배율 강화 | 58 | 깊은 상처 | 12162 | high | talent |
| 10125 | 기본 공격 대상 수 강화 | 64 | 날카로운 고함 | 12323 | high | talent |
| 10135 | 돌진 - 피해 | 68 | 돌진 연마 1 | 12285 | high | talent |
| 10145 | 오라 블레이드 - 피해 | 73 | 소용돌이 숙련 1 | 1680 | high | generated |
| 10155 | 스카링 소드 - 약화 | 78 | 방어구 가르기 연마 | 12308 | medium | talent |
| 10165 | 콤보 시너지 - 최종 데미지 | 82 | 전술 숙련 숙련 | 12295 | high | generated |
| 10175 | 스킬 데미지 강화 | 86 | 우렁찬 목소리 | 12321 | high | talent |
| 10185 | 돌진 - 재사용 | 90 | 돌진 연마 2 | 12285 | high | talent |
| 10195 | 오라 블레이드 - 타격 | 94 | 소용돌이 숙련 2 | 1680 | high | generated |
| 10205 | 셀프 리커버리 - 공격력 | 98 | 피의 분노 연마 | 12301 | medium | talent |
| 10215 | 오라 블레이드 - 재사용 | 104 | 소용돌이 숙련 3 | 1680 | high | generated |
| 10225 | 인사이징 - 피해 | 108 | 분쇄 연마 1 | 12286 | high | talent |
| 10235 | 어드밴스드 파이널 어택 - 강화 | 113 | 둔기 전문화 숙련 | 12284 | medium | generated |
| 10245 | 어드밴스드 콤보 - 최대 중첩 | 118 | 격노 숙련 1 | 12317 | high | generated |
| 10255 | 인핸스 레이징 블로우 - 피해 | 122 | 마무리 일격 연마 1 | 20502 | medium | talent |
| 10265 | 매직 크래쉬 - 약화 | 126 | 제압 숙련 | 7384 | high | generated |
| 10275 | 어드밴스드 콤보 - 방어 관통력 | 130 | 격노 숙련 2 | 12317 | high | generated |
| 10285 | 인사이징 - 약화 | 134 | 분쇄 연마 2 | 12286 | high | talent |
| 10295 | 인핸스 레이징 블로우 - 피해 | 138 | 마무리 일격 연마 2 | 20502 | medium | talent |

## 팔라딘 → 보호 성기사 (Protection Paladin)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 21010 | 슬래시 블러스트 | 1차 BA | 정의의 문장 | Seal of Righteousness | 21084 | medium |
| 9000 | 민첩한 몸놀림 | 0차 buff | 자유의 축복 | Blessing of Freedom | 1044 | high |
| 21020 | 워리어 리프 | 1차 passive | 군마 소환 | Summon Warhorse | 13819 | high |
| 21030 | 아이언 바디 | 1차 passive | 강인함 | Toughness | 20143 | medium |
| 21040 | 워리어 마스터리 | 1차 passive | 신성한 힘 | Divine Strength | 20262 | medium |
| 22010 | 디바인 스윙 | 2차 BA | 심판 | Judgement | 20271 | high |
| 22060 | 웨폰 액셀레이션 | 2차 passive | 성전사의 문장 | Seal of the Crusader | 21082 | high |
| 22020 | 페이지 오더 | 2차 active | 퇴마술 | Exorcism | 879 | high |
| 22080 | 피지컬 트레이닝 | 2차 passive | 한손 무기 전문화 | One-Handed Weapon Specialization | 20196 | medium |
| 22040 | 스탠스 | 2차 passive | 정의의 격노 | Righteous Fury | 25780 | high |
| 22050 | 웨폰 마스터리 | 2차 passive | 정밀함 | Precision | 20189 | medium |
| 22030 | 홀리 차지 | 2차 passive | 응징 | Vengeance | 20049 | medium |
| 22070 | 파이널 어택 | 2차 passive | 심판의 시간 | Reckoning | 20177 | medium |
| 23010 | 디바인 차지 | 3차 BA | 지휘의 문장 | Seal of Command | 20375 | high |
| 23070 | 아킬레스 | 3차 passive | 방패 전문화 | Shield Specialization | 20148 | low |
| 23020 | 돌진 | 3차 active | 심판의 망치 | Hammer of Justice | 853 | high |
| 23040 | 노블 디맨드 | 3차 active | 천벌 | Holy Wrath | 2812 | high |
| 23050 | 컴뱃 오더스 | 3차 buff | 지혜의 축복 | Blessing of Wisdom | 19742 | high |
| 23060 | 파라쇼크 가드 | 3차 passive | 헌신의 오라 | Devotion Aura | 465 | high |
| 23030 | 리스토네이션 | 3차 buff | 신의 축복 | Lay on Hands | 633 | high |
| 23080 | 블레싱 아머 | 3차 passive | 신의 가호 | Divine Protection | 498 | high |
| 24010 | 블래스트 | 4차 BA | 신성화 | Consecration | 26573 | high |
| 24100 | 메이플 용사 | 4차 passive | 신성의 오라 | Sanctity Aura | 20218 | high |
| 24030 | 생츄어리 | 4차 active | 천벌의 망치 | Hammer of Wrath | 24275 | high |
| 24060 | 가디언 스피릿 | 4차 buff | 성역의 축복 | Blessing of Sanctuary | 20911 | high |
| 24020 | 디바인 스티그마 | 4차 active | 신성한 방패 | Holy Shield | 20925 | high |
| 24090 | 어드밴스드 홀리 차지 | 4차 passive | 확신 | Conviction | 20117 | medium |
| 24050 | 디바인 블레싱 | 4차 buff | 왕의 축복 | Blessing of Kings | 20217 | high |
| 24040 | 매직 크래쉬 | 4차 active | 신성 충격 | Holy Shock | 20473 | high |
| 24080 | 팔라딘 엑스퍼트 | 4차 passive | 힘의 축복 연마 | Improved Blessing of Might | 20042 | medium |
| 24070 | 디바인 저지먼트 | 4차 passive | 눈에는 눈 | Eye for an Eye | 9799 | medium |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 20010 | 슬래시 블러스트 - 피해 | 12 | 정의의 문장 연마 1 | 20224 | medium | talent |
| 20020 | 슬래시 블러스트 - 대상 | 15 | 정의의 문장 연마 2 | 20224 | medium | talent |
| 20030 | 슬래시 블러스트 - 피해 | 19 | 정의의 문장 연마 3 | 20224 | medium | talent |
| 20040 | 슬래시 블러스트 - 대상 | 22 | 정의의 문장 연마 4 | 20224 | medium | talent |
| 20050 | 슬래시 블러스트 - 피해 | 26 | 정의의 문장 연마 5 | 20224 | medium | talent |
| 20060 | 디바인 스윙 - 피해 | 32 | 심판 연마 1 | 25956 | low | talent |
| 20070 | 디바인 스윙 - 대상 | 37 | 심판 연마 2 | 25956 | low | talent |
| 20080 | 디바인 스윙 - 피해 | 42 | 심판 연마 3 | 25956 | low | talentExtraRank |
| 20090 | 디바인 스윙 - 보스 몬스터 피해 | 47 | 심판 연마 4 | 25956 | low | talentExtraRank |
| 20100 | 디바인 스윙 - 피해 | 52 | 심판 연마 5 | 25956 | low | talentExtraRank |
| 20110 | 디바인 스윙 - 타격 | 56 | 심판 연마 6 | 25956 | low | talentExtraRank |
| 20120 | 디바인 차지 - 피해 | 62 | 지휘의 문장 숙련 1 | 20375 | high | generated |
| 20130 | 디바인 차지 - 피해 | 66 | 지휘의 문장 숙련 2 | 20375 | high | generated |
| 20140 | 디바인 차지 - 보스 몬스터 피해 | 71 | 지휘의 문장 숙련 3 | 20375 | high | generated |
| 20150 | 디바인 차지 - 피해 | 76 | 지휘의 문장 숙련 4 | 20375 | high | generated |
| 20160 | 디바인 차지 - 피해 | 80 | 지휘의 문장 숙련 5 | 20375 | high | generated |
| 20170 | 디바인 차지 - 보스 몬스터 피해 | 84 | 지휘의 문장 숙련 6 | 20375 | high | generated |
| 20180 | 디바인 차지 - 피해 | 88 | 지휘의 문장 숙련 7 | 20375 | high | generated |
| 20190 | 디바인 차지 - 피해 | 92 | 지휘의 문장 숙련 8 | 20375 | high | generated |
| 20200 | 디바인 차지 - 타격 | 96 | 지휘의 문장 숙련 9 | 20375 | high | generated |
| 20210 | 블래스트 - 피해 | 102 | 신성화 숙련 1 | 26573 | high | generated |
| 20220 | 블래스트 - 피해 | 106 | 신성화 숙련 2 | 26573 | high | generated |
| 20230 | 블래스트 - 보스 몬스터 피해 | 111 | 신성화 숙련 3 | 26573 | high | generated |
| 20240 | 블래스트 - 피해 | 116 | 신성화 숙련 4 | 26573 | high | generated |
| 20250 | 블래스트 - 피해 | 120 | 신성화 숙련 5 | 26573 | high | generated |
| 20260 | 블래스트 - 보스 몬스터 피해 | 124 | 신성화 숙련 6 | 26573 | high | generated |
| 20270 | 블래스트 - 피해 | 128 | 신성화 숙련 7 | 26573 | high | generated |
| 20280 | 블래스트 - 피해 | 132 | 신성화 숙련 8 | 26573 | high | generated |
| 20290 | 블래스트 - 타격 | 136 | 신성화 숙련 9 | 26573 | high | generated |
| 20015 | 주스탯 강화 | 14 | 신성한 지능 | 20257 | medium | talent |
| 20025 | 크리티컬 확률 강화 | 17 | 성전사의 문장 연마 | 20335 | medium | talent |
| 20035 | 아이언 바디 - 방어력 | 21 | 헌신의 오라 연마 | 20138 | medium | talent |
| 20045 | 워리어 마스터리 - 속도 | 24 | 신성한 힘 숙련 | 20262 | medium | generated |
| 20055 | 기본 공격 데미지 강화 | 28 | 양손 무기 전문화 | 20111 | medium | talent |
| 20065 | 명중 강화 | 34 | 예지 | 20096 | medium | talent |
| 20075 | 페이지 오더 - 피해 | 39 | 퇴마술 숙련 1 | 879 | high | generated |
| 20085 | 페이지 오더 - 약화 | 44 | 퇴마술 숙련 2 | 879 | high | generated |
| 20095 | 홀리 차지 - 공격력 | 49 | 응징 숙련 | 20049 | medium | generated |
| 20105 | 파이널 어택 - 피해 | 54 | 심판의 시간 숙련 | 20177 | medium | generated |
| 20115 | 최대 데미지 배율 강화 | 58 | 보루 | 20127 | medium | talent |
| 20125 | 기본 공격 대상 수 강화 | 64 | 정의의 격노 연마 | 20468 | medium | talent |
| 20135 | 돌진 - 피해 | 68 | 심판의 망치 연마 1 | 20487 | medium | talent |
| 20145 | 노블 디맨드 - 피해 | 73 | 천벌 숙련 1 | 2812 | high | generated |
| 20155 | 리스토네이션 - 공격력 | 78 | 신의 축복 연마 | 20234 | medium | talent |
| 20165 | 컴뱃 오더스 - 데미지 | 82 | 지혜의 축복 연마 1 | 20244 | medium | talent |
| 20175 | 스킬 데미지 강화 | 86 | 신성 마법 강화 | 5923 | medium | talent |
| 20185 | 돌진 - 재사용 | 90 | 심판의 망치 연마 2 | 20487 | medium | talent |
| 20195 | 노블 디맨드 - 재사용 | 94 | 천벌 숙련 2 | 2812 | high | generated |
| 20205 | 파라쇼크 가드 - 공격력 | 98 | 헌신의 오라 숙련 | 465 | high | generated |
| 20215 | 컴뱃 오더스 - 4차 스킬 | 104 | 지혜의 축복 연마 2 | 20244 | medium | talent |
| 20225 | 생츄어리 - 피해 | 108 | 천벌의 망치 숙련 1 | 24275 | high | generated |
| 20235 | 가디언 스피릿 - 보호 | 113 | 수호자의 은총 | 20174 | medium | talent |
| 20245 | 어드밴스드 홀리 차지 - 최종 데미지 | 118 | 확신 숙련 | 20117 | medium | generated |
| 20255 | 디바인 스티그마 - 피해 | 122 | 신성한 방패 숙련 1 | 20925 | high | generated |
| 20265 | 디바인 블레싱 - 최종 데미지 | 126 | 왕의 축복 숙련 | 20217 | high | generated |
| 20275 | 디바인 저지먼트 - 피해 | 130 | 눈에는 눈 숙련 | 9799 | medium | generated |
| 20285 | 생츄어리 - 보스 데미지 | 134 | 천벌의 망치 숙련 2 | 24275 | high | generated |
| 20295 | 디바인 스티그마 - 약화 | 138 | 신성한 방패 숙련 2 | 20925 | high | generated |

## 다크나이트 → 분노 전사 (Fury Warrior)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 31010 | 슬래시 블러스트 | 1차 BA | 영웅의 일격 | Heroic Strike | 78 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 광폭화 | Berserker Rage | 18499 | high |
| 31020 | 워리어 리프 | 1차 passive | 봉쇄 | Intercept | 20252 | high |
| 31030 | 아이언 바디 | 1차 passive | 강인함 | Toughness | 12299 | medium |
| 31040 | 워리어 마스터리 | 1차 passive | 전투 태세 | Battle Stance | 2457 | high |
| 32010 | 스피어 풀링 | 2차 BA | 회전베기 | Cleave | 845 | high |
| 32070 | 웨폰 액셀레이션 | 2차 passive | 질풍 | Flurry | 12319 | high |
| 32020 | 비홀더 | 2차 active | 사기의 외침 | Demoralizing Shout | 1160 | high |
| 32050 | 아이언 월 | 2차 passive | 방어 태세 | Defensive Stance | 71 | high |
| 32030 | 비홀더 쇼크 | 2차 active | 위협의 외침 | Intimidating Shout | 5246 | high |
| 32060 | 웨폰 마스터리 | 2차 passive | 도끼 전문화 | Axe Specialization | 12700 | medium |
| 32040 | 하이퍼 바디 | 2차 buff | 전투의 외침 | Battle Shout | 6673 | high |
| 32080 | 파이널 어택 | 2차 passive | 주체할 수 없는 분노 | Unbridled Wrath | 12322 | high |
| 33010 | 라만차 스피어 | 3차 BA | 소용돌이 | Whirlwind | 1680 | high |
| 33040 | 비홀더 도미넌트 | 3차 passive | 깊은 상처 | Deep Wounds | 12162 | high |
| 33020 | 돌진 | 3차 active | 돌진 | Charge | 100 | high |
| 33030 | 크로스 오버 체인 | 3차 buff | 무모함 | Recklessness | 1719 | high |
| 33060 | 비홀더스 버프 | 3차 passive | 우렁찬 목소리 | Booming Voice | 12321 | high |
| 33070 | 로드 오브 다크니스 | 3차 passive | 격노 | Enrage | 12317 | high |
| 33080 | 인듀어 | 3차 passive | 강철 의지 | Iron Will | 12300 | medium |
| 33050 | 비홀더 쇼크 강화 | 3차 passive | 날카로운 고함 | Piercing Howl | 12323 | high |
| 34010 | 다크 임페일 | 4차 BA | 피의 갈증 | Bloodthirst | 23881 | high |
| 34100 | 메이플 용사 | 4차 passive | 잔혹성 | Cruelty | 12320 | high |
| 34020 | 궁니르 디센트 | 4차 active | 마무리 일격 | Execute | 5308 | high |
| 34080 | 어드밴스드 파이널 어택 | 4차 passive | 도검 전문화 | Sword Specialization | 12281 | medium |
| 34050 | 리인카네이션 | 4차 passive | 최후의 저항 | Last Stand | 12975 | high |
| 34060 | 비홀더스 리벤지 | 4차 passive | 복수 | Revenge | 6572 | high |
| 34030 | 다크 레조넌스 | 4차 buff | 죽음의 소원 | Death Wish | 12328 | high |
| 34040 | 매직 크래쉬 | 4차 active | 자루 공격 | Pummel | 6552 | high |
| 34090 | 어드밴스드 웨폰 마스터리 | 4차 passive | 쌍수 무기 전문화 | Dual Wield Specialization | 23584 | medium |
| 34070 | 스탠스 | 4차 passive | 광폭 태세 | Berserker Stance | 2458 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 30010 | 슬래시 블러스트 - 피해 | 12 | 영웅의 일격 연마 1 | 12282 | high | talent |
| 30020 | 슬래시 블러스트 - 대상 | 15 | 영웅의 일격 연마 2 | 12282 | high | talent |
| 30030 | 슬래시 블러스트 - 피해 | 19 | 영웅의 일격 연마 3 | 12282 | high | talent |
| 30040 | 슬래시 블러스트 - 대상 | 22 | 영웅의 일격 연마 4 | 12282 | high | talentExtraRank |
| 30050 | 슬래시 블러스트 - 피해 | 26 | 영웅의 일격 연마 5 | 12282 | high | talentExtraRank |
| 30060 | 스피어 풀링 - 피해 | 32 | 회전베기 연마 1 | 12329 | high | talent |
| 30070 | 스피어 풀링 - 대상 | 37 | 회전베기 연마 2 | 12329 | high | talent |
| 30080 | 스피어 풀링 - 피해 | 42 | 회전베기 연마 3 | 12329 | high | talent |
| 30090 | 스피어 풀링 - 보스 몬스터 피해 | 47 | 회전베기 연마 4 | 12329 | high | talentExtraRank |
| 30100 | 스피어 풀링 - 피해 | 52 | 회전베기 연마 5 | 12329 | high | talentExtraRank |
| 30110 | 스피어 풀링 - 타격 | 56 | 회전베기 연마 6 | 12329 | high | talentExtraRank |
| 30120 | 라만차 스피어 - 피해 | 62 | 소용돌이 숙련 1 | 1680 | high | generated |
| 30130 | 라만차 스피어 - 피해 | 66 | 소용돌이 숙련 2 | 1680 | high | generated |
| 30140 | 라만차 스피어 - 보스 몬스터 피해 | 71 | 소용돌이 숙련 3 | 1680 | high | generated |
| 30150 | 라만차 스피어 - 피해 | 76 | 소용돌이 숙련 4 | 1680 | high | generated |
| 30160 | 라만차 스피어 - 피해 | 80 | 소용돌이 숙련 5 | 1680 | high | generated |
| 30170 | 라만차 스피어 - 보스 몬스터 피해 | 84 | 소용돌이 숙련 6 | 1680 | high | generated |
| 30180 | 라만차 스피어 - 피해 | 88 | 소용돌이 숙련 7 | 1680 | high | generated |
| 30190 | 라만차 스피어 - 피해 | 92 | 소용돌이 숙련 8 | 1680 | high | generated |
| 30200 | 라만차 스피어 - 타격 | 96 | 소용돌이 숙련 9 | 1680 | high | generated |
| 30210 | 다크 임페일 - 피해 | 102 | 피의 갈증 숙련 1 | 23881 | high | generated |
| 30220 | 다크 임페일 - 피해 | 106 | 피의 갈증 숙련 2 | 23881 | high | generated |
| 30230 | 다크 임페일 - 보스 몬스터 피해 | 111 | 피의 갈증 숙련 3 | 23881 | high | generated |
| 30240 | 다크 임페일 - 피해 | 116 | 피의 갈증 숙련 4 | 23881 | high | generated |
| 30250 | 다크 임페일 - 피해 | 120 | 피의 갈증 숙련 5 | 23881 | high | generated |
| 30260 | 다크 임페일 - 보스 몬스터 피해 | 124 | 피의 갈증 숙련 6 | 23881 | high | generated |
| 30270 | 다크 임페일 - 피해 | 128 | 피의 갈증 숙련 7 | 23881 | high | generated |
| 30280 | 다크 임페일 - 피해 | 132 | 피의 갈증 숙련 8 | 23881 | high | generated |
| 30290 | 다크 임페일 - 타격 | 136 | 피의 갈증 숙련 9 | 23881 | high | generated |
| 30015 | 주스탯 강화 | 14 | 광폭화 연마 | 20500 | medium | talent |
| 30025 | 크리티컬 확률 강화 | 17 | 장창 전문화 | 12165 | medium | talent |
| 30035 | 아이언 바디 - 방어력 | 21 | 강인함 숙련 | 12299 | medium | generated |
| 30045 | 워리어 마스터리 - 속도 | 24 | 전투 태세 숙련 | 2457 | high | generated |
| 30055 | 기본 공격 데미지 강화 | 28 | 양손 무기 전문화 | 12163 | high | talent |
| 30065 | 명중 강화 | 34 | 무력화 연마 | 12289 | medium | talent |
| 30075 | 비홀더 - 받는 피해 | 39 | 사기의 외침 연마 1 | 12324 | medium | talent |
| 30085 | 비홀더 쇼크 - 피해 | 44 | 위협의 외침 숙련 | 5246 | high | generated |
| 30095 | 하이퍼 바디 - 지속 | 49 | 전투의 외침 연마 | 12318 | medium | talent |
| 30105 | 파이널 어택 - 피해 | 54 | 주체할 수 없는 분노 숙련 | 12322 | high | generated |
| 30115 | 최대 데미지 배율 강화 | 58 | 꿰뚫기 | 16493 | high | talent |
| 30125 | 기본 공격 대상 수 강화 | 64 | 휩쓸기 일격 | 12292 | high | talent |
| 30135 | 돌진 - 피해 | 68 | 돌진 연마 1 | 12285 | high | talent |
| 30145 | 크로스 오버 체인 - 공격력 | 73 | 무모함 숙련 | 1719 | high | generated |
| 30155 | 비홀더 도미넌트 - 피해 | 78 | 깊은 상처 숙련 1 | 12162 | high | generated |
| 30165 | 비홀더스 버프 - 보스 몬스터 데미지 | 82 | 우렁찬 목소리 숙련 1 | 12321 | high | generated |
| 30175 | 스킬 데미지 강화 | 86 | 피의 광기 | 16487 | medium | talent |
| 30185 | 돌진 - 재사용 | 90 | 돌진 연마 2 | 12285 | high | talent |
| 30195 | 비홀더 도미넌트 - 대상 | 94 | 깊은 상처 숙련 2 | 12162 | high | generated |
| 30205 | 비홀더스 버프 - 공격력 | 98 | 우렁찬 목소리 숙련 2 | 12321 | high | generated |
| 30215 | 비홀더 - 재사용 | 104 | 사기의 외침 연마 2 | 12324 | medium | talent |
| 30225 | 궁니르 디센트 - 피해 | 108 | 마무리 일격 연마 1 | 20502 | medium | talent |
| 30235 | 어드밴스드 파이널 어택 - 강화 | 113 | 도검 전문화 숙련 | 12281 | medium | generated |
| 30245 | 리인카네이션 - 회복 | 118 | 최후의 저항 숙련 | 12975 | high | generated |
| 30255 | 비홀더스 리벤지 - 피해 | 122 | 복수 숙련 1 | 6572 | high | generated |
| 30265 | 매직 크래쉬 - 약화 | 126 | 자루 공격 숙련 | 6552 | high | generated |
| 30275 | 다크 레조넌스 - 지속 | 130 | 죽음의 소원 숙련 | 12328 | high | generated |
| 30285 | 궁니르 디센트 - 타격 | 134 | 마무리 일격 연마 2 | 20502 | medium | talent |
| 30295 | 비홀더스 리벤지 - 암흑 투기 | 138 | 복수 숙련 2 | 6572 | high | generated |

## 아크메이지(썬·콜) → 정기 주술사 (Elemental Shaman)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 41010 | 에너지 볼트 | 1차 BA | 번개 화살 | Lightning Bolt | 403 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 늑대 정령 | Ghost Wolf | 2645 | high |
| 41020 | 마나 웨이브 | 1차 passive | 수면 걷기 | Water Walking | 546 | high |
| 41040 | 텔레포트 | 1차 buff | 귀환 | Astral Recall | 556 | high |
| 41030 | 매직 가드 | 1차 buff | 돌가죽 토템 | Stoneskin Totem | 8071 | high |
| 42010 | 콜드 빔 | 2차 BA | 냉기 충격 | Frost Shock | 8056 | high |
| 42050 | 매직 액셀레이션 | 2차 passive | 질풍의 토템 | Windfury Totem | 8512 | high |
| 42020 | 프리징 이펙트 | 2차 passive | 냉기의 무기 | Frostbrand Weapon | 8033 | high |
| 42030 | 썬더 볼트 | 2차 active | 대지 충격 | Earth Shock | 8042 | high |
| 42040 | 메디테이션 | 2차 buff | 대지력 토템 | Strength of Earth Totem | 8075 | high |
| 42060 | 스펠 마스터리 | 2차 passive | 진탕 | Concussion | 16035 | high |
| 42080 | MP 이터 | 2차 passive | 마나샘 토템 | Mana Spring Totem | 5675 | high |
| 42070 | 하이 위즈덤 | 2차 passive | 천둥의 부름 | Call of Thunder | 16041 | high |
| 43010 | 아이스 스트라이크 | 3차 BA | 화염 충격 | Flame Shock | 8050 | high |
| 43040 | 엘리멘탈 어댑팅 | 3차 passive | 진동의 토템 | Tremor Totem | 8143 | high |
| 43020 | 글레이셜 월 | 3차 active | 속박의 토템 | Earthbind Totem | 2484 | high |
| 43050 | 프로즌 브레이크 | 3차 passive | 원소의 수호 | Elemental Warding | 28996 | medium |
| 43030 | 썬더 스피어 | 3차 active | 번개 보호막 | Lightning Shield | 324 | high |
| 43060 | 엘리멘탈 리셋 | 3차 passive | 정기의 집중 | Elemental Focus | 16164 | high |
| 43070 | 매직 크리티컬 | 3차 passive | 정기의 격노 | Elemental Fury | 16089 | high |
| 43080 | 엘리먼트 앰플리피케이션 | 3차 passive | 전도 | Convection | 16039 | high |
| 44010 | 체인 라이트닝 | 4차 BA | 연쇄 번개 | Chain Lightning | 421 | high |
| 44100 | 메이플 용사 | 4차 passive | 폭풍의 손길 | Storm Reach | 28999 | medium |
| 44020 | 프리징 브레스 | 4차 active | 용암 토템 | Magma Totem | 8190 | high |
| 44030 | 블리자드 | 4차 active | 불꽃 회오리 토템 | Fire Nova Totem | 1535 | high |
| 44040 | 프로즌 오브 | 4차 active | 불타는 토템 | Searing Totem | 3599 | high |
| 44050 | 인피니티 | 4차 buff | 정기의 숙련 | Elemental Mastery | 16166 | high |
| 44060 | 엘퀴네스 | 4차 active | 마나 해일 토템 | Mana Tide Totem | 16190 | high |
| 44070 | 마스터 매직 | 4차 passive | 토템 숙련 | Totemic Mastery | 16189 | medium |
| 44080 | 아케인 에임 | 4차 passive | 정기의 황폐 | Elemental Devastation | 30160 | medium |
| 44090 | 프로스트 이펙트 | 4차 passive | 울림 | Reverberation | 16040 | medium |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 40010 | 에너지 볼트 - 피해 | 12 | 번개 숙련 1 | 16578 | medium | talent |
| 40020 | 에너지 볼트 - 대상 | 15 | 번개 숙련 2 | 16578 | medium | talent |
| 40030 | 에너지 볼트 - 피해 | 19 | 번개 숙련 3 | 16578 | medium | talent |
| 40040 | 에너지 볼트 - 대상 | 22 | 번개 숙련 4 | 16578 | medium | talent |
| 40050 | 에너지 볼트 - 피해 | 26 | 번개 숙련 5 | 16578 | medium | talent |
| 40060 | 콜드 빔 - 피해 | 32 | 냉기 충격 숙련 1 | 8056 | high | generated |
| 40070 | 콜드 빔 - 대상 | 37 | 냉기 충격 숙련 2 | 8056 | high | generated |
| 40080 | 콜드 빔 - 피해 | 42 | 냉기 충격 숙련 3 | 8056 | high | generated |
| 40090 | 콜드 빔 - 보스 몬스터 피해 | 47 | 냉기 충격 숙련 4 | 8056 | high | generated |
| 40100 | 콜드 빔 - 피해 | 52 | 냉기 충격 숙련 5 | 8056 | high | generated |
| 40110 | 콜드 빔 - 타격 | 56 | 냉기 충격 숙련 6 | 8056 | high | generated |
| 40120 | 아이스 스트라이크 - 피해 | 62 | 화염 충격 숙련 1 | 8050 | high | generated |
| 40130 | 아이스 스트라이크 - 피해 | 66 | 화염 충격 숙련 2 | 8050 | high | generated |
| 40140 | 아이스 스트라이크 - 보스 몬스터 피해 | 71 | 화염 충격 숙련 3 | 8050 | high | generated |
| 40150 | 아이스 스트라이크 - 피해 | 76 | 화염 충격 숙련 4 | 8050 | high | generated |
| 40160 | 아이스 스트라이크 - 피해 | 80 | 화염 충격 숙련 5 | 8050 | high | generated |
| 40170 | 아이스 스트라이크 - 보스 몬스터 피해 | 84 | 화염 충격 숙련 6 | 8050 | high | generated |
| 40180 | 아이스 스트라이크 - 피해 | 88 | 화염 충격 숙련 7 | 8050 | high | generated |
| 40190 | 아이스 스트라이크 - 피해 | 92 | 화염 충격 숙련 8 | 8050 | high | generated |
| 40200 | 아이스 스트라이크 - 타격 | 96 | 화염 충격 숙련 9 | 8050 | high | generated |
| 40210 | 체인 라이트닝 - 피해 | 102 | 연쇄 번개 숙련 1 | 421 | high | generated |
| 40220 | 체인 라이트닝 - 피해 | 106 | 연쇄 번개 숙련 2 | 421 | high | generated |
| 40230 | 체인 라이트닝 - 보스 몬스터 피해 | 111 | 연쇄 번개 숙련 3 | 421 | high | generated |
| 40240 | 체인 라이트닝 - 피해 | 116 | 연쇄 번개 숙련 4 | 421 | high | generated |
| 40250 | 체인 라이트닝 - 피해 | 120 | 연쇄 번개 숙련 5 | 421 | high | generated |
| 40260 | 체인 라이트닝 - 보스 몬스터 피해 | 124 | 연쇄 번개 숙련 6 | 421 | high | generated |
| 40270 | 체인 라이트닝 - 피해 | 128 | 연쇄 번개 숙련 7 | 421 | high | generated |
| 40280 | 체인 라이트닝 - 피해 | 132 | 연쇄 번개 숙련 8 | 421 | high | generated |
| 40290 | 체인 라이트닝 - 타격 | 136 | 연쇄 번개 숙련 9 | 421 | high | generated |
| 40015 | 주스탯 강화 | 14 | 선조의 지혜 | 17485 | medium | talent |
| 40025 | 크리티컬 확률 강화 | 17 | 천둥의 일격 | 16255 | medium | talent |
| 40035 | 매직 가드 - 재사용 | 21 | 수호의 토템 | 16258 | medium | talent |
| 40045 | 텔레포트 - 재사용 | 24 | 귀환 숙련 | 556 | high | generated |
| 40055 | 기본 공격 데미지 강화 | 28 | 화염의 부름 | 16038 | medium | talent |
| 40065 | 명중 강화 | 34 | 자연의 인도 | 16180 | medium | talent |
| 40075 | 썬더 볼트 - 피해 | 39 | 대지 충격 숙련 | 8042 | high | generated |
| 40085 | 메디테이션 - 지속 | 44 | 토템 강화 | 16259 | medium | talent |
| 40095 | MP 이터 - MP 부스트 | 49 | 회복의 토템 | 16187 | medium | talent |
| 40105 | 프리징 이펙트 - 오라 | 54 | 냉기의 무기 숙련 | 8033 | high | generated |
| 40115 | 최대 데미지 배율 강화 | 58 | 폭풍의 눈 | 29062 | medium | talent |
| 40125 | 기본 공격 대상 수 강화 | 64 | 번개 보호막 연마 | 16261 | medium | talent |
| 40135 | 글레이셜 월 - 피해 | 68 | 대지의 손아귀 1 | 16043 | medium | talent |
| 40145 | 썬더 스피어 - 피해 | 73 | 번개 보호막 숙련 1 | 324 | high | generated |
| 40155 | 썬더 스피어 - 재사용 | 78 | 번개 보호막 숙련 2 | 324 | high | generated |
| 40165 | 엘리멘탈 리셋 - 확률 | 82 | 정기의 집중 숙련 | 16164 | high | generated |
| 40175 | 스킬 데미지 강화 | 86 | 해일 숙련 | 16194 | medium | talent |
| 40185 | 글레이셜 월 - 재사용 | 90 | 대지의 손아귀 2 | 16043 | medium | talent |
| 40195 | 썬더 스피어 - 일반 몬스터 피해 | 94 | 번개 보호막 숙련 3 | 324 | high | generated |
| 40205 | 프로즌 브레이크 - 피해 | 98 | 원소의 수호 숙련 | 28996 | medium | generated |
| 40215 | 썬더 스피어 - 타격 주기 | 104 | 번개 보호막 숙련 4 | 324 | high | generated |
| 40225 | 프리징 브레스 - 피해 | 108 | 화염 토템 연마 1 | 16086 | medium | talent |
| 40235 | 블리자드 - 파이널 어택 | 113 | 화염 토템 연마 2 | 16086 | medium | talent |
| 40245 | 프리징 브레스 - 약화 | 118 | 화염 토템 연마 3 | 16086 | medium | talentExtraRank |
| 40255 | 프로즌 오브 - 피해 | 122 | 불타는 토템 숙련 1 | 3599 | high | generated |
| 40265 | 프로즌 오브 - 타격 주기 | 126 | 불타는 토템 숙련 2 | 3599 | high | generated |
| 40275 | 엘퀴네스 - 타격 주기 | 130 | 마나 해일 토템 숙련 1 | 16190 | high | generated |
| 40285 | 블리자드 - 피해 | 134 | 화염 토템 연마 4 | 16086 | medium | talentExtraRank |
| 40295 | 엘퀴네스 - 피해 & 대상 | 138 | 마나 해일 토템 숙련 2 | 16190 | high | generated |

## 아크메이지(불·독) → 파괴 흑마법사 (Destruction Warlock)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 51010 | 에너지 볼트 | 1차 BA | 어둠의 화살 | Shadow Bolt | 686 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 지옥마 소환 | Summon Felsteed | 5784 | high |
| 51020 | 마나 웨이브 | 1차 passive | 공포마 소환 | Summon Dreadsteed | 23161 | high |
| 51040 | 텔레포트 | 1차 buff | 소환 의식 | Ritual of Summoning | 698 | high |
| 51030 | 매직 가드 | 1차 buff | 악마의 갑옷 | Demon Armor | 706 | high |
| 52010 | 플레임 오브 | 2차 BA | 불타는 고통 | Searing Pain | 5676 | high |
| 52050 | 매직 액셀레이션 | 2차 passive | 파멸 | Bane | 17788 | high |
| 52060 | 이그나이트 | 2차 passive | 화염 분출 | Pyroclasm | 18096 | medium |
| 52030 | 포이즌 브레스 | 2차 active | 고통의 저주 | Curse of Agony | 980 | high |
| 52040 | 메디테이션 | 2차 buff | 원소의 저주 | Curse of the Elements | 1490 | high |
| 52070 | 스펠 마스터리 | 2차 passive | 강렬함 | Intensity | 18135 | medium |
| 52080 | MP 이터 | 2차 passive | 생명력 전환 | Life Tap | 1454 | high |
| 52020 | 엘리멘탈 드레인 | 2차 passive | 생명력 착취 | Siphon Life | 18265 | high |
| 53010 | 익스플로젼 | 3차 BA | 영혼의 불꽃 | Soul Fire | 6353 | high |
| 53040 | 엘리멘탈 어댑팅 | 3차 passive | 어둠의 수호물 | Shadow Ward | 6229 | high |
| 53020 | 포이즌 미스트 | 3차 active | 부패 | Corruption | 172 | high |
| 53050 | 익스트림 매직 | 3차 passive | 어둠의 숙련 | Shadow Mastery | 18271 | medium |
| 53030 | 포이즌 리젼 | 3차 active | 점화 | Conflagrate | 17962 | high |
| 53060 | 엘리멘탈 리셋 | 3차 passive | 어둠의 저주 | Curse of Shadow | 17862 | high |
| 53070 | 매직 크리티컬 | 3차 passive | 황폐 | Devastation | 18130 | high |
| 53080 | 엘리먼트 앰플리피케이션 | 3차 passive | 격변 | Cataclysm | 17778 | high |
| 54010 | 플레임 스윕 | 4차 BA | 지옥의 불길 | Hellfire | 1949 | high |
| 54100 | 메이플 용사 | 4차 passive | 파멸의 화염 | Ruin | 17959 | high |
| 54020 | 미스트 이럽션 | 4차 passive | 어둠의 연소 | Shadowburn | 17877 | high |
| 54030 | 메테오 | 4차 active | 불의 비 | Rain of Fire | 5740 | high |
| 54040 | 플레임 헤이즈 | 4차 active | 제물 | Immolate | 348 | high |
| 54050 | 인피니티 | 4차 buff | 악마의 희생 | Demonic Sacrifice | 18788 | high |
| 54060 | 이프리트 | 4차 active | 지옥불정령 | Inferno | 1122 | high |
| 54070 | 마스터 매직 | 4차 passive | 파괴의 범위 | Destructive Reach | 17917 | medium |
| 54080 | 아케인 에임 | 4차 passive | 일몰 | Nightfall | 18094 | medium |
| 54090 | 퍼번트 드레인 | 4차 passive | 불씨 폭풍 | Emberstorm | 17954 | medium |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 50010 | 에너지 볼트 - 피해 | 12 | 어둠의 화살 연마 1 | 17793 | high | talent |
| 50020 | 에너지 볼트 - 대상 | 15 | 어둠의 화살 연마 2 | 17793 | high | talent |
| 50030 | 에너지 볼트 - 피해 | 19 | 어둠의 화살 연마 3 | 17793 | high | talent |
| 50040 | 에너지 볼트 - 대상 | 22 | 어둠의 화살 연마 4 | 17793 | high | talent |
| 50050 | 에너지 볼트 - 피해 | 26 | 어둠의 화살 연마 5 | 17793 | high | talent |
| 50060 | 플레임 오브 - 피해 | 32 | 불타는 고통 연마 1 | 17927 | medium | talent |
| 50070 | 플레임 오브 - 대상 | 37 | 불타는 고통 연마 2 | 17927 | medium | talent |
| 50080 | 플레임 오브 - 피해 | 42 | 불타는 고통 연마 3 | 17927 | medium | talent |
| 50090 | 플레임 오브 - 보스 몬스터 피해 | 47 | 불타는 고통 연마 4 | 17927 | medium | talent |
| 50100 | 플레임 오브 - 피해 | 52 | 불타는 고통 연마 5 | 17927 | medium | talent |
| 50110 | 플레임 오브 - 타격 | 56 | 불타는 고통 연마 6 | 17927 | medium | talentExtraRank |
| 50120 | 익스플로젼 - 피해 | 62 | 영혼의 불꽃 숙련 1 | 6353 | high | generated |
| 50130 | 익스플로젼 - 피해 | 66 | 영혼의 불꽃 숙련 2 | 6353 | high | generated |
| 50140 | 익스플로젼 - 보스 몬스터 피해 | 71 | 영혼의 불꽃 숙련 3 | 6353 | high | generated |
| 50150 | 익스플로젼 - 피해 | 76 | 영혼의 불꽃 숙련 4 | 6353 | high | generated |
| 50160 | 익스플로젼 - 피해 | 80 | 영혼의 불꽃 숙련 5 | 6353 | high | generated |
| 50170 | 익스플로젼 - 보스 몬스터 피해 | 84 | 영혼의 불꽃 숙련 6 | 6353 | high | generated |
| 50180 | 익스플로젼 - 피해 | 88 | 영혼의 불꽃 숙련 7 | 6353 | high | generated |
| 50190 | 익스플로젼 - 피해 | 92 | 영혼의 불꽃 숙련 8 | 6353 | high | generated |
| 50200 | 익스플로젼 - 타격 | 96 | 영혼의 불꽃 숙련 9 | 6353 | high | generated |
| 50210 | 플레임 스윕 - 피해 | 102 | 지옥의 불길 숙련 1 | 1949 | high | generated |
| 50220 | 플레임 스윕 - 피해 | 106 | 지옥의 불길 숙련 2 | 1949 | high | generated |
| 50230 | 플레임 스윕 - 보스 몬스터 피해 | 111 | 지옥의 불길 숙련 3 | 1949 | high | generated |
| 50240 | 플레임 스윕 - 피해 | 116 | 지옥의 불길 숙련 4 | 1949 | high | generated |
| 50250 | 플레임 스윕 - 피해 | 120 | 지옥의 불길 숙련 5 | 1949 | high | generated |
| 50260 | 플레임 스윕 - 보스 몬스터 피해 | 124 | 지옥의 불길 숙련 6 | 1949 | high | generated |
| 50270 | 플레임 스윕 - 피해 | 128 | 지옥의 불길 숙련 7 | 1949 | high | generated |
| 50280 | 플레임 스윕 - 피해 | 132 | 지옥의 불길 숙련 8 | 1949 | high | generated |
| 50290 | 플레임 스윕 - 타격 | 136 | 지옥의 불길 숙련 9 | 1949 | high | generated |
| 50015 | 주스탯 강화 | 14 | 지옥 지능 | 18731 | medium | talent |
| 50025 | 크리티컬 확률 강화 | 17 | 여파 | 18119 | medium | talent |
| 50035 | 매직 가드 - 재사용 | 21 | 악마의 갑옷 숙련 | 706 | high | generated |
| 50045 | 텔레포트 - 재사용 | 24 | 소환 의식 숙련 | 698 | high | generated |
| 50055 | 기본 공격 데미지 강화 | 28 | 화염 화살 연마 | 18126 | medium | talent |
| 50065 | 명중 강화 | 34 | 억제 | 18174 | medium | talent |
| 50075 | 포이즌 브레스 - 피해 | 39 | 고통의 저주 연마 | 18827 | medium | talent |
| 50085 | 메디테이션 - 지속 | 44 | 원소의 저주 숙련 | 1490 | high | generated |
| 50095 | MP 이터 - MP 부스트 | 49 | 생명력 전환 연마 | 18182 | medium | talent |
| 50105 | 이그나이트 - 피해 | 54 | 화염 분출 숙련 | 18096 | medium | generated |
| 50115 | 최대 데미지 배율 강화 | 58 | 섬뜩한 손길 | 18218 | medium | talent |
| 50125 | 기본 공격 대상 수 강화 | 64 | 저주 증폭 | 18288 | medium | talent |
| 50135 | 포이즌 미스트 - 피해 | 68 | 부패 연마 1 | 17810 | high | talent |
| 50145 | 포이즌 리젼 - 중독 | 73 | 점화 숙련 1 | 17962 | high | generated |
| 50155 | 포이즌 리젼 - 피해 | 78 | 점화 숙련 2 | 17962 | high | generated |
| 50165 | 엘리멘탈 리셋 - 확률 | 82 | 어둠의 저주 숙련 | 17862 | high | generated |
| 50175 | 스킬 데미지 강화 | 86 | 부정의 힘 | 18769 | medium | talent |
| 50185 | 포이즌 미스트 - 재사용 | 90 | 부패 연마 2 | 17810 | high | talent |
| 50195 | 포이즌 리젼 - 일반 몬스터 피해 | 94 | 점화 숙련 3 | 17962 | high | generated |
| 50205 | 익스트림 매직 - 피해 | 98 | 어둠의 숙련 숙련 | 18271 | medium | generated |
| 50215 | 포이즌 미스트 - 타격 주기 | 104 | 부패 연마 3 | 17810 | high | talent |
| 50225 | 미스트 이럽션 - 폭발 | 108 | 어둠의 연소 숙련 1 | 17877 | high | generated |
| 50235 | 메테오 - 파이널 어택 | 113 | 불의 비 숙련 1 | 5740 | high | generated |
| 50245 | 플레임 헤이즈 - 독 안개 | 118 | 제물 연마 1 | 17815 | high | talent |
| 50255 | 미스트 이럽션 - 피해 | 122 | 어둠의 연소 숙련 2 | 17877 | high | generated |
| 50265 | 플레임 헤이즈 - 화상 | 126 | 제물 연마 2 | 17815 | high | talent |
| 50275 | 이프리트 - 피해 | 130 | 지옥불정령 숙련 1 | 1122 | high | generated |
| 50285 | 메테오 - 피해 | 134 | 불의 비 숙련 2 | 5740 | high | generated |
| 50295 | 이프리트 - 지속 & 대상 | 138 | 지옥불정령 숙련 2 | 1122 | high | generated |

## 비숍 → 신성 사제 (Holy Priest)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 61010 | 에너지 볼트 | 1차 BA | 성스러운 일격 | Smite | 585 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 내면의 집중 | Inner Focus | 14751 | high |
| 61020 | 마나 웨이브 | 1차 passive | 공중 부양 | Levitate | 1706 | high |
| 61040 | 텔레포트 | 1차 buff | 소실 | Fade | 586 | high |
| 61030 | 매직 가드 | 1차 buff | 내면의 열정 | Inner Fire | 588 | high |
| 62010 | 홀리 애로우 | 2차 BA | 신성한 불꽃 | Holy Fire | 14914 | high |
| 62040 | 매직 액셀레이션 | 2차 passive | 신성한 격노 | Divine Fury | 18530 | medium |
| 62020 | 힐 | 2차 buff | 소생 | Renew | 139 | high |
| 62060 | 인빈서블 | 2차 passive | 내면의 열정 연마 | Improved Inner Fire | 14747 | medium |
| 62030 | 블레스 | 2차 buff | 신의 권능: 인내 | Power Word: Fortitude | 1243 | high |
| 62070 | 스펠 마스터리 | 2차 passive | 치유 집중 | Healing Focus | 14913 | medium |
| 62080 | MP이터 | 2차 passive | 명상 | Meditation | 14521 | medium |
| 62050 | 하이 위즈덤 | 2차 passive | 신성 전문화 | Holy Specialization | 14889 | medium |
| 63010 | 샤이닝 레이 | 3차 BA | 정신 분열 | Mind Blast | 8092 | high |
| 63040 | 디바인 프로텍션 | 3차 passive | 신의 권능: 보호막 | Power Word: Shield | 17 | high |
| 63050 | 트라이엄프 페더 | 3차 passive | 축복받은 회복 | Blessed Recovery | 27811 | medium |
| 63020 | 홀리 파운틴 | 3차 buff | 빛샘 | Lightwell | 724 | high |
| 63030 | 홀리 매직 쉘 | 3차 buff | 영감 | Inspiration | 14892 | high |
| 63060 | 홀리 심볼 | 3차 passive | 공포의 수호물 | Fear Ward | 6346 | high |
| 63070 | 매직 크리티컬 | 3차 passive | 타오르는 빛 | Searing Light | 14909 | medium |
| 63080 | 엘리먼트 앰플리피케이션 | 3차 passive | 영적 인도 | Spiritual Guidance | 14901 | medium |
| 64010 | 빅뱅 | 4차 BA | 신성한 폭발 | Holy Nova | 15237 | high |
| 64100 | 메이플 용사 | 4차 passive | 의지력 | Force of Will | 18544 | medium |
| 64020 | 엔젤레이 | 4차 active | 별조각 | Starshards | 10797 | high |
| 64030 | 제네시스 | 4차 active | 치유의 기원 | Prayer of Healing | 596 | high |
| 64040 | 어드밴스드 블레스 | 4차 buff | 천상의 정신 | Divine Spirit | 14752 | high |
| 64050 | 인피니티 | 4차 buff | 마력 주입 | Power Infusion | 10060 | high |
| 64060 | 바하뮤트 | 4차 active | 구원의 영혼 | Spirit of Redemption | 20711 | high |
| 64070 | 마스터 매직 | 4차 passive | 신의 권능: 인내 연마 | Improved Power Word: Fortitude | 14749 | medium |
| 64080 | 아케인 에임 | 4차 passive | 신성의 손길 | Holy Reach | 27789 | medium |
| 64090 | 홀리 블러드 | 4차 passive | 영적 치유 | Spiritual Healing | 14898 | medium |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 60010 | 에너지 볼트 - 피해 | 12 | 성스러운 일격 숙련 1 | 585 | high | generated |
| 60020 | 에너지 볼트 - 대상 | 15 | 성스러운 일격 숙련 2 | 585 | high | generated |
| 60030 | 에너지 볼트 - 피해 | 19 | 성스러운 일격 숙련 3 | 585 | high | generated |
| 60040 | 에너지 볼트 - 대상 | 22 | 성스러운 일격 숙련 4 | 585 | high | generated |
| 60050 | 에너지 볼트 - 피해 | 26 | 성스러운 일격 숙련 5 | 585 | high | generated |
| 60060 | 홀리 애로우 - 피해 | 32 | 신성한 불꽃 숙련 1 | 14914 | high | generated |
| 60070 | 홀리 애로우 - 대상 | 37 | 신성한 불꽃 숙련 2 | 14914 | high | generated |
| 60080 | 홀리 애로우 - 피해 | 42 | 신성한 불꽃 숙련 3 | 14914 | high | generated |
| 60090 | 홀리 애로우 - 보스 몬스터 피해 | 47 | 신성한 불꽃 숙련 4 | 14914 | high | generated |
| 60100 | 홀리 애로우 - 피해 | 52 | 신성한 불꽃 숙련 5 | 14914 | high | generated |
| 60110 | 홀리 애로우 - 타격 | 56 | 신성한 불꽃 숙련 6 | 14914 | high | generated |
| 60120 | 샤이닝 레이 - 피해 | 62 | 정신 분열 연마 1 | 15273 | high | talent |
| 60130 | 샤이닝 레이 - 피해 | 66 | 정신 분열 연마 2 | 15273 | high | talent |
| 60140 | 샤이닝 레이 - 보스 몬스터 피해 | 71 | 정신 분열 연마 3 | 15273 | high | talent |
| 60150 | 샤이닝 레이 - 피해 | 76 | 정신 분열 연마 4 | 15273 | high | talent |
| 60160 | 샤이닝 레이 - 피해 | 80 | 정신 분열 연마 5 | 15273 | high | talent |
| 60170 | 샤이닝 레이 - 보스 몬스터 피해 | 84 | 정신 분열 연마 6 | 15273 | high | talentExtraRank |
| 60180 | 샤이닝 레이 - 피해 | 88 | 정신 분열 연마 7 | 15273 | high | talentExtraRank |
| 60190 | 샤이닝 레이 - 피해 | 92 | 정신 분열 연마 8 | 15273 | high | talentExtraRank |
| 60200 | 샤이닝 레이 - 타격 | 96 | 정신 분열 연마 9 | 15273 | high | talentExtraRank |
| 60210 | 빅뱅 - 피해 | 102 | 신성한 폭발 숙련 1 | 15237 | high | generated |
| 60220 | 빅뱅 - 피해 | 106 | 신성한 폭발 숙련 2 | 15237 | high | generated |
| 60230 | 빅뱅 - 보스 몬스터 피해 | 111 | 신성한 폭발 숙련 3 | 15237 | high | generated |
| 60240 | 빅뱅 - 피해 | 116 | 신성한 폭발 숙련 4 | 15237 | high | generated |
| 60250 | 빅뱅 - 피해 | 120 | 신성한 폭발 숙련 5 | 15237 | high | generated |
| 60260 | 빅뱅 - 보스 몬스터 피해 | 124 | 신성한 폭발 숙련 6 | 15237 | high | generated |
| 60270 | 빅뱅 - 피해 | 128 | 신성한 폭발 숙련 7 | 15237 | high | generated |
| 60280 | 빅뱅 - 피해 | 132 | 신성한 폭발 숙련 8 | 15237 | high | generated |
| 60290 | 빅뱅 - 타격 | 136 | 신성한 폭발 숙련 9 | 15237 | high | generated |
| 60015 | 주스탯 강화 | 14 | 정신력 | 18551 | medium | talent |
| 60025 | 크리티컬 확률 강화 | 17 | 순교 | 14531 | medium | talent |
| 60035 | 매직 가드 - 재사용 | 21 | 내면의 열정 숙련 | 588 | high | generated |
| 60045 | 텔레포트 - 재사용 | 24 | 소실 숙련 | 586 | high | generated |
| 60055 | 기본 공격 데미지 강화 | 28 | 마법봉 전문화 | 14524 | medium | talent |
| 60065 | 명중 강화 | 34 | 꺾이지 않는 의지 | 14522 | medium | talent |
| 60075 | 힐 - 지속 | 39 | 소생 연마 1 | 14908 | high | talent |
| 60085 | 블레스 - 지속 | 44 | 신의 권능: 인내 숙련 | 1243 | high | generated |
| 60095 | MP 이터 - MP 부스트 | 49 | 명상 숙련 | 14521 | medium | generated |
| 60105 | 힐 - 공격력 | 54 | 소생 연마 2 | 14908 | high | talent |
| 60115 | 최대 데미지 배율 강화 | 58 | 치유 연마 | 14912 | medium | talent |
| 60125 | 기본 공격 대상 수 강화 | 64 | 치유의 기원 연마 | 14911 | medium | talent |
| 60135 | 홀리 파운틴 - 보스 몬스터 데미지 | 68 | 빛샘 숙련 | 724 | high | generated |
| 60145 | 트라이엄프 페더 - 피해 | 73 | 영감 1 | 14892 | high | talent |
| 60155 | 트라이엄프 페더 - 확률 | 78 | 영감 2 | 14892 | high | talent |
| 60165 | 홀리 매직쉘 - 정화 | 82 | 영감 숙련 | 14892 | high | generated |
| 60175 | 스킬 데미지 강화 | 86 | 정신 민첩성 | 14520 | medium | talent |
| 60185 | 홀리 심볼 - 데미지 | 90 | 공포의 수호물 숙련 1 | 6346 | high | generated |
| 60195 | 트라이엄프 페더 - 강림 | 94 | 영감 3 | 14892 | high | talent |
| 60205 | 홀리 심볼 - 지속 | 98 | 공포의 수호물 숙련 2 | 6346 | high | generated |
| 60215 | 트라이엄프 페더 - 타격 | 104 | 영감 4 | 14892 | high | talentExtraRank |
| 60225 | 엔젤레이 - 피해 | 108 | 별조각 숙련 1 | 10797 | high | generated |
| 60235 | 어드밴스드 블레스 - 최종 데미지 | 113 | 천상의 정신 숙련 | 14752 | high | generated |
| 60245 | 제네시스 - 피해 | 118 | 치유의 기원 숙련 1 | 596 | high | generated |
| 60255 | 엔젤레이 - 보스 몬스터 피해 | 122 | 별조각 숙련 2 | 10797 | high | generated |
| 60265 | 제네시스 - 재사용 | 126 | 치유의 기원 숙련 2 | 596 | high | generated |
| 60275 | 바하뮤트 - 피해 & 대상 | 130 | 구원의 영혼 숙련 1 | 20711 | high | generated |
| 60285 | 홀리 블러드 - 공격 속도 | 134 | 영적 치유 숙련 | 14898 | medium | generated |
| 60295 | 바하뮤트 - 재사용 | 138 | 구원의 영혼 숙련 2 | 20711 | high | generated |

## 보우마스터 → 냉기 마법사 (Frost Mage)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 71010 | 애로우 블로우 | 1차 BA | 얼음 화살 | Frostbolt | 116 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 점멸 | Blink | 1953 | high |
| 71020 | 더블 점프 | 1차 passive | 저속 낙하 | Slow Fall | 130 | high |
| 71040 | 아처 마스터리 | 1차 passive | 서리 갑옷 | Frost Armor | 168 | high |
| 71030 | 크리티컬 샷 | 1차 passive | 산산조각 | Shatter | 11170 | high |
| 72010 | 바람의 시 | 2차 BA | 냉기 돌풍 | Cone of Cold | 120 | high |
| 72040 | 보우 액셀레이션 | 2차 passive | 냉정 | Presence of Mind | 12043 | high |
| 72020 | 리트리트 샷 | 2차 active | 얼음 회오리 | Frost Nova | 122 | high |
| 72080 | 피지컬 트레이닝 | 2차 passive | 얼음 파편 | Ice Shards | 11207 | high |
| 72030 | 퀴버 카트리지 | 2차 passive | 혹한의 추위 | Winter's Chill | 11180 | high |
| 72060 | 보우 마스터리 | 2차 passive | 원소 정밀성 | Elemental Precision | 29438 | medium |
| 72050 | 소울 애로우 : 활 | 2차 passive | 신비한 정신 | Arcane Mind | 11232 | high |
| 72070 | 파이널 어택 : 활 | 2차 passive | 동상 | Frostbite | 11071 | high |
| 73010 | 바람의 시 II | 3차 BA | 신비한 폭발 | Arcane Explosion | 1449 | high |
| 73020 | 플레시 미라주 | 3차 passive | 신비한 집중 | Arcane Concentration | 11213 | high |
| 73040 | 애로우 플래터 | 3차 active | 불기둥 | Flamestrike | 2120 | high |
| 73070 | 컨센트레이션 | 3차 passive | 신비한 집중력 | Arcane Focus | 11222 | medium |
| 73030 | 피닉스 | 3차 active | 화염구 | Fireball | 133 | high |
| 73060 | 모탈 블로우 | 3차 passive | 냉기 계열 초기화 | Cold Snap | 12472 | high |
| 73080 | 마크맨쉽 | 3차 passive | 냉기 집중 | Frost Channeling | 11160 | high |
| 73050 | 익스트림 아쳐리 : 활 | 3차 passive | 신비의 마법 강화 | Arcane Power | 12042 | high |
| 74010 | 언카운터블 애로우 | 4차 BA | 신비한 화살 | Arcane Missiles | 5143 | high |
| 74100 | 메이플 용사 | 4차 passive | 신비한 지능 | Arcane Intellect | 1459 | high |
| 74020 | 폭풍의 시 | 4차 active | 눈보라 | Blizzard | 10 | high |
| 74080 | 어드밴스드 파이널 어택 | 4차 passive | 영구 동토 | Permafrost | 11175 | high |
| 74050 | 어드밴스드 퀴버 | 4차 passive | 극지의 손길 | Arctic Reach | 16757 | medium |
| 74040 | 플레시 미라주 II | 4차 passive | 신비한 불안정 | Arcane Instability | 15058 | high |
| 74030 | 샤프 아이즈 | 4차 buff | 마법 증폭 | Amplify Magic | 1008 | high |
| 74070 | 일루전 스탭 | 4차 passive | 얼음 보호막 | Ice Barrier | 11426 | high |
| 74060 | 보우 엑스퍼트 | 4차 passive | 냉기 수호 | Frost Warding | 11189 | high |
| 74090 | 아머 피어싱 | 4차 passive | 얼음 관통 | Piercing Ice | 11151 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 70010 | 애로우 블로우 - 피해 | 12 | 얼음 화살 연마 1 | 11070 | high | talent |
| 70020 | 애로우 블로우 - 대상 | 15 | 얼음 화살 연마 2 | 11070 | high | talent |
| 70030 | 애로우 블로우 - 피해 | 19 | 얼음 화살 연마 3 | 11070 | high | talent |
| 70040 | 애로우 블로우 - 대상 | 22 | 얼음 화살 연마 4 | 11070 | high | talent |
| 70050 | 애로우 블로우 - 피해 | 26 | 얼음 화살 연마 5 | 11070 | high | talent |
| 70060 | 바람의 시 - 피해 | 32 | 냉기 돌풍 연마 1 | 11190 | high | talent |
| 70070 | 바람의 시 - 대상 | 37 | 냉기 돌풍 연마 2 | 11190 | high | talent |
| 70080 | 바람의 시 - 피해 | 42 | 냉기 돌풍 연마 3 | 11190 | high | talent |
| 70090 | 바람의 시 - 보스 몬스터 피해 | 47 | 냉기 돌풍 연마 4 | 11190 | high | talentExtraRank |
| 70100 | 바람의 시 - 피해 | 52 | 냉기 돌풍 연마 5 | 11190 | high | talentExtraRank |
| 70110 | 바람의 시 - 타격 | 56 | 냉기 돌풍 연마 6 | 11190 | high | talentExtraRank |
| 70120 | 바람의 시 II - 피해 | 62 | 신비한 폭발 연마 1 | 11242 | medium | talent |
| 70130 | 바람의 시 II - 피해 | 66 | 신비한 폭발 연마 2 | 11242 | medium | talent |
| 70140 | 바람의 시 II - 보스 몬스터 피해 | 71 | 신비한 폭발 연마 3 | 11242 | medium | talent |
| 70150 | 바람의 시 II - 피해 | 76 | 신비한 폭발 연마 4 | 11242 | medium | talentExtraRank |
| 70160 | 바람의 시 II - 피해 | 80 | 신비한 폭발 연마 5 | 11242 | medium | talentExtraRank |
| 70170 | 바람의 시 II - 보스 몬스터 피해 | 84 | 신비한 폭발 연마 6 | 11242 | medium | talentExtraRank |
| 70180 | 바람의 시 II - 피해 | 88 | 신비한 폭발 연마 7 | 11242 | medium | talentExtraRank |
| 70190 | 바람의 시 II - 피해 | 92 | 신비한 폭발 연마 8 | 11242 | medium | talentExtraRank |
| 70200 | 바람의 시 II - 타격 | 96 | 신비한 폭발 연마 9 | 11242 | medium | talentExtraRank |
| 70210 | 언카운터블 애로우 - 피해 | 102 | 신비한 화살 연마 1 | 11237 | medium | talent |
| 70220 | 언카운터블 애로우 - 피해 | 106 | 신비한 화살 연마 2 | 11237 | medium | talent |
| 70230 | 언카운터블 애로우 - 보스 몬스터 피해 | 111 | 신비한 화살 연마 3 | 11237 | medium | talent |
| 70240 | 언카운터블 애로우 - 피해 | 116 | 신비한 화살 연마 4 | 11237 | medium | talent |
| 70250 | 언카운터블 애로우 - 피해 | 120 | 신비한 화살 연마 5 | 11237 | medium | talent |
| 70260 | 언카운터블 애로우 - 보스 몬스터 피해 | 124 | 신비한 화살 연마 6 | 11237 | medium | talentExtraRank |
| 70270 | 언카운터블 애로우 - 피해 | 128 | 신비한 화살 연마 7 | 11237 | medium | talentExtraRank |
| 70280 | 언카운터블 애로우 - 피해 | 132 | 신비한 화살 연마 8 | 11237 | medium | talentExtraRank |
| 70290 | 언카운터블 애로우 - 타격 | 136 | 신비한 화살 연마 9 | 11237 | medium | talentExtraRank |
| 70015 | 주스탯 강화 | 14 | 신비한 명상 | 18462 | medium | talent |
| 70025 | 크리티컬 확률 강화 | 17 | 치명타 증가 | 11115 | high | talent |
| 70035 | 아처 마스터리 - 속도 | 21 | 서리 갑옷 숙련 | 168 | high | generated |
| 70045 | 크리티컬 샷 - 크리티컬 | 24 | 산산조각 숙련 | 11170 | high | generated |
| 70055 | 기본 공격 데미지 강화 | 28 | 신비한 섬세함 | 11210 | medium | talent |
| 70065 | 명중 강화 | 34 | 마법 조율 | 11247 | medium | talent |
| 70075 | 리트리트 샷 - 피해 | 39 | 얼음 회오리 연마 1 | 11165 | high | talent |
| 70085 | 퀴버 카트리지 - 피해 | 44 | 혹한의 추위 숙련 | 11180 | high | generated |
| 70095 | 리트리트 샷 - 기절 | 49 | 얼음 회오리 연마 2 | 11165 | high | talent |
| 70105 | 파이널 어택 - 피해 | 54 | 동상 숙련 | 11071 | high | generated |
| 70115 | 최대 데미지 배율 강화 | 58 | 화염 마법 강화 | 11124 | high | talent |
| 70125 | 기본 공격 대상 수 강화 | 64 | 화염 투척 | 11100 | high | talent |
| 70135 | 플레시 미라주 - 피해 | 68 | 신비한 집중 숙련 | 11213 | high | generated |
| 70145 | 애로우 플래터 - 피해 | 73 | 불기둥 연마 1 | 11108 | high | talent |
| 70155 | 피닉스 - 대상 | 78 | 화염구 연마 1 | 11069 | high | talent |
| 70165 | 피닉스 - 타격 주기 | 82 | 화염구 연마 2 | 11069 | high | talent |
| 70175 | 스킬 데미지 강화 | 86 | 원소의 대가 | 29074 | medium | talent |
| 70185 | 모탈 블로우 - 지속 | 90 | 냉기 계열 초기화 숙련 | 12472 | high | generated |
| 70195 | 피닉스 - 일반 몬스터 데미지 | 94 | 화염구 연마 3 | 11069 | high | talent |
| 70205 | 애로우 플래터 - 대상 | 98 | 불기둥 연마 2 | 11108 | high | talent |
| 70215 | 피닉스 - 재사용 | 104 | 화염구 연마 4 | 11069 | high | talent |
| 70225 | 폭풍의 시 - 피해 | 108 | 눈보라 연마 1 | 11185 | high | talent |
| 70235 | 어드밴스드 파이널 어택 - 강화 | 113 | 영구 동토 숙련 | 11175 | high | generated |
| 70245 | 일루전 스탭 - 강화 | 118 | 얼음 보호막 숙련 | 11426 | high | generated |
| 70255 | 플레시 미라주 II - 재사용 | 122 | 신비한 불안정 숙련 1 | 15058 | high | generated |
| 70265 | 샤프 아이즈 - 지속 | 126 | 마법 증폭 숙련 | 1008 | high | generated |
| 70275 | 어드밴스드 퀴버 - 흡혈 | 130 | 극지의 손길 숙련 | 16757 | medium | generated |
| 70285 | 폭풍의 시 - 연장 | 134 | 눈보라 연마 2 | 11185 | high | talent |
| 70295 | 플레시 미라주 II - 강화 & 대상 | 138 | 신비한 불안정 숙련 2 | 15058 | high | generated |

## 신궁 → 사격 사냥꾼 (Marksmanship Hunter)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 81010 | 애로우 블로우 | 1차 BA | 자동 사격 | Auto Shot | 75 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 치타의 상 | Aspect of the Cheetah | 5118 | high |
| 81020 | 더블 점프 | 1차 passive | 철수 | Disengage | 781 | high |
| 81040 | 아처 마스터리 | 1차 passive | 치타 무리의 상 | Aspect of the Pack | 13159 | high |
| 81030 | 크리티컬 샷 | 1차 passive | 치명적인 사격 | Lethal Shots | 19426 | high |
| 82010 | 피어싱 | 2차 BA | 독사 쐐기 | Serpent Sting | 1978 | high |
| 82030 | 크로스보우 액셀레이션 | 2차 passive | 속사 | Rapid Fire | 3045 | high |
| 82020 | 리트리트 샷 | 2차 active | 산탄 사격 | Scatter Shot | 19503 | high |
| 82070 | 피지컬 트레이닝 | 2차 passive | 원거리 무기 전문화 | Ranged Weapon Specialization | 19507 | medium |
| 82080 | 데미지 리버싱 | 2차 passive | 공격 저지 | Deterrence | 19263 | medium |
| 82050 | 크로스보우 마스터리 | 2차 passive | 효율성 | Efficiency | 19416 | medium |
| 82040 | 소울 애로우 : 석궁 | 2차 passive | 매의 눈 | Hawk Eye | 19498 | medium |
| 82060 | 파이널 어택 : 석궁 | 2차 passive | 충격포 연마 | Improved Concussive Shot | 19407 | medium |
| 83010 | 피어싱 II | 3차 BA | 신비한 사격 | Arcane Shot | 3044 | high |
| 83040 | 볼트 플로우 | 3차 buff | 사냥꾼의 징표 | Hunter's Mark | 1130 | high |
| 83030 | 볼트 스위프트 | 3차 active | 연발 사격 | Volley | 1510 | high |
| 83050 | 페인 킬러 | 3차 buff | 죽은척하기 | Feign Death | 5384 | high |
| 83020 | 프리져 | 3차 active | 얼음 덫 | Freezing Trap | 1499 | high |
| 83070 | 모탈 블로우 | 3차 passive | 필사의 사격 | Mortal Shots | 19485 | high |
| 83080 | 마크맨쉽 | 3차 passive | 사냥꾼의 징표 연마 | Improved Hunter's Mark | 19421 | medium |
| 83060 | 익스트림 아쳐리 : 석궁 | 3차 passive | 매의 상 | Aspect of the Hawk | 13165 | high |
| 84010 | 인핸스 피어싱 | 4차 BA | 일제 사격 | Multi-Shot | 2643 | high |
| 84100 | 메이플 용사 | 4차 passive | 전갈 쐐기 | Scorpid Sting | 3043 | high |
| 84020 | 스나이핑 | 4차 active | 조준 사격 | Aimed Shot | 19434 | high |
| 84080 | 어드밴스드 파이널 어택 | 4차 passive | 충격포 | Concussive Shot | 5116 | high |
| 84050 | 어디셔널 볼트 | 4차 passive | 폭발의 덫 | Explosive Trap | 13813 | high |
| 84040 | 애로우 일루전 | 4차 active | 냉기의 덫 | Frost Trap | 13809 | high |
| 84030 | 샤프 아이즈 | 4차 buff | 정조준 오라 | Trueshot Aura | 19506 | high |
| 84070 | 일루전 스탭 | 4차 passive | 원숭이의 상 | Aspect of the Monkey | 13163 | high |
| 84060 | 크로스보우 엑스퍼트 | 4차 passive | 살수의 본능 | Killer Instinct | 19370 | medium |
| 84090 | 라스트맨 스탠딩 | 4차 passive | 괴물 사냥 | Monster Slaying | 24293 | medium |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 80010 | 애로우 블로우 - 피해 | 12 | 자동 사격 숙련 1 | 75 | high | generated |
| 80020 | 애로우 블로우 - 대상 | 15 | 자동 사격 숙련 2 | 75 | high | generated |
| 80030 | 애로우 블로우 - 피해 | 19 | 자동 사격 숙련 3 | 75 | high | generated |
| 80040 | 애로우 블로우 - 대상 | 22 | 자동 사격 숙련 4 | 75 | high | generated |
| 80050 | 애로우 블로우 - 피해 | 26 | 자동 사격 숙련 5 | 75 | high | generated |
| 80060 | 피어싱 - 피해 | 32 | 독사 쐐기 연마 1 | 19464 | medium | talent |
| 80070 | 피어싱 - 대상 | 37 | 독사 쐐기 연마 2 | 19464 | medium | talent |
| 80080 | 피어싱 - 피해 | 42 | 독사 쐐기 연마 3 | 19464 | medium | talent |
| 80090 | 피어싱 - 보스 몬스터 피해 | 47 | 독사 쐐기 연마 4 | 19464 | medium | talent |
| 80100 | 피어싱 - 피해 | 52 | 독사 쐐기 연마 5 | 19464 | medium | talent |
| 80110 | 피어싱 - 타격 | 56 | 독사 쐐기 연마 6 | 19464 | medium | talentExtraRank |
| 80120 | 피어싱 II - 피해 | 62 | 신비한 사격 연마 1 | 19454 | medium | talent |
| 80130 | 피어싱 II - 피해 | 66 | 신비한 사격 연마 2 | 19454 | medium | talent |
| 80140 | 피어싱 II - 보스 몬스터 피해 | 71 | 신비한 사격 연마 3 | 19454 | medium | talent |
| 80150 | 피어싱 II - 피해 | 76 | 신비한 사격 연마 4 | 19454 | medium | talent |
| 80160 | 피어싱 II - 피해 | 80 | 신비한 사격 연마 5 | 19454 | medium | talent |
| 80170 | 피어싱 II - 보스 몬스터 피해 | 84 | 신비한 사격 연마 6 | 19454 | medium | talentExtraRank |
| 80180 | 피어싱 II - 피해 | 88 | 신비한 사격 연마 7 | 19454 | medium | talentExtraRank |
| 80190 | 피어싱 II - 피해 | 92 | 신비한 사격 연마 8 | 19454 | medium | talentExtraRank |
| 80200 | 피어싱 II - 타격 | 96 | 신비한 사격 연마 9 | 19454 | medium | talentExtraRank |
| 80210 | 인핸스 피어싱 - 피해 | 102 | 탄막 1 | 19461 | medium | talent |
| 80220 | 인핸스 피어싱 - 피해 | 106 | 탄막 2 | 19461 | medium | talent |
| 80230 | 인핸스 피어싱 - 보스 몬스터 피해 | 111 | 탄막 3 | 19461 | medium | talent |
| 80240 | 인핸스 피어싱 - 피해 | 116 | 탄막 4 | 19461 | medium | talentExtraRank |
| 80250 | 인핸스 피어싱 - 피해 | 120 | 탄막 5 | 19461 | medium | talentExtraRank |
| 80260 | 인핸스 피어싱 - 보스 몬스터 피해 | 124 | 탄막 6 | 19461 | medium | talentExtraRank |
| 80270 | 인핸스 피어싱 - 피해 | 128 | 탄막 7 | 19461 | medium | talentExtraRank |
| 80280 | 인핸스 피어싱 - 피해 | 132 | 탄막 8 | 19461 | medium | talentExtraRank |
| 80290 | 인핸스 피어싱 - 타격 | 136 | 탄막 9 | 19461 | medium | talentExtraRank |
| 80015 | 주스탯 강화 | 14 | 번개 같은 반사신경 | 19168 | medium | talent |
| 80025 | 크리티컬 확률 강화 | 17 | 전갈 쐐기 연마 | 19491 | medium | talent |
| 80035 | 아처 마스터리 - 속도 | 21 | 치타 무리의 상 숙련 | 13159 | high | generated |
| 80045 | 크리티컬 샷 - 크리티컬 | 24 | 치명적인 사격 숙련 | 19426 | high | generated |
| 80055 | 기본 공격 데미지 강화 | 28 | 인간형 사냥 | 19151 | medium | talent |
| 80065 | 명중 강화 | 34 | 확고한 발걸음 | 19290 | medium | talent |
| 80075 | 리트리트 샷 - 피해 | 39 | 산탄 사격 숙련 1 | 19503 | high | generated |
| 80085 | 데미지 리버싱 - 지속 | 44 | 공격 저지 숙련 | 19263 | medium | generated |
| 80095 | 리트리트 샷 - 기절 | 49 | 산탄 사격 숙련 2 | 19503 | high | generated |
| 80105 | 파이널 어택 - 피해 | 54 | 충격포 연마 숙련 | 19407 | medium | generated |
| 80115 | 최대 데미지 배율 강화 | 58 | 야만의 일격 | 19159 | medium | talent |
| 80125 | 기본 공격 대상 수 강화 | 64 | 덫의 달인 | 19376 | medium | talent |
| 80135 | 볼트 스위프트 - 피해 | 68 | 연발 사격 숙련 1 | 1510 | high | generated |
| 80145 | 페인 킬러 - 면역 | 73 | 죽은척하기 숙련 | 5384 | high | generated |
| 80155 | 프리져 - 대상 | 78 | 교묘한 덫 1 | 19239 | medium | talent |
| 80165 | 프리져 - 피해 | 82 | 교묘한 덫 2 | 19239 | medium | talent |
| 80175 | 스킬 데미지 강화 | 86 | 생존 전문가 | 19255 | medium | talent |
| 80185 | 모탈 블로우 - 지속 | 90 | 필사의 사격 숙련 | 19485 | high | generated |
| 80195 | 프리져 - 일반 몬스터 데미지 | 94 | 교묘한 덫 3 | 19239 | medium | talentExtraRank |
| 80205 | 볼트 스위프트 - 기절 | 98 | 연발 사격 숙련 2 | 1510 | high | generated |
| 80215 | 프리져 - 재사용 | 104 | 교묘한 덫 4 | 19239 | medium | talentExtraRank |
| 80225 | 스나이핑 - 피해 | 108 | 조준 사격 숙련 1 | 19434 | high | generated |
| 80235 | 어드밴스드 파이널 어택 - 강화 | 113 | 충격포 숙련 | 5116 | high | generated |
| 80245 | 일루전 스탭 - 강화 | 118 | 원숭이의 상 숙련 | 13163 | high | generated |
| 80255 | 어디셔널 볼트 - 피해 | 122 | 교묘한 덫 5 | 19239 | medium | talentExtraRank |
| 80265 | 샤프 아이즈 - 지속 | 126 | 정조준 오라 숙련 | 19506 | high | generated |
| 80275 | 애로우 일루전 - 피해 | 130 | 올가미 | 19184 | medium | talent |
| 80285 | 스나이핑 - 인핸스 | 134 | 조준 사격 숙련 2 | 19434 | high | generated |
| 80295 | 어디셔널 볼트 - 타격 & 대상 | 138 | 교묘한 덫 6 | 19239 | medium | talentExtraRank |

## 나이트로드 → 암살 도적 (Assassination Rogue)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 91010 | 럭키 세븐 | 1차 BA | 사악한 일격 | Sinister Strike | 1752 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 전력 질주 | Sprint | 2983 | high |
| 91040 | 플래시 점프 | 1차 passive | 위장술 | Camouflage | 13975 | medium |
| 91020 | 헤이스트 | 1차 passive | 전력 질주 연마 | Improved Sprint | 13743 | medium |
| 91030 | 다크 사이트 | 1차 buff | 은신 | Stealth | 1784 | high |
| 92010 | 슈리켄 버스트 | 2차 BA | 기습 | Backstab | 53 | high |
| 92060 | 자벨린 액셀레이션 | 2차 passive | 난도질 | Slice and Dice | 5171 | high |
| 92020 | 윈드 탈리스만 | 2차 active | 후려치기 | Gouge | 1776 | high |
| 92080 | 피지컬 트레이닝 | 2차 passive | 기회 | Opportunity | 14057 | medium |
| 92050 | 자벨린 마스터리 | 2차 passive | 단검 전문화 | Dagger Specialization | 13706 | medium |
| 92040 | 마크 오브 어쌔신 | 2차 passive | 사전계획 | Premeditation | 14183 | high |
| 92070 | 크리티컬 스로우 | 2차 passive | 악의 | Malice | 14138 | high |
| 92030 | 쉐도우 러쉬 | 2차 buff | 소멸 | Vanish | 1856 | high |
| 93010 | 슈리켄 챌린지 | 3차 BA | 과다출혈 | Hemorrhage | 16511 | high |
| 93030 | 쉐도우 파트너 | 3차 passive | 도검 전문화 | Sword Specialization | 13960 | medium |
| 93020 | 트리플 스로우 | 3차 active | 유령의 일격 | Ghostly Strike | 14278 | high |
| 93080 | 아드레날린 | 3차 passive | 아드레날린 촉진 | Adrenaline Rush | 13750 | high |
| 93040 | 다크 플레어 | 3차 active | 폭풍의 칼날 | Blade Flurry | 13877 | high |
| 93050 | 래디컬 다크니스 | 3차 passive | 살해 | Murder | 14158 | medium |
| 93060 | 베놈 | 3차 passive | 맹독 | Deadly Poison | 2835 | medium |
| 93070 | 숙련된 표창술 | 3차 passive | 치명상 | Lethality | 14128 | high |
| 94010 | 쇼다운 챌린지 | 4차 BA | 매복 | Ambush | 8676 | high |
| 94100 | 메이플 용사 | 4차 passive | 무자비 | Ruthlessness | 14156 | high |
| 94020 | 쿼드러플 스로우 | 4차 active | 절개 | Eviscerate | 2098 | high |
| 94030 | 써든레이드 | 4차 active | 파열 | Rupture | 1943 | high |
| 94050 | 마크 오브 나이트로드 | 4차 passive | 운명의 낙인 | Seal Fate | 14186 | high |
| 94040 | 퍼지 에어리어 | 4차 buff | 약점 노출 | Expose Armor | 8647 | high |
| 94070 | 페이크 | 4차 passive | 반격 | Riposte | 14251 | high |
| 94080 | 페이탈 베놈 | 4차 passive | 극독 | Vile Poisons | 16513 | medium |
| 94090 | 자벨린 엑스퍼트 | 4차 passive | 쌍수 무기 전문화 | Dual Wield Specialization | 13715 | medium |
| 94060 | 다크 세레니티 | 4차 passive | 냉혈 | Cold Blood | 14177 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 90010 | 럭키 세븐 - 피해 | 12 | 사악한 일격 연마 1 | 13732 | medium | talent |
| 90020 | 럭키 세븐 - 대상 | 15 | 사악한 일격 연마 2 | 13732 | medium | talent |
| 90030 | 럭키 세븐 - 피해 | 19 | 사악한 일격 연마 3 | 13732 | medium | talentExtraRank |
| 90040 | 럭키 세븐 - 대상 | 22 | 사악한 일격 연마 4 | 13732 | medium | talentExtraRank |
| 90050 | 럭키 세븐 - 피해 | 26 | 사악한 일격 연마 5 | 13732 | medium | talentExtraRank |
| 90060 | 슈리켄 버스트 - 피해 | 32 | 기습 연마 1 | 13733 | medium | talent |
| 90070 | 슈리켄 버스트 - 대상 | 37 | 기습 연마 2 | 13733 | medium | talent |
| 90080 | 슈리켄 버스트 - 피해 | 42 | 기습 연마 3 | 13733 | medium | talent |
| 90090 | 슈리켄 버스트 - 보스 몬스터 피해 | 47 | 기습 연마 4 | 13733 | medium | talentExtraRank |
| 90100 | 슈리켄 버스트 - 피해 | 52 | 기습 연마 5 | 13733 | medium | talentExtraRank |
| 90110 | 슈리켄 버스트 - 타격 | 56 | 기습 연마 6 | 13733 | medium | talentExtraRank |
| 90120 | 슈리켄 챌린지 - 피해 | 62 | 톱날 검 1 | 14171 | medium | talent |
| 90130 | 슈리켄 챌린지 - 피해 | 66 | 톱날 검 2 | 14171 | medium | talent |
| 90140 | 슈리켄 챌린지 - 보스 몬스터 피해 | 71 | 톱날 검 3 | 14171 | medium | talent |
| 90150 | 슈리켄 챌린지 - 피해 | 76 | 톱날 검 4 | 14171 | medium | talentExtraRank |
| 90160 | 슈리켄 챌린지 - 피해 | 80 | 톱날 검 5 | 14171 | medium | talentExtraRank |
| 90170 | 슈리켄 챌린지 - 보스 몬스터 피해 | 84 | 톱날 검 6 | 14171 | medium | talentExtraRank |
| 90180 | 슈리켄 챌린지 - 피해 | 88 | 톱날 검 7 | 14171 | medium | talentExtraRank |
| 90190 | 슈리켄 챌린지 - 피해 | 92 | 톱날 검 8 | 14171 | medium | talentExtraRank |
| 90200 | 슈리켄 챌린지 - 타격 | 96 | 톱날 검 9 | 14171 | medium | talentExtraRank |
| 90210 | 쇼다운 챌린지 - 피해 | 102 | 매복 연마 1 | 14079 | medium | talent |
| 90220 | 쇼다운 챌린지 - 피해 | 106 | 매복 연마 2 | 14079 | medium | talent |
| 90230 | 쇼다운 챌린지 - 보스 몬스터 피해 | 111 | 매복 연마 3 | 14079 | medium | talent |
| 90240 | 쇼다운 챌린지 - 피해 | 116 | 매복 연마 4 | 14079 | medium | talentExtraRank |
| 90250 | 쇼다운 챌린지 - 피해 | 120 | 매복 연마 5 | 14079 | medium | talentExtraRank |
| 90260 | 쇼다운 챌린지 - 보스 몬스터 피해 | 124 | 매복 연마 6 | 14079 | medium | talentExtraRank |
| 90270 | 쇼다운 챌린지 - 피해 | 128 | 매복 연마 7 | 14079 | medium | talentExtraRank |
| 90280 | 쇼다운 챌린지 - 피해 | 132 | 매복 연마 8 | 14079 | medium | talentExtraRank |
| 90290 | 쇼다운 챌린지 - 타격 | 136 | 매복 연마 9 | 14079 | medium | talentExtraRank |
| 90015 | 주스탯 강화 | 14 | 활력 | 14983 | high | talent |
| 90025 | 크리티컬 확률 강화 | 17 | 가차없는 일격 | 14179 | high | talent |
| 90035 | 헤이스트 - 속도 | 21 | 전력 질주 연마 숙련 | 13743 | medium | generated |
| 90045 | 다크 사이트 - 지속 | 24 | 기만의 대가 | 13958 | medium | talent |
| 90055 | 기본 공격 데미지 강화 | 28 | 공격성 | 18427 | medium | talent |
| 90065 | 명중 강화 | 34 | 정확성 | 13705 | medium | talent |
| 90075 | 윈드 탈리스만 - 피해 | 39 | 후려치기 연마 | 13741 | medium | talent |
| 90085 | 마크 오브 어쌔신 - 피해 | 44 | 사전계획 숙련 | 14183 | high | generated |
| 90095 | 크리티컬 스로우 - 크리티컬 | 49 | 악의 숙련 | 14138 | high | generated |
| 90105 | 쉐도우 러쉬 - 가속 | 54 | 소멸 숙련 | 1856 | high | generated |
| 90115 | 최대 데미지 배율 강화 | 58 | 냉혹한 공격 | 14144 | medium | talent |
| 90125 | 기본 공격 대상 수 강화 | 64 | 난도질 연마 | 14165 | medium | talent |
| 90135 | 쉐도우 파트너 - 피해 | 68 | 도검 전문화 숙련 | 13960 | medium | generated |
| 90145 | 트리플 스로우 - 피해 | 73 | 유령의 일격 숙련 | 14278 | high | generated |
| 90155 | 다크 플레어 - 타격 | 78 | 폭풍의 칼날 숙련 1 | 13877 | high | generated |
| 90165 | 베놈 - 약화 | 82 | 독 연마 1 | 14113 | high | talent |
| 90175 | 스킬 데미지 강화 | 86 | 약점 노출 연마 | 14168 | medium | talent |
| 90185 | 아드레날린 - 지속 | 90 | 아드레날린 촉진 숙련 | 13750 | high | generated |
| 90195 | 다크 플레어 - 재사용 | 94 | 폭풍의 칼날 숙련 2 | 13877 | high | generated |
| 90205 | 베놈 - 확률 | 98 | 독 연마 2 | 14113 | high | talent |
| 90215 | 다크 플레어 - 타격 주기 | 104 | 폭풍의 칼날 숙련 3 | 13877 | high | generated |
| 90225 | 쿼드러플 스로우 - 재사용 | 108 | 절개 연마 1 | 14162 | high | talent |
| 90235 | 퍼지 에어리어 - 크리티컬 | 113 | 약점 노출 숙련 | 8647 | high | generated |
| 90245 | 페이크 - 회피 | 118 | 반격 숙련 | 14251 | high | generated |
| 90255 | 마크 오브 나이트로드 - 약화 | 122 | 운명의 낙인 숙련 1 | 14186 | high | generated |
| 90265 | 써든레이드 - 피해 | 126 | 파열 숙련 | 1943 | high | generated |
| 90275 | 페이탈 베놈 - 피해 | 130 | 독 연마 3 | 14113 | high | talent |
| 90285 | 쿼드러플 스로우 - 피해 | 134 | 절개 연마 2 | 14162 | high | talent |
| 90295 | 마크 오브 나이트로드 - 발동 주기 | 138 | 운명의 낙인 숙련 2 | 14186 | high | generated |

## 섀도어 → 악마 흑마법사 (Demonology Warlock)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 101010 | 더블 스탭 | 1차 BA | 어둠의 화살 | Shadow Bolt | 686 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 지옥마 소환 | Summon Felsteed | 5784 | high |
| 101040 | 플래시 점프 | 1차 passive | 공포마 소환 | Summon Dreadsteed | 23161 | high |
| 101020 | 헤이스트 | 1차 passive | 지옥의 지배 | Fel Domination | 18708 | high |
| 101030 | 다크 사이트 | 1차 buff | 서큐버스 소환 | Summon Succubus | 712 | high |
| 102010 | 새비지 블로우 | 2차 BA | 화염 화살 | Firebolt | 3110 | high |
| 102040 | 대거 액셀레이션 | 2차 passive | 파멸 | Bane | 17788 | high |
| 102020 | 스틸 | 2차 passive | 생명력 흡수 | Drain Life | 689 | high |
| 102070 | 피지컬 트레이닝 | 2차 passive | 부정의 힘 | Unholy Power | 18769 | medium |
| 102050 | 카르마 | 2차 passive | 악마의 포옹 | Demonic Embrace | 18697 | medium |
| 102060 | 대거 마스터리 | 2차 passive | 지옥 지능 | Fel Intellect | 18731 | medium |
| 102080 | 실드 마스터리 | 2차 passive | 악마의 갑옷 | Demon Armor | 706 | high |
| 102030 | 크리티컬 엣지 | 2차 passive | 황폐 | Devastation | 18130 | high |
| 103010 | 엣지 카니발 | 3차 BA | 고통의 채찍 | Lash of Pain | 7814 | high |
| 103050 | 쉐도우 파트너 | 3차 passive | 보이드워커 소환 | Summon Voidwalker | 697 | high |
| 103020 | 무스펠 하임 | 3차 active | 죽음의 고리 | Death Coil | 6789 | high |
| 103030 | 메소 익스플로젼 | 3차 active | 지옥의 불길 | Hellfire | 1949 | high |
| 103040 | 다크 플레어 | 3차 active | 지옥사냥개 소환 | Summon Felhunter | 691 | high |
| 103060 | 베놈 | 3차 passive | 고통의 저주 | Curse of Agony | 980 | high |
| 103070 | 인투 다크니스 | 3차 buff | 악마의 희생 | Demonic Sacrifice | 18788 | high |
| 103080 | 그리드 | 3차 passive | 영혼 흡수 | Drain Soul | 1120 | high |
| 104010 | 크루얼 스탭 | 4차 BA | 제물 | Immolate | 348 | high |
| 104100 | 메이플 용사 | 4차 passive | 피의 서약 | Blood Pact | 6307 | high |
| 104020 | 암살 | 4차 active | 영혼의 불꽃 | Soul Fire | 6353 | high |
| 104030 | 써든레이드 | 4차 active | 지옥불정령 | Inferno | 1122 | high |
| 104050 | 블러디 파킷 | 4차 passive | 생명력 전환 | Life Tap | 1454 | high |
| 104040 | 연막탄 | 4차 buff | 원소의 저주 | Curse of the Elements | 1490 | high |
| 104070 | 페이크 | 4차 passive | 공포 | Fear | 5782 | high |
| 104080 | 페이탈 베놈 | 4차 passive | 생명력 착취 | Siphon Life | 18265 | high |
| 104090 | 대거 엑스퍼트 | 4차 passive | 악마학의 대가 | Master Demonologist | 23785 | medium |
| 104060 | 섀도어 인스팅트 | 4차 passive | 영혼의 고리 | Soul Link | 19028 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 100010 | 더블 스탭 - 피해 | 12 | 어둠의 화살 연마 1 | 17793 | high | talent |
| 100020 | 더블 스탭 - 대상 | 15 | 어둠의 화살 연마 2 | 17793 | high | talent |
| 100030 | 더블 스탭 - 피해 | 19 | 어둠의 화살 연마 3 | 17793 | high | talent |
| 100040 | 더블 스탭 - 대상 | 22 | 어둠의 화살 연마 4 | 17793 | high | talent |
| 100050 | 더블 스탭 - 피해 | 26 | 어둠의 화살 연마 5 | 17793 | high | talent |
| 100060 | 새비지 블로우 - 피해 | 32 | 화염 화살 연마 1 | 18126 | medium | talent |
| 100070 | 새비지 블로우 - 대상 | 37 | 화염 화살 연마 2 | 18126 | medium | talent |
| 100080 | 새비지 블로우 - 피해 | 42 | 화염 화살 연마 3 | 18126 | medium | talentExtraRank |
| 100090 | 새비지 블로우 - 보스 몬스터 피해 | 47 | 화염 화살 연마 4 | 18126 | medium | talentExtraRank |
| 100100 | 새비지 블로우 - 피해 | 52 | 화염 화살 연마 5 | 18126 | medium | talentExtraRank |
| 100110 | 새비지 블로우 - 타격 | 56 | 화염 화살 연마 6 | 18126 | medium | talentExtraRank |
| 100120 | 엣지 카니발 - 피해 | 62 | 고통의 채찍 연마 1 | 18128 | medium | talent |
| 100130 | 엣지 카니발 - 피해 | 66 | 고통의 채찍 연마 2 | 18128 | medium | talent |
| 100140 | 엣지 카니발 - 보스 몬스터 피해 | 71 | 고통의 채찍 연마 3 | 18128 | medium | talentExtraRank |
| 100150 | 엣지 카니발 - 피해 | 76 | 고통의 채찍 연마 4 | 18128 | medium | talentExtraRank |
| 100160 | 엣지 카니발 - 피해 | 80 | 고통의 채찍 연마 5 | 18128 | medium | talentExtraRank |
| 100170 | 엣지 카니발 - 보스 몬스터 피해 | 84 | 고통의 채찍 연마 6 | 18128 | medium | talentExtraRank |
| 100180 | 엣지 카니발 - 피해 | 88 | 고통의 채찍 연마 7 | 18128 | medium | talentExtraRank |
| 100190 | 엣지 카니발 - 피해 | 92 | 고통의 채찍 연마 8 | 18128 | medium | talentExtraRank |
| 100200 | 엣지 카니발 - 타격 | 96 | 고통의 채찍 연마 9 | 18128 | medium | talentExtraRank |
| 100210 | 크루얼 스탭 - 피해 | 102 | 제물 연마 1 | 17815 | high | talent |
| 100220 | 크루얼 스탭 - 피해 | 106 | 제물 연마 2 | 17815 | high | talent |
| 100230 | 크루얼 스탭 - 보스 몬스터 피해 | 111 | 제물 연마 3 | 17815 | high | talent |
| 100240 | 크루얼 스탭 - 피해 | 116 | 제물 연마 4 | 17815 | high | talent |
| 100250 | 크루얼 스탭 - 피해 | 120 | 제물 연마 5 | 17815 | high | talent |
| 100260 | 크루얼 스탭 - 보스 몬스터 피해 | 124 | 제물 연마 6 | 17815 | high | talentExtraRank |
| 100270 | 크루얼 스탭 - 피해 | 128 | 제물 연마 7 | 17815 | high | talentExtraRank |
| 100280 | 크루얼 스탭 - 피해 | 132 | 제물 연마 8 | 17815 | high | talentExtraRank |
| 100290 | 크루얼 스탭 - 타격 | 136 | 제물 연마 9 | 17815 | high | talentExtraRank |
| 100015 | 주스탯 강화 | 14 | 지옥 체력 | 18748 | medium | talent |
| 100025 | 크리티컬 확률 강화 | 17 | 여파 | 18119 | medium | talent |
| 100035 | 헤이스트 - 속도 | 21 | 지옥의 지배 숙련 | 18708 | high | generated |
| 100045 | 다크 사이트 - 지속 | 24 | 서큐버스 연마 | 18754 | medium | talent |
| 100055 | 기본 공격 데미지 강화 | 28 | 임프 연마 | 18694 | medium | talent |
| 100065 | 명중 강화 | 34 | 억제 | 18174 | medium | talent |
| 100075 | 스틸 - 확률 | 39 | 생명력 흡수 연마 1 | 17804 | medium | talent |
| 100085 | 대거 액셀레이션 - 속도 | 44 | 파멸 숙련 | 17788 | high | generated |
| 100095 | 대거 마스터리 - 크리티컬 | 49 | 지옥 지능 숙련 | 18731 | medium | generated |
| 100105 | 스틸 - 약화 | 54 | 생명력 흡수 연마 2 | 17804 | medium | talent |
| 100115 | 최대 데미지 배율 강화 | 58 | 파멸의 화염 | 17959 | high | talent |
| 100125 | 기본 공격 대상 수 강화 | 64 | 소환의 대가 | 18709 | medium | talent |
| 100135 | 쉐도우 파트너 - 피해 | 68 | 보이드워커 연마 | 18705 | medium | talent |
| 100145 | 무스펠 하임 - 피해 | 73 | 죽음의 고리 숙련 | 6789 | high | generated |
| 100155 | 다크 플레어 - 타격 | 78 | 지옥사냥개 소환 숙련 1 | 691 | high | generated |
| 100165 | 베놈 - 약화 | 82 | 고통의 저주 연마 1 | 18827 | medium | talent |
| 100175 | 스킬 데미지 강화 | 86 | 강렬함 | 18135 | medium | talent |
| 100185 | 메소 익스플로젼 - 피해 | 90 | 지옥의 불길 숙련 | 1949 | high | generated |
| 100195 | 다크 플레어 - 재사용 | 94 | 지옥사냥개 소환 숙련 2 | 691 | high | generated |
| 100205 | 베놈 - 확률 | 98 | 고통의 저주 연마 2 | 18827 | medium | talent |
| 100215 | 다크 플레어 - 타격 주기 | 104 | 지옥사냥개 소환 숙련 3 | 691 | high | generated |
| 100225 | 암살 - 살의 | 108 | 영혼의 불꽃 숙련 1 | 6353 | high | generated |
| 100235 | 연막탄 - 크리티컬 | 113 | 원소의 저주 숙련 | 1490 | high | generated |
| 100245 | 페이크 - 회피 | 118 | 공포 숙련 | 5782 | high | generated |
| 100255 | 블러디 파킷 - 대상 & 피해 | 122 | 생명력 전환 연마 1 | 18182 | medium | talent |
| 100265 | 써든레이드 - 피해 | 126 | 지옥불정령 숙련 | 1122 | high | generated |
| 100275 | 페이탈 베놈 - 피해 | 130 | 생명력 착취 숙련 | 18265 | high | generated |
| 100285 | 암살 - 피해 | 134 | 영혼의 불꽃 숙련 2 | 6353 | high | generated |
| 100295 | 블러디 파킷 - 대상 & 피해 | 138 | 생명력 전환 연마 2 | 18182 | medium | talent |

## 바이퍼 → 야성 드루이드 (Feral (Cat) Druid)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 111010 | 써머솔트 킥 | 1차 BA | 할퀴기 | Claw | 1082 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 질주 | Dash | 1850 | high |
| 111040 | 파이렛 리프 | 1차 passive | 여행 변신 | Travel Form | 783 | high |
| 111020 | 크리티컬 로어 | 1차 passive | 날카로운 발톱 | Sharpened Claws | 16942 | high |
| 111030 | 퀵모션 | 1차 passive | 날렵한 몸놀림 | Feline Swiftness | 17002 | medium |
| 112010 | 쇼크 웨이브 | 2차 BA | 갈퀴 발톱 | Rake | 1822 | high |
| 112040 | 너클 액셀레이션 | 2차 passive | 야만의 격노 | Savage Fury | 16998 | medium |
| 112030 | 씨 서펜트 버스트 | 2차 passive | 도려내기 | Rip | 1079 | high |
| 112070 | 피지컬 트레이닝 | 2차 passive | 자연의 무기 | Natural Weapons | 16902 | medium |
| 112050 | 멘탈 클리어리티 | 2차 passive | 청명의 전조 | Omen of Clarity | 16864 | high |
| 112060 | 너클 마스터리 | 2차 passive | 야성의 본능 | Feral Instinct | 16947 | medium |
| 112080 | 인듀어런스 | 2차 passive | 광포한 재생 | Frenzied Regeneration | 22842 | high |
| 112020 | 어드밴스드 대쉬 | 2차 buff | 야성의 돌진 | Feral Charge | 16979 | high |
| 113010 | 터닝 킥 | 3차 BA | 칼날 발톱 | Shred | 5221 | high |
| 113070 | 윌로우 디펜시브 | 3차 passive | 나무 껍질 | Barkskin | 22812 | high |
| 113020 | 스크류 펀치 | 3차 active | 덮치기 | Pounce | 9005 | high |
| 113030 | 서펜트 스톤 | 3차 buff | 호랑이의 분노 | Tiger's Fury | 5217 | high |
| 113050 | 서펜트 어썰트 | 3차 passive | 피의 광기 | Blood Frenzy | 16952 | high |
| 113040 | 씨 서펜트 강화 I | 3차 passive | 원초적 격노 | Primal Fury | 16958 | high |
| 113060 | 럭키 다이스 | 3차 passive | 약탈의 일격 | Predatory Strikes | 16972 | high |
| 113080 | 그로기 마스터리 | 3차 passive | 잔혹한 충격 | Brutal Impact | 16940 | medium |
| 114010 | 훅 봄버 | 4차 BA | 흉포한 이빨 | Ferocious Bite | 22568 | high |
| 114100 | 메이플 용사 | 4차 passive | 무리의 우두머리 | Leader of the Pack | 17007 | high |
| 114020 | 피스트 인레이지 | 4차 active | 찢어발기기 | Ravage | 6785 | high |
| 114030 | 전함 노틸러스 | 4차 active | 휘둘러 치기 | Swipe | 779 | high |
| 114050 | 윈드 부스터 | 4차 buff | 표범 변신 | Cat Form | 768 | high |
| 114070 | 씨 서펜트 강화 II | 4차 passive | 두꺼운 가죽 | Thick Hide | 16929 | medium |
| 114040 | 바이퍼지션 | 4차 buff | 요정의 불꽃 (야성) | Faerie Fire (Feral) | 16857 | high |
| 114080 | 씨 서펜트 인레이지 | 4차 passive | 후려갈기기 | Maul | 6807 | high |
| 114090 | 서펜트 어썰트 인레이지 | 4차 passive | 강타 | Bash | 5211 | high |
| 114060 | 타임 리프 | 4차 buff | 정신 자극 | Innervate | 29166 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 110010 | 써머솔트 킥 - 피해 | 12 | 흉포 1 | 16934 | high | talent |
| 110020 | 써머솔트 킥 - 대상 | 15 | 흉포 2 | 16934 | high | talent |
| 110030 | 써머솔트 킥 - 피해 | 19 | 흉포 3 | 16934 | high | talent |
| 110040 | 써머솔트 킥 - 대상 | 22 | 흉포 4 | 16934 | high | talent |
| 110050 | 써머솔트 킥 - 피해 | 26 | 흉포 5 | 16934 | high | talent |
| 110060 | 쇼크 웨이브 - 피해 | 32 | 갈퀴 발톱 숙련 1 | 1822 | high | generated |
| 110070 | 쇼크 웨이브 - 대상 | 37 | 갈퀴 발톱 숙련 2 | 1822 | high | generated |
| 110080 | 쇼크 웨이브 - 피해 | 42 | 갈퀴 발톱 숙련 3 | 1822 | high | generated |
| 110090 | 쇼크 웨이브 - 보스 몬스터 피해 | 47 | 갈퀴 발톱 숙련 4 | 1822 | high | generated |
| 110100 | 쇼크 웨이브 - 피해 | 52 | 갈퀴 발톱 숙련 5 | 1822 | high | generated |
| 110110 | 쇼크 웨이브 - 타격 | 56 | 갈퀴 발톱 숙련 6 | 1822 | high | generated |
| 110120 | 터닝 킥 - 피해 | 62 | 칼날 발톱 연마 1 | 16966 | medium | talent |
| 110130 | 터닝 킥 - 피해 | 66 | 칼날 발톱 연마 2 | 16966 | medium | talent |
| 110140 | 터닝 킥 - 보스 몬스터 피해 | 71 | 칼날 발톱 연마 3 | 16966 | medium | talentExtraRank |
| 110150 | 터닝 킥 - 피해 | 76 | 칼날 발톱 연마 4 | 16966 | medium | talentExtraRank |
| 110160 | 터닝 킥 - 피해 | 80 | 칼날 발톱 연마 5 | 16966 | medium | talentExtraRank |
| 110170 | 터닝 킥 - 보스 몬스터 피해 | 84 | 칼날 발톱 연마 6 | 16966 | medium | talentExtraRank |
| 110180 | 터닝 킥 - 피해 | 88 | 칼날 발톱 연마 7 | 16966 | medium | talentExtraRank |
| 110190 | 터닝 킥 - 피해 | 92 | 칼날 발톱 연마 8 | 16966 | medium | talentExtraRank |
| 110200 | 터닝 킥 - 타격 | 96 | 칼날 발톱 연마 9 | 16966 | medium | talentExtraRank |
| 110210 | 훅 봄버 - 피해 | 102 | 야성의 공격성 1 | 16858 | medium | talent |
| 110220 | 훅 봄버 - 피해 | 106 | 야성의 공격성 2 | 16858 | medium | talent |
| 110230 | 훅 봄버 - 보스 몬스터 피해 | 111 | 야성의 공격성 3 | 16858 | medium | talent |
| 110240 | 훅 봄버 - 피해 | 116 | 야성의 공격성 4 | 16858 | medium | talent |
| 110250 | 훅 봄버 - 피해 | 120 | 야성의 공격성 5 | 16858 | medium | talent |
| 110260 | 훅 봄버 - 보스 몬스터 피해 | 124 | 야성의 공격성 6 | 16858 | medium | talentExtraRank |
| 110270 | 훅 봄버 - 피해 | 128 | 야성의 공격성 7 | 16858 | medium | talentExtraRank |
| 110280 | 훅 봄버 - 피해 | 132 | 야성의 공격성 8 | 16858 | medium | talentExtraRank |
| 110290 | 훅 봄버 - 타격 | 136 | 야성의 공격성 9 | 16858 | medium | talentExtraRank |
| 110015 | 주스탯 강화 | 14 | 야생의 심장 | 17003 | high | talent |
| 110025 | 크리티컬 확률 강화 | 17 | 야생의 징표 | 1126 | high | talent |
| 110035 | 크리티컬 로어 - 크리티컬 데미지 | 21 | 날카로운 발톱 숙련 | 16942 | high | generated |
| 110045 | 퀵 모션 - 속도 | 24 | 날렵한 몸놀림 숙련 | 17002 | medium | generated |
| 110055 | 기본 공격 데미지 강화 | 28 | 야생의 징표 연마 | 17050 | medium | talent |
| 110065 | 명중 강화 | 34 | 인간형 추적 | 5225 | high | talent |
| 110075 | 씨 서펜트 버스트 - 피해 | 39 | 도려내기 숙련 | 1079 | high | generated |
| 110085 | 너클 액셀레이션 - 속도 | 44 | 야만의 격노 숙련 | 16998 | medium | generated |
| 110095 | 인듀어런스 - 공격력 | 49 | 광포한 재생 숙련 | 22842 | high | generated |
| 110105 | 어드밴스드 대쉬 - 보호 | 54 | 야성의 돌진 숙련 | 16979 | high | generated |
| 110115 | 최대 데미지 배율 강화 | 58 | 격노 | 17056 | medium | talent |
| 110125 | 기본 공격 대상 수 강화 | 64 | 위협의 포효 | 99 | high | talent |
| 110135 | 서펜트 스톤 - 시작 | 68 | 호랑이의 분노 숙련 1 | 5217 | high | generated |
| 110145 | 스크류 펀치 - 피해 | 73 | 덮치기 숙련 | 9005 | high | generated |
| 110155 | 씨 서펜트 강화 I - 재사용 | 78 | 원초적 격노 숙련 | 16958 | high | generated |
| 110165 | 서펜트 어썰트 - 피해 | 82 | 피의 광기 숙련 | 16952 | high | generated |
| 110175 | 스킬 데미지 강화 | 86 | 타고난 변신술사 | 16833 | medium | talent |
| 110185 | 럭키 다이스 - 공격력 | 90 | 약탈의 일격 숙련 | 16972 | high | generated |
| 110195 | 서펜트 스톤 - 지속 | 94 | 호랑이의 분노 숙련 2 | 5217 | high | generated |
| 110205 | 그로기 마스터리 - 최종 데미지 | 98 | 잔혹한 충격 숙련 | 16940 | medium | generated |
| 110215 | 서펜트 스톤 - 중첩 | 104 | 호랑이의 분노 숙련 3 | 5217 | high | generated |
| 110225 | 피스트 인레이지 - 피해 | 108 | 찢어발기기 숙련 1 | 6785 | high | generated |
| 110235 | 전함 노틸러스 - 파이널 어택 | 113 | 휘둘러 치기 숙련 1 | 779 | high | generated |
| 110245 | 씨 서펜트 강화 II - 타격 & 재사용 | 118 | 두꺼운 가죽 숙련 | 16929 | medium | generated |
| 110255 | 씨 서펜트 인레이지 - 피해 | 122 | 후려갈기기 숙련 | 6807 | high | generated |
| 110265 | 전함 노틸러스 - 피해 | 126 | 휘둘러 치기 숙련 2 | 779 | high | generated |
| 110275 | 서펜트 어썰트 인레이지 - 피해 | 130 | 강타 숙련 | 5211 | high | generated |
| 110285 | 피스트 인레이지 - 재사용 | 134 | 찢어발기기 숙련 2 | 6785 | high | generated |
| 110295 | 타임 리프 - 부여 | 138 | 정신 자극 숙련 | 29166 | high | generated |

## 캡틴 → 야수 사냥꾼 (Beast Mastery Hunter)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 121010 | 더블 파이어 | 1차 BA | 자동 사격 | Auto Shot | 75 | high |
| 9000 | 민첩한 몸놀림 | 0차 buff | 치타의 상 | Aspect of the Cheetah | 5118 | high |
| 121040 | 파이렛 리프 | 1차 passive | 치타 무리의 상 | Aspect of the Pack | 13159 | high |
| 121020 | 크리티컬 로어 | 1차 passive | 치명적인 사격 | Lethal Shots | 19426 | high |
| 121030 | 퀵모션 | 1차 passive | 길잡이 | Pathfinding | 19559 | medium |
| 122010 | 매그넘 샷 | 2차 BA | 신비한 사격 | Arcane Shot | 3044 | high |
| 122020 | 스위프트 파이어 | 2차 active | 충격포 | Concussive Shot | 5116 | high |
| 122030 | 서먼 크루 | 2차 active | 야수 부르기 | Call Pet | 883 | high |
| 122070 | 피지컬 트레이닝 | 2차 passive | 원거리 무기 전문화 | Ranged Weapon Specialization | 19507 | medium |
| 122050 | 건 액셀레이션 | 2차 passive | 매의 상 연마 | Improved Aspect of the Hawk | 19552 | medium |
| 122060 | 건 마스터리 | 2차 passive | 야수 훈련 | Bestial Discipline | 19590 | medium |
| 122080 | 인피닛 불릿 | 2차 passive | 사냥꾼의 징표 | Hunter's Mark | 1130 | high |
| 122040 | 백스텝샷 | 2차 active | 철수 | Disengage | 781 | high |
| 123010 | 더블 배럴 샷 | 3차 BA | 일제 사격 | Multi-Shot | 2643 | high |
| 123070 | 발키리 페이션트 | 3차 passive | 두꺼운 가죽 | Thick Hide | 19609 | medium |
| 123030 | 시즈 봄버 | 3차 active | 폭발의 덫 | Explosive Trap | 13813 | high |
| 123020 | 불릿 스매시 | 3차 active | 위협 | Intimidation | 19577 | high |
| 123040 | 어셈블 크루 | 3차 passive | 영혼의 유대 | Spirit Bond | 19578 | medium |
| 123050 | 풀메탈 자켓 | 3차 passive | 필사의 사격 | Mortal Shots | 19485 | high |
| 123060 | 럭키 다이스 | 3차 passive | 광란 | Frenzy | 19621 | medium |
| 123080 | 할로포인트 불릿 | 3차 passive | 흉포 | Ferocity | 19598 | medium |
| 124010 | 퍼실레이드 | 4차 BA | 연발 사격 | Volley | 1510 | high |
| 124100 | 메이플 용사 | 4차 passive | 야생의 상 | Aspect of the Wild | 20043 | high |
| 124020 | 헤드 샷 | 4차 active | 조준 사격 | Aimed Shot | 19434 | high |
| 124030 | 전함 노틸러스 | 4차 active | 야수의 격노 | Bestial Wrath | 19574 | high |
| 124080 | 크루 커맨더십 | 4차 passive | 해방된 분노 | Unleashed Fury | 19616 | medium |
| 124050 | 배틀쉽 봄버 | 4차 active | 천둥발구르기 | Thunderstomp | 26090 | medium |
| 124060 | 파이렛 스타일 | 4차 buff | 매의 상 | Aspect of the Hawk | 13165 | high |
| 124040 | 래피드 파이어 | 4차 active | 속사 | Rapid Fire | 3045 | high |
| 124090 | 캡틴 디그니티 | 4차 passive | 충격포 연마 | Improved Concussive Shot | 19407 | medium |
| 124070 | 퀵 드로우 | 4차 passive | 번개 같은 반사신경 | Lightning Reflexes | 19168 | medium |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 120010 | 더블 파이어 - 피해 | 12 | 자동 사격 숙련 1 | 75 | high | generated |
| 120020 | 더블 파이어 - 대상 | 15 | 자동 사격 숙련 2 | 75 | high | generated |
| 120030 | 더블 파이어 - 피해 | 19 | 자동 사격 숙련 3 | 75 | high | generated |
| 120040 | 더블 파이어 - 대상 | 22 | 자동 사격 숙련 4 | 75 | high | generated |
| 120050 | 더블 파이어 - 피해 | 26 | 자동 사격 숙련 5 | 75 | high | generated |
| 120060 | 매그넘 샷 - 피해 | 32 | 신비한 사격 연마 1 | 19454 | medium | talent |
| 120070 | 매그넘 샷 - 대상 | 37 | 신비한 사격 연마 2 | 19454 | medium | talent |
| 120080 | 매그넘 샷 - 피해 | 42 | 신비한 사격 연마 3 | 19454 | medium | talent |
| 120090 | 매그넘 샷 - 보스 몬스터 피해 | 47 | 신비한 사격 연마 4 | 19454 | medium | talent |
| 120100 | 매그넘 샷 - 피해 | 52 | 신비한 사격 연마 5 | 19454 | medium | talent |
| 120110 | 매그넘 샷 - 타격 | 56 | 신비한 사격 연마 6 | 19454 | medium | talentExtraRank |
| 120120 | 더블 배럴 샷 - 피해 | 62 | 탄막 1 | 19461 | medium | talent |
| 120130 | 더블 배럴 샷 - 피해 | 66 | 탄막 2 | 19461 | medium | talent |
| 120140 | 더블 배럴 샷 - 보스 몬스터 피해 | 71 | 탄막 3 | 19461 | medium | talent |
| 120150 | 더블 배럴 샷 - 피해 | 76 | 탄막 4 | 19461 | medium | talentExtraRank |
| 120160 | 더블 배럴 샷 - 피해 | 80 | 탄막 5 | 19461 | medium | talentExtraRank |
| 120170 | 더블 배럴 샷 - 보스 몬스터 피해 | 84 | 탄막 6 | 19461 | medium | talentExtraRank |
| 120180 | 더블 배럴 샷 - 피해 | 88 | 탄막 7 | 19461 | medium | talentExtraRank |
| 120190 | 더블 배럴 샷 - 피해 | 92 | 탄막 8 | 19461 | medium | talentExtraRank |
| 120200 | 더블 배럴 샷 - 타격 | 96 | 탄막 9 | 19461 | medium | talentExtraRank |
| 120210 | 퍼실레이드 - 피해 | 102 | 연발 사격 숙련 1 | 1510 | high | generated |
| 120220 | 퍼실레이드 - 피해 | 106 | 연발 사격 숙련 2 | 1510 | high | generated |
| 120230 | 퍼실레이드 - 보스 몬스터 피해 | 111 | 연발 사격 숙련 3 | 1510 | high | generated |
| 120240 | 퍼실레이드 - 피해 | 116 | 연발 사격 숙련 4 | 1510 | high | generated |
| 120250 | 퍼실레이드 - 피해 | 120 | 연발 사격 숙련 5 | 1510 | high | generated |
| 120260 | 퍼실레이드 - 보스 몬스터 피해 | 124 | 연발 사격 숙련 6 | 1510 | high | generated |
| 120270 | 퍼실레이드 - 피해 | 128 | 연발 사격 숙련 7 | 1510 | high | generated |
| 120280 | 퍼실레이드 - 피해 | 132 | 연발 사격 숙련 8 | 1510 | high | generated |
| 120290 | 퍼실레이드 - 타격 | 136 | 연발 사격 숙련 9 | 1510 | high | generated |
| 120015 | 주스탯 강화 | 14 | 지구력 훈련 | 19583 | medium | talent |
| 120025 | 크리티컬 확률 강화 | 17 | 살수의 본능 | 19370 | medium | talent |
| 120035 | 크리티컬 로어 - 크리티컬 데미지 | 21 | 치명적인 사격 숙련 | 19426 | high | generated |
| 120045 | 퀵 모션 - 속도 | 24 | 길잡이 숙련 | 19559 | medium | generated |
| 120055 | 기본 공격 데미지 강화 | 28 | 인간형 사냥 | 19151 | medium | talent |
| 120065 | 명중 강화 | 34 | 확고한 발걸음 | 19290 | medium | talent |
| 120075 | 스위프트 파이어 - 피해 | 39 | 충격포 숙련 1 | 5116 | high | generated |
| 120085 | 건 액셀레이션 - 속도 | 44 | 매의 상 연마 숙련 | 19552 | medium | generated |
| 120095 | 서먼 크루 - 피해 | 49 | 동물 치료 연마 1 | 19572 | medium | talent |
| 120105 | 스위프트 파이어 - 약화 | 54 | 충격포 숙련 2 | 5116 | high | generated |
| 120115 | 최대 데미지 배율 강화 | 58 | 괴물 사냥 | 24293 | medium | talent |
| 120125 | 기본 공격 대상 수 강화 | 64 | 야수의 신속함 | 19596 | medium | talent |
| 120135 | 시즈 봄버 - 설치 | 68 | 교묘한 덫 1 | 19239 | medium | talent |
| 120145 | 불릿 스매시 - 피해 | 73 | 위협 숙련 | 19577 | high | generated |
| 120155 | 어셈블 크루 - 피해 | 78 | 동물 치료 연마 2 | 19572 | medium | talent |
| 120165 | 시즈 봄버 - 피해 | 82 | 교묘한 덫 2 | 19239 | medium | talent |
| 120175 | 스킬 데미지 강화 | 86 | 효율성 | 19416 | medium | talent |
| 120185 | 럭키 다이스 - 공격력 | 90 | 광란 숙련 | 19621 | medium | generated |
| 120195 | 어셈블 크루 - 타격 주기 | 94 | 동물 치료 연마 3 | 19572 | medium | talentExtraRank |
| 120205 | 풀메탈 자켓 - 방어 관통력 | 98 | 필사의 사격 숙련 | 19485 | high | generated |
| 120215 | 어셈블 크루 - 지속 | 104 | 동물 치료 연마 4 | 19572 | medium | talentExtraRank |
| 120225 | 헤드 샷 - 피해 | 108 | 조준 사격 숙련 | 19434 | high | generated |
| 120235 | 전함 노틸러스 - 파이널 어택 | 113 | 야수의 격노 숙련 1 | 19574 | high | generated |
| 120245 | 배틀쉽 봄버 - 폭격 | 118 | 천둥발구르기 숙련 1 | 26090 | medium | generated |
| 120255 | 크루 커맨더십 - 최종 데미지 | 122 | 해방된 분노 숙련 | 19616 | medium | generated |
| 120265 | 전함 노틸러스 - 피해 | 126 | 야수의 격노 숙련 2 | 19574 | high | generated |
| 120275 | 래피드 파이어 - 피해 | 130 | 속사 숙련 | 3045 | high | generated |
| 120285 | 캡틴 디그니티 - 피해 | 134 | 충격포 연마 숙련 | 19407 | medium | generated |
| 120295 | 배틀쉽 봄버 - 설치 | 138 | 천둥발구르기 숙련 2 | 26090 | medium | generated |

## 나이트워커 → 암흑 사제 (Shadow Priest)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 131010 | 럭키 세븐 | 1차 BA | 성스러운 일격 | Smite | 585 | high |
| 9001 | 엘리멘탈 하모니 | 0차 buff | 내면의 집중 | Inner Focus | 14751 | high |
| 131020 | 쉐도우 점프 | 1차 passive | 공중 부양 | Levitate | 1706 | high |
| 131030 | 엘리멘트 : 다크니스 | 1차 buff | 어둠의 형상 | Shadowform | 15473 | high |
| 131040 | 쉐도우 배트 | 1차 passive | 어둠의 권능: 고통 | Shadow Word: Pain | 589 | high |
| 132010 | 트리플 스로우 | 2차 BA | 신성한 불꽃 | Holy Fire | 14914 | high |
| 132040 | 스로잉 액셀레이션 | 2차 passive | 정신 민첩성 | Mental Agility | 14520 | medium |
| 132020 | 스타더스트 | 2차 active | 별조각 | Starshards | 10797 | high |
| 132080 | 피지컬 트레이닝 | 2차 passive | 마법봉 전문화 | Wand Specialization | 14524 | medium |
| 132030 | 배트 커뮤니온 | 2차 passive | 어둠의 권능: 고통 연마 | Improved Shadow Word: Pain | 15275 | high |
| 132060 | 스로잉 마스터리 | 2차 passive | 어둠 집중 | Shadow Focus | 15260 | medium |
| 132070 | 크리티컬 스로우 | 2차 passive | 의지력 | Force of Will | 18544 | medium |
| 132050 | 다크니스 어뎁팅 | 2차 passive | 어둠의 그물 | Shadow Weaving | 15257 | high |
| 133010 | 쿼드러플 스로우 | 3차 BA | 정신 분열 | Mind Blast | 8092 | high |
| 133080 | 래디컬 다크니스 | 3차 passive | 어둠의 친화 | Shadow Affinity | 15318 | medium |
| 133020 | 쉐도우 서번트 | 3차 active | 정신 지배 | Mind Control | 605 | high |
| 133050 | 배트 커뮤니온 II | 3차 passive | 암흑 | Blackout | 15268 | high |
| 133030 | 다크니스 어센션 | 3차 buff | 흡혈의 선물 | Vampiric Embrace | 15286 | high |
| 133060 | 다크니스 어뎁팅 II | 3차 passive | 어둠 | Darkness | 15259 | high |
| 133040 | 쉐도우 모멘텀 | 3차 passive | 영혼의 갈취 | Spirit Tap | 15270 | high |
| 133070 | 스피릿 스로잉 | 3차 passive | 내면의 열정 | Inner Fire | 588 | high |
| 134010 | 퀸터플 스로우 | 4차 BA | 정신의 채찍 | Mind Flay | 15407 | high |
| 134100 | 시그너스 나이츠 | 4차 passive | 신의 권능: 인내 | Power Word: Fortitude | 1243 | high |
| 134020 | 다크니스 오멘 | 4차 active | 영혼의 절규 | Psychic Scream | 8122 | high |
| 134040 | 쉐도우 스티치 | 4차 active | 파멸의 역병 | Devouring Plague | 2944 | high |
| 134050 | 배트 커뮤니온 III | 4차 passive | 어둠의 손길 | Shadow Reach | 17322 | medium |
| 134060 | 다크니스 어뎁팅 III | 4차 passive | 흡혈의 선물 연마 | Improved Vampiric Embrace | 27839 | medium |
| 134030 | 다크니스 이베이젼 | 4차 buff | 소실 | Fade | 586 | high |
| 134080 | 사이펀 바이탈리티 | 4차 passive | 신의 권능: 보호막 | Power Word: Shield | 17 | high |
| 134070 | 스로잉 엑스퍼트 | 4차 passive | 정신력 | Mental Strength | 18551 | medium |
| 134090 | 다크니스 블레싱 | 4차 passive | 어둠의 보호 | Shadow Protection | 976 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 130010 | 럭키 세븐 - 피해 | 12 | 타오르는 빛 1 | 14909 | medium | talent |
| 130020 | 럭키 세븐 - 대상 | 15 | 타오르는 빛 2 | 14909 | medium | talent |
| 130030 | 럭키 세븐 - 피해 | 19 | 타오르는 빛 3 | 14909 | medium | talentExtraRank |
| 130040 | 럭키 세븐 - 대상 | 22 | 타오르는 빛 4 | 14909 | medium | talentExtraRank |
| 130050 | 럭키 세븐 - 피해 | 26 | 타오르는 빛 5 | 14909 | medium | talentExtraRank |
| 130060 | 트리플 스로우 - 피해 | 32 | 신성한 불꽃 숙련 1 | 14914 | high | generated |
| 130070 | 트리플 스로우 - 대상 | 37 | 신성한 불꽃 숙련 2 | 14914 | high | generated |
| 130080 | 트리플 스로우 - 피해 | 42 | 신성한 불꽃 숙련 3 | 14914 | high | generated |
| 130090 | 트리플 스로우 - 보스 몬스터 피해 | 47 | 신성한 불꽃 숙련 4 | 14914 | high | generated |
| 130100 | 트리플 스로우 - 피해 | 52 | 신성한 불꽃 숙련 5 | 14914 | high | generated |
| 130110 | 트리플 스로우 - 타격 | 56 | 신성한 불꽃 숙련 6 | 14914 | high | generated |
| 130120 | 쿼드러플 스로우 - 피해 | 62 | 정신 분열 연마 1 | 15273 | high | talent |
| 130130 | 쿼드러플 스로우 - 피해 | 66 | 정신 분열 연마 2 | 15273 | high | talent |
| 130140 | 쿼드러플 스로우 - 보스 몬스터 피해 | 71 | 정신 분열 연마 3 | 15273 | high | talent |
| 130150 | 쿼드러플 스로우 - 피해 | 76 | 정신 분열 연마 4 | 15273 | high | talent |
| 130160 | 쿼드러플 스로우 - 피해 | 80 | 정신 분열 연마 5 | 15273 | high | talent |
| 130170 | 쿼드러플 스로우 - 보스 몬스터 피해 | 84 | 정신 분열 연마 6 | 15273 | high | talentExtraRank |
| 130180 | 쿼드러플 스로우 - 피해 | 88 | 정신 분열 연마 7 | 15273 | high | talentExtraRank |
| 130190 | 쿼드러플 스로우 - 피해 | 92 | 정신 분열 연마 8 | 15273 | high | talentExtraRank |
| 130200 | 쿼드러플 스로우 - 타격 | 96 | 정신 분열 연마 9 | 15273 | high | talentExtraRank |
| 130210 | 퀸터플 스로우 - 피해 | 102 | 정신의 채찍 숙련 1 | 15407 | high | generated |
| 130220 | 퀸터플 스로우 - 피해 | 106 | 정신의 채찍 숙련 2 | 15407 | high | generated |
| 130230 | 퀸터플 스로우 - 보스 몬스터 피해 | 111 | 정신의 채찍 숙련 3 | 15407 | high | generated |
| 130240 | 퀸터플 스로우 - 피해 | 116 | 정신의 채찍 숙련 4 | 15407 | high | generated |
| 130250 | 퀸터플 스로우 - 피해 | 120 | 정신의 채찍 숙련 5 | 15407 | high | generated |
| 130260 | 퀸터플 스로우 - 보스 몬스터 피해 | 124 | 정신의 채찍 숙련 6 | 15407 | high | generated |
| 130270 | 퀸터플 스로우 - 피해 | 128 | 정신의 채찍 숙련 7 | 15407 | high | generated |
| 130280 | 퀸터플 스로우 - 피해 | 132 | 정신의 채찍 숙련 8 | 15407 | high | generated |
| 130290 | 퀸터플 스로우 - 타격 | 136 | 정신의 채찍 숙련 9 | 15407 | high | generated |
| 130015 | 주스탯 강화 | 14 | 꺾이지 않는 의지 | 14522 | medium | talent |
| 130025 | 크리티컬 확률 강화 | 17 | 신성 전문화 | 14889 | medium | talent |
| 130035 | 엘리멘트 : 다크니스 - 지속 | 21 | 어둠의 형상 숙련 | 15473 | high | generated |
| 130045 | 쉐도우 배트 - 확률 | 24 | 어둠의 권능: 고통 숙련 | 589 | high | generated |
| 130055 | 기본 공격 데미지 강화 | 28 | 고요한 결의 | 14523 | medium | talent |
| 130065 | 명중 강화 | 34 | 침묵 | 15487 | high | talent |
| 130075 | 스타더스트 - 피해 | 39 | 별조각 숙련 1 | 10797 | high | generated |
| 130085 | 배트 커뮤니온 - 피해 | 44 | 어둠의 권능: 고통 연마 숙련 | 15275 | high | generated |
| 130095 | 스타더스트 - 기절 | 49 | 별조각 숙련 2 | 10797 | high | generated |
| 130105 | 다크니스 어뎁팅 - 중첩 | 54 | 어둠의 그물 숙련 | 15257 | high | generated |
| 130115 | 최대 데미지 배율 강화 | 58 | 순교 | 14531 | medium | talent |
| 130125 | 기본 공격 대상 수 강화 | 64 | 신성한 폭발 | 15237 | high | talent |
| 130135 | 쉐도우 서번트 - 기본 공격 데미지 | 68 | 정신 지배 숙련 1 | 605 | high | generated |
| 130145 | 배트 커뮤니온 II - 피해 | 73 | 암흑 숙련 1 | 15268 | high | generated |
| 130155 | 다크니스 어센션 - 재사용 | 78 | 흡혈의 선물 숙련 | 15286 | high | generated |
| 130165 | 다크니스 어뎁팅 II - 피해 | 82 | 어둠 숙련 | 15259 | high | generated |
| 130175 | 스킬 데미지 강화 | 86 | 명상 | 14521 | medium | talent |
| 130185 | 쉐도우 모멘텀 - 공격력 | 90 | 영혼의 갈취 숙련 | 15270 | high | generated |
| 130195 | 배트 커뮤니온 II - 대상 | 94 | 암흑 숙련 2 | 15268 | high | generated |
| 130205 | 스피릿 스로잉 - 최종 데미지 | 98 | 내면의 열정 숙련 | 588 | high | generated |
| 130215 | 쉐도우 서번트 - 지속 | 104 | 정신 지배 숙련 2 | 605 | high | generated |
| 130225 | 다크니스 오멘 - 소환 주기 | 108 | 영혼의 절규 연마 1 | 15392 | medium | talent |
| 130235 | 쉐도우 스티치 - 피해 | 113 | 파멸의 역병 숙련 | 2944 | high | generated |
| 130245 | 배트 커뮤니온 III - 강화 | 118 | 어둠의 손길 숙련 1 | 17322 | medium | generated |
| 130255 | 다크니스 어뎁팅 III - 강화 | 122 | 흡혈의 선물 연마 숙련 1 | 27839 | medium | generated |
| 130265 | 다크니스 이베이젼 - 지속 | 126 | 소실 연마 | 15274 | medium | talent |
| 130275 | 다크니스 오멘 - 추가 소환 | 130 | 영혼의 절규 연마 2 | 15392 | medium | talent |
| 130285 | 다크니스 어뎁팅 III - 약화 | 134 | 흡혈의 선물 연마 숙련 2 | 27839 | medium | generated |
| 130295 | 배트 커뮤니온 III - 추가 공격 | 138 | 어둠의 손길 숙련 2 | 17322 | medium | generated |

## 윈드브레이커 → 조화 드루이드 (Balance Druid)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 141010 | 브리즈 애로우 | 1차 BA | 천벌 | Wrath | 5176 | high |
| 9001 | 엘리멘탈 하모니 | 0차 buff | 여행 변신 | Travel Form | 783 | high |
| 141020 | 거스트 쉬프트 | 1차 passive | 순간이동: 달의 숲 | Teleport: Moonglade | 18960 | high |
| 141040 | 위스퍼 오브 더 윈드 | 1차 passive | 자연의 손길 | Nature's Reach | 16819 | medium |
| 141030 | 엘리멘트 : 스톰 | 1차 buff | 달빛야수 변신 | Moonkin Form | 24858 | high |
| 142010 | 거스트 샷 | 2차 BA | 달빛 섬광 | Moonfire | 8921 | high |
| 142040 | 보우 액셀레이션 | 2차 passive | 자연의 신속함 | Nature's Swiftness | 17116 | high |
| 142020 | 스파이럴 볼텍스 | 2차 active | 휘감는 뿌리 | Entangling Roots | 339 | high |
| 142080 | 피지컬 트레이닝 | 2차 passive | 자연의 무기 | Natural Weapons | 16902 | medium |
| 142050 | 트라이플링 윔 I | 2차 passive | 청명의 전조 | Omen of Clarity | 16864 | high |
| 142060 | 보우 마스터리 | 2차 passive | 자연의 집중 | Nature's Focus | 17063 | medium |
| 142070 | 실프스 에이드 | 2차 passive | 야생의 징표 | Mark of the Wild | 1126 | high |
| 142030 | 윈드워크 | 2차 buff | 질주 | Dash | 1850 | high |
| 143010 | 서리바람의 군무 | 3차 BA | 곤충 떼 | Insect Swarm | 5570 | high |
| 143080 | 닷지 | 3차 passive | 나무 껍질 | Barkskin | 22812 | high |
| 143020 | 핀포인트 피어스 | 3차 active | 요정의 불꽃 | Faerie Fire | 770 | high |
| 143040 | 트라이플링 윔 II | 3차 passive | 복수 | Vengeance | 16909 | high |
| 143030 | 에메랄드 플라워 | 3차 buff | 자연의 손아귀 | Nature's Grasp | 16689 | high |
| 143070 | 세컨드 윈드 | 3차 passive | 자연의 은총 | Nature's Grace | 16880 | high |
| 143060 | 페더리니스 | 3차 passive | 달의 격노 | Moonfury | 16896 | high |
| 143050 | 알바트로스 | 3차 passive | 달빛 | Moonglow | 16845 | high |
| 144010 | 페어리 턴 | 4차 BA | 별빛 화살 | Starfire | 2912 | high |
| 144100 | 시그너스 나이츠 | 4차 passive | 가시 | Thorns | 467 | high |
| 144020 | 천공의 노래 | 4차 active | 허리케인 | Hurricane | 16914 | high |
| 144050 | 트라이플링 윔 III | 4차 passive | 타고난 변신술사 | Natural Shapeshifter | 16833 | medium |
| 144080 | 에메랄드 더스트 | 4차 passive | 자연의 손아귀 연마 | Improved Nature's Grasp | 17245 | medium |
| 144040 | 스톰 브링어 | 4차 passive | 별빛 화살 연마 | Improved Starfire | 16850 | high |
| 144030 | 샤프 아이즈 | 4차 buff | 야생의 선물 | Gift of the Wild | 21849 | high |
| 144060 | 윈드 블레싱 | 4차 passive | 회복 | Rejuvenation | 774 | high |
| 144070 | 보우 엑스퍼트 | 4차 passive | 격노 | Furor | 17056 | medium |
| 144090 | 알바트로스 맥시멈 | 4차 passive | 정신 자극 | Innervate | 29166 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 140010 | 브리즈 애로우 - 피해 | 12 | 천벌 연마 1 | 16814 | high | talent |
| 140020 | 브리즈 애로우 - 대상 | 15 | 천벌 연마 2 | 16814 | high | talent |
| 140030 | 브리즈 애로우 - 피해 | 19 | 천벌 연마 3 | 16814 | high | talent |
| 140040 | 브리즈 애로우 - 대상 | 22 | 천벌 연마 4 | 16814 | high | talent |
| 140050 | 브리즈 애로우 - 피해 | 26 | 천벌 연마 5 | 16814 | high | talent |
| 140060 | 거스트 샷 - 피해 | 32 | 달빛 섬광 연마 1 | 16821 | high | talent |
| 140070 | 거스트 샷 - 대상 | 37 | 달빛 섬광 연마 2 | 16821 | high | talent |
| 140080 | 거스트 샷 - 피해 | 42 | 달빛 섬광 연마 3 | 16821 | high | talent |
| 140090 | 거스트 샷 - 보스 몬스터 피해 | 47 | 달빛 섬광 연마 4 | 16821 | high | talent |
| 140100 | 거스트 샷 - 피해 | 52 | 달빛 섬광 연마 5 | 16821 | high | talent |
| 140110 | 거스트 샷 - 타격 | 56 | 달빛 섬광 연마 6 | 16821 | high | talentExtraRank |
| 140120 | 서리바람의 군무 - 피해 | 62 | 곤충 떼 숙련 1 | 5570 | high | generated |
| 140130 | 서리바람의 군무 - 피해 | 66 | 곤충 떼 숙련 2 | 5570 | high | generated |
| 140140 | 서리바람의 군무 - 보스 몬스터 피해 | 71 | 곤충 떼 숙련 3 | 5570 | high | generated |
| 140150 | 서리바람의 군무 - 피해 | 76 | 곤충 떼 숙련 4 | 5570 | high | generated |
| 140160 | 서리바람의 군무 - 피해 | 80 | 곤충 떼 숙련 5 | 5570 | high | generated |
| 140170 | 서리바람의 군무 - 보스 몬스터 피해 | 84 | 곤충 떼 숙련 6 | 5570 | high | generated |
| 140180 | 서리바람의 군무 - 피해 | 88 | 곤충 떼 숙련 7 | 5570 | high | generated |
| 140190 | 서리바람의 군무 - 피해 | 92 | 곤충 떼 숙련 8 | 5570 | high | generated |
| 140200 | 서리바람의 군무 - 타격 | 96 | 곤충 떼 숙련 9 | 5570 | high | generated |
| 140210 | 페어리 턴 - 피해 | 102 | 별빛 화살 숙련 1 | 2912 | high | generated |
| 140220 | 페어리 턴 - 피해 | 106 | 별빛 화살 숙련 2 | 2912 | high | generated |
| 140230 | 페어리 턴 - 보스 몬스터 피해 | 111 | 별빛 화살 숙련 3 | 2912 | high | generated |
| 140240 | 페어리 턴 - 피해 | 116 | 별빛 화살 숙련 4 | 2912 | high | generated |
| 140250 | 페어리 턴 - 피해 | 120 | 별빛 화살 숙련 5 | 2912 | high | generated |
| 140260 | 페어리 턴 - 보스 몬스터 피해 | 124 | 별빛 화살 숙련 6 | 2912 | high | generated |
| 140270 | 페어리 턴 - 피해 | 128 | 별빛 화살 숙련 7 | 2912 | high | generated |
| 140280 | 페어리 턴 - 피해 | 132 | 별빛 화살 숙련 8 | 2912 | high | generated |
| 140290 | 페어리 턴 - 타격 | 136 | 별빛 화살 숙련 9 | 2912 | high | generated |
| 140015 | 주스탯 강화 | 14 | 야생의 심장 | 17003 | high | talent |
| 140025 | 크리티컬 확률 강화 | 17 | 날카로운 발톱 | 16942 | high | talent |
| 140035 | 엘리멘트 : 스톰 - 지속 | 21 | 달빛야수 변신 숙련 | 24858 | high | generated |
| 140045 | 위스퍼 오브 더 윈드 - 공격력 | 24 | 자연의 손길 숙련 | 16819 | medium | generated |
| 140055 | 기본 공격 데미지 강화 | 28 | 야생의 징표 연마 | 17050 | medium | talent |
| 140065 | 명중 강화 | 34 | 미묘함 | 17118 | medium | talent |
| 140075 | 스파이럴 볼텍스 - 피해 | 39 | 휘감는 뿌리 연마 1 | 16918 | medium | talent |
| 140085 | 트라이플링 윔 I - 피해 | 44 | 청명의 전조 숙련 | 16864 | high | generated |
| 140095 | 스파이럴 볼텍스 - 기절 | 49 | 휘감는 뿌리 연마 2 | 16918 | medium | talent |
| 140105 | 윈드워크 - 가속 | 54 | 질주 숙련 | 1850 | high | generated |
| 140115 | 최대 데미지 배율 강화 | 58 | 자연의 선물 | 17104 | medium | talent |
| 140125 | 기본 공격 대상 수 강화 | 64 | 가시 연마 | 16836 | medium | talent |
| 140135 | 핀포인트 피어스 - 피해 | 68 | 요정의 불꽃 숙련 1 | 770 | high | generated |
| 140145 | 트라이플링 윔 II - 피해 | 73 | 복수 숙련 1 | 16909 | high | generated |
| 140155 | 에메랄드 플라워 - 재사용 | 78 | 자연의 손아귀 숙련 | 16689 | high | generated |
| 140165 | 세컨드 윈드 - 중첩 | 82 | 자연의 은총 숙련 | 16880 | high | generated |
| 140175 | 스킬 데미지 강화 | 86 | 평온한 정신 | 24968 | medium | talent |
| 140185 | 트라이플링 윔 II - 확률 | 90 | 복수 숙련 2 | 16909 | high | generated |
| 140195 | 핀포인트 피어스 - 약화 | 94 | 요정의 불꽃 숙련 2 | 770 | high | generated |
| 140205 | 페더리니스 - 보스 몬스터 데미지 | 98 | 달의 격노 숙련 | 16896 | high | generated |
| 140215 | 트라이플링 윔 II - 추가 생성 | 104 | 복수 숙련 3 | 16909 | high | generated |
| 140225 | 천공의 노래 - 피해 | 108 | 허리케인 숙련 1 | 16914 | high | generated |
| 140235 | 트라이플링 윔 III - 강화 | 113 | 타고난 변신술사 숙련 1 | 16833 | medium | generated |
| 140245 | 에메랄드 더스트 - 최종 데미지 | 118 | 자연의 손아귀 연마 숙련 | 17245 | medium | generated |
| 140255 | 스톰 브링어 - 피해 | 122 | 별빛 화살 연마 숙련 1 | 16850 | high | generated |
| 140265 | 샤프 아이즈 - 지속 | 126 | 야생의 선물 숙련 | 21849 | high | generated |
| 140275 | 트라이플링 윔 III - 추가 생성 | 130 | 타고난 변신술사 숙련 2 | 16833 | medium | generated |
| 140285 | 천공의 노래 - 추가 생성 | 134 | 허리케인 숙련 2 | 16914 | high | generated |
| 140295 | 스톰 브링어 - 확률 | 138 | 별빛 화살 연마 숙련 2 | 16850 | high | generated |

## 플레임위자드 → 화염 마법사 (Fire Mage)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 151010 | 오비탈 플레임 | 1차 BA | 화염구 | Fireball | 133 | high |
| 9001 | 엘리멘탈 하모니 | 0차 buff | 냉정 | Presence of Mind | 12043 | high |
| 151030 | 파이어워크 | 1차 passive | 저속 낙하 | Slow Fall | 130 | high |
| 151040 | 불의 반발력 | 1차 passive | 화염 계열 수호 | Fire Ward | 543 | high |
| 151020 | 엘리멘트 : 플레임 | 1차 buff | 신비의 마법 강화 | Arcane Power | 12042 | high |
| 152010 | 오비탈 플레임 II | 2차 BA | 불태우기 | Scorch | 2948 | high |
| 152040 | 북 오브 파이어 | 2차 passive | 불타는 영혼 | Burning Soul | 11083 | high |
| 152020 | 플레임 볼텍스 | 2차 active | 신비한 폭발 | Arcane Explosion | 1449 | high |
| 152050 | 번 앤 레스트 | 2차 passive | 원소의 대가 | Master of Elements | 29074 | medium |
| 152060 | 엘리멘트 : 플레임 II | 2차 passive | 화염 마법 강화 | Fire Power | 11124 | high |
| 152070 | 주문 연마 | 2차 passive | 화염 투척 | Flame Throwing | 11100 | high |
| 152080 | 오비탈 익스플로젼 | 2차 passive | 충격 | Impact | 11103 | high |
| 152030 | 파이어 블링크 | 2차 buff | 점멸 | Blink | 1953 | high |
| 153010 | 오비탈 플레임 III | 3차 BA | 화염 작렬 | Fire Blast | 2136 | high |
| 153040 | 스피릿 오브 플레임 | 3차 buff | 변이 | Polymorph | 118 | high |
| 153020 | 플레임 템페스타 | 3차 active | 화염 폭풍 | Blast Wave | 11113 | high |
| 153050 | 번뜩이는 깨달음 | 3차 passive | 신비한 집중 | Arcane Concentration | 11213 | high |
| 153030 | 마엘스트롬 | 3차 active | 얼음 회오리 | Frost Nova | 122 | high |
| 153060 | 약점 분석 | 3차 passive | 치명타 증가 | Critical Mass | 11115 | high |
| 153070 | 엘리멘트 : 플레임 III | 3차 passive | 소각 | Incinerate | 18459 | medium |
| 153080 | 해방된 마력 | 3차 passive | 신비한 정신 | Arcane Mind | 11232 | high |
| 154010 | 오비탈 플레임 IV | 4차 BA | 불덩이 작렬 | Pyroblast | 11366 | high |
| 154100 | 시그너스 나이츠 | 4차 passive | 신비한 지능 | Arcane Intellect | 1459 | high |
| 154020 | 블레이징 익스팅션 | 4차 active | 발화 | Combustion | 11129 | high |
| 154030 | 엘리멘트 : 플레임 IV | 4차 passive | 신비한 불안정 | Arcane Instability | 15058 | high |
| 154060 | 본 피닉스 | 4차 passive | 얼음 방패 | Ice Block | 11958 | high |
| 154070 | 인페르노라이즈 | 4차 active | 불기둥 | Flamestrike | 2120 | high |
| 154040 | 버닝 리젼 | 4차 buff | 마법 증폭 | Amplify Magic | 1008 | high |
| 154080 | 플레임 배리어 | 4차 passive | 마나 보호막 | Mana Shield | 1463 | high |
| 154090 | 마법의 진리 | 4차 passive | 신비한 섬세함 | Arcane Subtlety | 11210 | medium |
| 154050 | 꺼지지 않는 화염 | 4차 passive | 작열 | Ignite | 11119 | high |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 150010 | 오비탈 플레임 - 피해 | 12 | 화염구 연마 1 | 11069 | high | talent |
| 150020 | 오비탈 플레임 - 대상 | 15 | 화염구 연마 2 | 11069 | high | talent |
| 150030 | 오비탈 플레임 - 피해 | 19 | 화염구 연마 3 | 11069 | high | talent |
| 150040 | 오비탈 플레임 - 대상 | 22 | 화염구 연마 4 | 11069 | high | talent |
| 150050 | 오비탈 플레임 - 피해 | 26 | 화염구 연마 5 | 11069 | high | talent |
| 150060 | 오비탈 플레임 II - 피해 | 32 | 불태우기 연마 1 | 11095 | high | talent |
| 150070 | 오비탈 플레임 II - 대상 | 37 | 불태우기 연마 2 | 11095 | high | talent |
| 150080 | 오비탈 플레임 II - 피해 | 42 | 불태우기 연마 3 | 11095 | high | talent |
| 150090 | 오비탈 플레임 II - 보스 몬스터 피해 | 47 | 불태우기 연마 4 | 11095 | high | talentExtraRank |
| 150100 | 오비탈 플레임 II - 피해 | 52 | 불태우기 연마 5 | 11095 | high | talentExtraRank |
| 150110 | 오비탈 플레임 II - 타격 | 56 | 불태우기 연마 6 | 11095 | high | talentExtraRank |
| 150120 | 오비탈 플레임 III - 피해 | 62 | 화염 작렬 연마 1 | 11078 | high | talent |
| 150130 | 오비탈 플레임 III - 피해 | 66 | 화염 작렬 연마 2 | 11078 | high | talent |
| 150140 | 오비탈 플레임 III - 보스 몬스터 피해 | 71 | 화염 작렬 연마 3 | 11078 | high | talent |
| 150150 | 오비탈 플레임 III - 피해 | 76 | 화염 작렬 연마 4 | 11078 | high | talentExtraRank |
| 150160 | 오비탈 플레임 III - 피해 | 80 | 화염 작렬 연마 5 | 11078 | high | talentExtraRank |
| 150170 | 오비탈 플레임 III - 보스 몬스터 피해 | 84 | 화염 작렬 연마 6 | 11078 | high | talentExtraRank |
| 150180 | 오비탈 플레임 III - 피해 | 88 | 화염 작렬 연마 7 | 11078 | high | talentExtraRank |
| 150190 | 오비탈 플레임 III - 피해 | 92 | 화염 작렬 연마 8 | 11078 | high | talentExtraRank |
| 150200 | 오비탈 플레임 III - 타격 | 96 | 화염 작렬 연마 9 | 11078 | high | talentExtraRank |
| 150210 | 오비탈 플레임 IV - 피해 | 102 | 불덩이 작렬 숙련 1 | 11366 | high | generated |
| 150220 | 오비탈 플레임 IV - 피해 | 106 | 불덩이 작렬 숙련 2 | 11366 | high | generated |
| 150230 | 오비탈 플레임 IV - 보스 몬스터 피해 | 111 | 불덩이 작렬 숙련 3 | 11366 | high | generated |
| 150240 | 오비탈 플레임 IV - 피해 | 116 | 불덩이 작렬 숙련 4 | 11366 | high | generated |
| 150250 | 오비탈 플레임 IV - 피해 | 120 | 불덩이 작렬 숙련 5 | 11366 | high | generated |
| 150260 | 오비탈 플레임 IV - 보스 몬스터 피해 | 124 | 불덩이 작렬 숙련 6 | 11366 | high | generated |
| 150270 | 오비탈 플레임 IV - 피해 | 128 | 불덩이 작렬 숙련 7 | 11366 | high | generated |
| 150280 | 오비탈 플레임 IV - 피해 | 132 | 불덩이 작렬 숙련 8 | 11366 | high | generated |
| 150290 | 오비탈 플레임 IV - 타격 | 136 | 불덩이 작렬 숙련 9 | 11366 | high | generated |
| 150015 | 주스탯 강화 | 14 | 신비한 명상 | 18462 | medium | talent |
| 150025 | 크리티컬 확률 강화 | 17 | 신비한 집중력 | 11222 | medium | talent |
| 150035 | 엘리멘트 : 플레임 - 지속 | 21 | 신비의 마법 강화 숙련 | 12042 | high | generated |
| 150045 | 불의 반발력 - 공격력 | 24 | 화염 계열 수호 숙련 | 543 | high | generated |
| 150055 | 기본 공격 데미지 강화 | 28 | 화염 계열 수호 연마 | 11094 | medium | talent |
| 150065 | 명중 강화 | 34 | 원소 정밀성 | 29438 | medium | talent |
| 150075 | 플레임 볼텍스 - 피해 | 39 | 신비한 폭발 숙련 | 1449 | high | generated |
| 150085 | 엘리멘트 : 플레임 II - 데미지 | 44 | 화염 마법 강화 숙련 | 11124 | high | generated |
| 150095 | 번 앤 레스트 - MP 부스트 | 49 | 원소의 대가 숙련 | 29074 | medium | generated |
| 150105 | 오비탈 익스플로젼 - 피해 | 54 | 충격 숙련 | 11103 | high | generated |
| 150115 | 최대 데미지 배율 강화 | 58 | 얼음 파편 | 11207 | high | talent |
| 150125 | 기본 공격 대상 수 강화 | 64 | 신비한 폭발 연마 | 11242 | medium | talent |
| 150135 | 플레임 템페스타 - 피해 | 68 | 화염 폭풍 숙련 1 | 11113 | high | generated |
| 150145 | 스피릿 오브 플레임 - 라이온 | 73 | 변이 숙련 1 | 118 | high | generated |
| 150155 | 마엘스트롬 - 피해 | 78 | 얼음 회오리 연마 1 | 11165 | high | talent |
| 150165 | 엘리멘트 : 플레임 III - 스킬 데미지 | 82 | 소각 숙련 | 18459 | medium | generated |
| 150175 | 스킬 데미지 강화 | 86 | 마법 조율 | 11247 | medium | talent |
| 150185 | 플레임 템페스타 - 기절 | 90 | 화염 폭풍 숙련 2 | 11113 | high | generated |
| 150195 | 스피릿 오브 플레임 - 폭스 | 94 | 변이 숙련 2 | 118 | high | generated |
| 150205 | 마엘스트롬 - 약화 | 98 | 얼음 회오리 연마 2 | 11165 | high | talent |
| 150215 | 스피릿 오브 플레임 - 최종 데미지 | 104 | 변이 숙련 3 | 118 | high | generated |
| 150225 | 블레이징 익스팅션 - 피해 | 108 | 발화 숙련 1 | 11129 | high | generated |
| 150235 | 인페르노라이즈 - 피해 | 113 | 불기둥 연마 1 | 11108 | high | talent |
| 150245 | 본 피닉스 - 회복 | 118 | 얼음 방패 숙련 | 11958 | high | generated |
| 150255 | 버닝 리젼 - 크리티컬 데미지 | 122 | 마법 증폭 숙련 | 1008 | high | generated |
| 150265 | 블레이징 익스팅션 - 타격 주기 | 126 | 발화 숙련 2 | 11129 | high | generated |
| 150275 | 엘리멘트 : 플레임 IV - 최종 데미지 | 130 | 신비한 불안정 숙련 | 15058 | high | generated |
| 150285 | 플레임 배리어 - 공격력 | 134 | 마나 보호막 숙련 | 1463 | high | generated |
| 150295 | 인페르노라이즈 - 화신 | 138 | 불기둥 연마 2 | 11108 | high | talent |

## 소울마스터 → 징벌 성기사 (Retribution Paladin)

### 스킬 (31)

| 메이플 ID | 메이플 스킬 | 분류 | WoW 이름 | English | spellId | conf |
|---|---|---|---|---|---|---|
| 161010 | 솔라 슬래시 | 1차 BA | 정의의 문장 | Seal of Righteousness | 21084 | medium |
| 9001 | 엘리멘탈 하모니 | 0차 buff | 군마 소환 | Summon Warhorse | 13819 | high |
| 161030 | 소울 리프 | 1차 passive | 자유의 축복 | Blessing of Freedom | 1044 | high |
| 161040 | 소울 가디언 | 1차 passive | 헌신의 오라 | Devotion Aura | 465 | high |
| 161020 | 엘리멘트 : 소울 | 1차 buff | 힘의 축복 | Blessing of Might | 19740 | high |
| 162010 | 셀레스티얼 비전 | 2차 BA | 성전사의 문장 | Seal of the Crusader | 21082 | high |
| 162040 | 님블 핑거 | 2차 passive | 심판의 시간 | Reckoning | 20177 | medium |
| 162030 | 코스믹 매터 | 2차 active | 퇴마술 | Exorcism | 879 | high |
| 162050 | 피지컬 트레이닝 | 2차 passive | 양손 무기 전문화 | Two-Handed Weapon Specialization | 20111 | medium |
| 162070 | 소울 블레싱 | 2차 passive | 힘의 축복 연마 | Improved Blessing of Might | 20042 | medium |
| 162060 | 소드 마스터리 | 2차 passive | 정밀함 | Precision | 20189 | medium |
| 162020 | 솔루나 타임 | 2차 buff | 빛의 문장 | Seal of Light | 20165 | high |
| 162080 | 이너 트러스트 | 2차 passive | 응징 | Vengeance | 20049 | medium |
| 163010 | 셀레스티얼 비전 II | 3차 BA | 심판 | Judgement | 20271 | high |
| 163050 | 윌 오브 스틸 | 3차 passive | 신의 가호 | Divine Protection | 498 | high |
| 163030 | 라우드 러쉬 | 3차 active | 심판의 망치 | Hammer of Justice | 853 | high |
| 163040 | 트루 사이트 | 3차 active | 천벌 | Holy Wrath | 2812 | high |
| 163020 | 코스믹 샤워 | 3차 active | 신성화 | Consecration | 26573 | high |
| 163070 | 솔루나 마스터리 | 3차 passive | 영적 집중 | Spiritual Focus | 20205 | medium |
| 163060 | 소울 블레싱 II | 3차 passive | 확신 | Conviction | 20117 | medium |
| 163080 | 이너 샤우트 | 3차 passive | 응보의 오라 | Retribution Aura | 7294 | high |
| 164010 | 셀레스티얼 비전 III | 4차 BA | 지휘의 문장 | Seal of Command | 20375 | high |
| 164100 | 시그너스 나이츠 | 4차 passive | 왕의 축복 | Blessing of Kings | 20217 | high |
| 164030 | 솔루나 슬래시 | 4차 active | 천벌의 망치 | Hammer of Wrath | 24275 | high |
| 164040 | 소울 페네트레이션 | 4차 active | 참회 | Repentance | 20066 | high |
| 164020 | 소울 플레지 | 4차 passive | 신성의 오라 | Sanctity Aura | 20218 | high |
| 164050 | 마스터 오브 더 소드 | 4차 passive | 정당성 | Vindication | 9452 | medium |
| 164070 | 코스믹 버스트 | 4차 active | 신성 충격 | Holy Shock | 20473 | high |
| 164080 | 언포시어블 | 4차 passive | 눈에는 눈 | Eye for an Eye | 9799 | medium |
| 164090 | 소드 엑스퍼트 | 4차 passive | 은총 | Benediction | 20101 | medium |
| 164060 | 소울 블레싱 III | 4차 passive | 신성한 힘 | Divine Strength | 20262 | medium |

### 숙련 (58)

| 숙련 ID | 메이플 숙련 | Lv | WoW 이름 | spellId | conf | source |
|---|---|---|---|---|---|---|
| 160010 | 솔라 슬래시 - 피해 | 12 | 정의의 문장 연마 1 | 20224 | medium | talent |
| 160020 | 솔라 슬래시 - 대상 | 15 | 정의의 문장 연마 2 | 20224 | medium | talent |
| 160030 | 솔라 슬래시 - 피해 | 19 | 정의의 문장 연마 3 | 20224 | medium | talent |
| 160040 | 솔라 슬래시 - 대상 | 22 | 정의의 문장 연마 4 | 20224 | medium | talent |
| 160050 | 솔라 슬래시 - 피해 | 26 | 정의의 문장 연마 5 | 20224 | medium | talent |
| 160060 | 셀레스티얼 비전 - 피해 | 32 | 성전사의 문장 연마 1 | 20335 | medium | talent |
| 160070 | 셀레스티얼 비전 - 대상 | 37 | 성전사의 문장 연마 2 | 20335 | medium | talent |
| 160080 | 셀레스티얼 비전 - 피해 | 42 | 성전사의 문장 연마 3 | 20335 | medium | talent |
| 160090 | 셀레스티얼 비전 - 보스 몬스터 피해 | 47 | 성전사의 문장 연마 4 | 20335 | medium | talentExtraRank |
| 160100 | 셀레스티얼 비전 - 피해 | 52 | 성전사의 문장 연마 5 | 20335 | medium | talentExtraRank |
| 160110 | 셀레스티얼 비전 - 타격 | 56 | 성전사의 문장 연마 6 | 20335 | medium | talentExtraRank |
| 160120 | 셀레스티얼 비전 II - 피해 | 62 | 심판 연마 1 | 25956 | low | talent |
| 160130 | 셀레스티얼 비전 II - 피해 | 66 | 심판 연마 2 | 25956 | low | talent |
| 160140 | 셀레스티얼 비전 II - 보스 몬스터 피해 | 71 | 심판 연마 3 | 25956 | low | talentExtraRank |
| 160150 | 셀레스티얼 비전 II - 피해 | 76 | 심판 연마 4 | 25956 | low | talentExtraRank |
| 160160 | 셀레스티얼 비전 II - 피해 | 80 | 심판 연마 5 | 25956 | low | talentExtraRank |
| 160170 | 셀레스티얼 비전 II - 보스 몬스터 피해 | 84 | 심판 연마 6 | 25956 | low | talentExtraRank |
| 160180 | 셀레스티얼 비전 II - 피해 | 88 | 심판 연마 7 | 25956 | low | talentExtraRank |
| 160190 | 셀레스티얼 비전 II - 피해 | 92 | 심판 연마 8 | 25956 | low | talentExtraRank |
| 160200 | 셀레스티얼 비전 II - 타격 | 96 | 심판 연마 9 | 25956 | low | talentExtraRank |
| 160210 | 셀레스티얼 비전 III - 피해 | 102 | 지휘의 문장 숙련 1 | 20375 | high | generated |
| 160220 | 셀레스티얼 비전 III - 피해 | 106 | 지휘의 문장 숙련 2 | 20375 | high | generated |
| 160230 | 셀레스티얼 비전 III - 보스 몬스터 피해 | 111 | 지휘의 문장 숙련 3 | 20375 | high | generated |
| 160240 | 셀레스티얼 비전 III - 피해 | 116 | 지휘의 문장 숙련 4 | 20375 | high | generated |
| 160250 | 셀레스티얼 비전 III - 피해 | 120 | 지휘의 문장 숙련 5 | 20375 | high | generated |
| 160260 | 셀레스티얼 비전 III - 보스 몬스터 피해 | 124 | 지휘의 문장 숙련 6 | 20375 | high | generated |
| 160270 | 셀레스티얼 비전 III - 피해 | 128 | 지휘의 문장 숙련 7 | 20375 | high | generated |
| 160280 | 셀레스티얼 비전 III - 피해 | 132 | 지휘의 문장 숙련 8 | 20375 | high | generated |
| 160290 | 셀레스티얼 비전 III - 타격 | 136 | 지휘의 문장 숙련 9 | 20375 | high | generated |
| 160015 | 주스탯 강화 | 14 | 신성한 지능 | 20257 | medium | talent |
| 160025 | 크리티컬 확률 강화 | 17 | 신성 마법 강화 | 5923 | medium | talent |
| 160055 | 기본 공격 데미지 강화 | 28 | 한손 무기 전문화 | 20196 | medium | talent |
| 160065 | 명중 강화 | 34 | 예지 | 20096 | medium | talent |
| 160115 | 최대 데미지 배율 강화 | 58 | 굴절 | 20060 | medium | talent |
| 160125 | 기본 공격 대상 수 강화 | 64 | 응보의 오라 연마 | 20091 | medium | talent |
| 160175 | 스킬 데미지 강화 | 86 | 치유의 빛 | 20237 | medium | talent |
| 160035 | 엘리멘트 : 소울 - 지속 | 21 | 힘의 축복 숙련 | 19740 | high | generated |
| 160045 | 소울 가디언 - 공격력 | 24 | 헌신의 오라 연마 | 20138 | medium | talent |
| 160075 | 코스믹 매터 - 피해 | 39 | 퇴마술 숙련 | 879 | high | generated |
| 160085 | 님블 핑거 - 속도 | 44 | 심판의 시간 숙련 | 20177 | medium | generated |
| 160095 | 솔루나 타임 - 대상 | 49 | 빛의 문장 숙련 1 | 20165 | high | generated |
| 160105 | 솔루나 타임 - 지속 | 54 | 빛의 문장 숙련 2 | 20165 | high | generated |
| 160135 | 라우드 러쉬 - 피해 | 68 | 심판의 망치 연마 1 | 20487 | medium | talent |
| 160145 | 코스믹 샤워 - 피해 | 73 | 신성화 숙련 1 | 26573 | high | generated |
| 160155 | 트루 사이트 - 피해 | 78 | 천벌 숙련 1 | 2812 | high | generated |
| 160165 | 소울 블레싱 II - 크리티컬 데미지 | 82 | 확신 숙련 | 20117 | medium | generated |
| 160185 | 라우드 러쉬 - 재사용 | 90 | 심판의 망치 연마 2 | 20487 | medium | talent |
| 160195 | 솔루나 마스터리 - 피해 | 94 | 영적 집중 숙련 | 20205 | medium | generated |
| 160205 | 트루 사이트 - 재사용 | 98 | 천벌 숙련 2 | 2812 | high | generated |
| 160215 | 코스믹 샤워 - 타격 주기 | 104 | 신성화 숙련 2 | 26573 | high | generated |
| 160225 | 솔루나 슬래시 - 피해 | 108 | 천벌의 망치 숙련 1 | 24275 | high | generated |
| 160235 | 소울 페네트레이션 - 피해 | 113 | 참회 숙련 1 | 20066 | high | generated |
| 160245 | 마스터 오브 더 소드 - 강화 | 118 | 정당성 숙련 1 | 9452 | medium | generated |
| 160255 | 코스믹 버스트 - 피해 | 122 | 신성 충격 숙련 | 20473 | high | generated |
| 160265 | 솔루나 슬래시 - 재사용 & 대상 | 126 | 천벌의 망치 숙련 2 | 24275 | high | generated |
| 160275 | 소울 블레싱 III - 강화 | 130 | 신성한 힘 숙련 | 20262 | medium | generated |
| 160285 | 마스터 오브 더 소드 - 최종 데미지 | 134 | 정당성 숙련 2 | 9452 | medium | generated |
| 160295 | 소울 페네트레이션 - 약화 | 138 | 참회 숙련 2 | 20066 | high | generated |

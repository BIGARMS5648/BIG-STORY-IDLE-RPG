# World map skin (WoW: Forever, vanilla)

Source of truth: `world-map.json` (same folder). IDs cross-checked against AzerothCore creature_template / creature_template_model / koKR locale; displayIds from TBC/WotLK remodels (>16700) were nulled so the addon falls back to `SetCreature(npcId)`.

Order: ch1-28 open-world zones by level, ch29-40 dungeons by level, ch41-47 raids. Loading screens: 1.x 5-man dungeons and zones use the continent screen (`LoadScreenEasternKingdom` / `LoadScreenKalimdor`).

| Ch | St/maxVar | Zone (KO / EN) | Hunting monsters (KO, first maxVar used) | Boss (KO / EN, npcId) | Loading screen |
|---|---|---|---|---|---|
| 1 | 4/4 | 엘윈 숲 / Elwynn Forest | 코볼트 졸개, 데피아즈단원, 숲거미, 돌엄니멧돼지, 멀록 길잡이 | 들창코 / Hogger (448) | LoadScreenEasternKingdom |
| 2 | 8/3 | 듀로타 / Durotar | 점박이멧돼지, 일꾼전갈, 악마의 하수인, 서슬갈기 가시멧돼지, 채찍꼬리 붉은발톱랩터 | 잘라제인 / Zalazane (3205) | LoadScreenKalimdor |
| 3 | 10/3 | 던 모로 / Dun Morogh | 바위턱트로그, 새끼 겨울늑대, 웬디고, 얼음발톱흰곰, 오염된 노움 | 바가쉬 / Vagash (1388) | LoadScreenEasternKingdom |
| 4 | 10/3 | 티리스팔 숲 / Tirisfal Glades | 넋 나간 좀비, 덜그럭거리는 해골, 새끼 검은그물거미, 그늘박쥐, 붉은십자군 전사 | 데블린 아가만드 / Devlin Agamand (1657) | LoadScreenEasternKingdom |
| 5 | 10/3 | 서부 몰락지대 / Westfall | 허수아비골렘, 데피아즈단 덫사냥꾼, 갈퀴발 놀, 멀록 길잡이, 뿔엄니멧돼지 | 전투 절단기 4000 / Foe Reaper 4000 (573) | LoadScreenEasternKingdom |
| 6 | 10/3 | 불모의 땅 / The Barrens | 굶주린 얼룩말, 사바나 암사자, 서슬갈기일족 가시마술사, 콜카르일족 사냥꾼, 칼날바람하피 | 사자왕 후마르 / Humar the Pridelord (5828) | LoadScreenKalimdor |
| 7 | 10/3 | 어둠해안 / Darkshore | 광포한 엉겅퀴곰, 달표범, 어둠의해안 트레샤돈, 잿빛안개멀록 점쟁이, 검은나무일족 전사 | 군주 신슬레이어 / Lord Sinslayer (7017) | LoadScreenKalimdor |
| 8 | 10/3 | 은빛소나무 숲 / Silverpine Forest | 점박이 검은늑대, 달의분노일족 백발전사, 이끼땅거미, 썩은가죽 놀, 달라란 수습마법사 | 아루갈의 후예 / Son of Arugal (2529) | LoadScreenEasternKingdom |
| 9 | 10/3 | 붉은마루 산맥 / Redridge Mountains | 붉은마루일족 싸움꾼, 붉은마루일족 투사, 타란툴라, 새끼 검은용, 검은바위부족 길잡이 | 가스일조그 / Gath'Ilzogg (334) | LoadScreenEasternKingdom |
| 10 | 10/3 | 돌발톱 산맥 / Stonetalon Mountains | 투자개발회사 나무꾼, 동굴이끼 땅거미, 사자날개 와이번, 혈폭풍하피, 난폭한 불의 정령 | 마녀 리벤 / Sister Riven (5930) | LoadScreenKalimdor |
| 11 | 10/3 | 그늘숲 / Duskwood | 파멸의어둠일족 암흑길잡이, 파멸의어둠일족 흑마술사, 새끼 그물독거미, 해골 악령, 뼈만 남은 시체 | 누더기 / Stitches (412) | LoadScreenEasternKingdom |
| 12 | 10/2 | 잿빛 골짜기 / Ashenvale | 엉겅퀴일족 복수자, 잿빛골짜기곰, 찔레가시 거미, 그늘덤불 나무현자, 암흑이교도 제사장 | 아크릴루스 / Akkrilus (3773) | LoadScreenKalimdor |
| 13 | 10/3 | 저습지 / Wetlands | 용아귀부족 약탈자, 줄무늬랩터, 푸른아가미멀록 약탈꾼, 습지악어, 수렁이끼괴물 | 족장 네크로쉬 / Chieftain Nek'rosh (2091) | LoadScreenEasternKingdom |
| 14 | 10/3 | 힐스브래드 구릉지 / Hillsbrad Foothills | 힐스브래드 농부, 회색곰, 비밀결사대 노상강도, 너덜지느러미멀록 바다사냥꾼, 덩치 큰 이끼거미 | 큰곰 삼라스 / Big Samras (14280) | LoadScreenEasternKingdom |
| 15 | 10/3 | 버섯구름 봉우리 / Thousand Needles | 갈라크일족 척후병, 그림토템부족 흙점쟁이, 바위표범, 소금바위 바실리스크, 마루둥지 와이번 | 아르낙 그림토템 / Arnak Grimtotem (10896) | LoadScreenKalimdor |
| 16 | 10/3 | 아라시 고원 / Arathi Highlands | 마른나무껍질 트롤, 돌주먹 오우거, 줄무늬 고원랩터, 절벽대머리수리, 마른수염 코볼트 | 한파의 코르그레쉬 / Kor'gresh Coldrage (2793) | LoadScreenEasternKingdom |
| 17 | 10/3 | 가시덤불 골짜기 / Stranglethorn Vale | 가시덤불랩터, 붉은머리부족 전사, 가시덤불 호랑이, 안개계곡고릴라, 붉은해적단 칼잡이 | 야수왕 뱅갈라시 / King Bangalash (731) | LoadScreenEasternKingdom |
| 18 | 10/4 | 잊혀진 땅 / Desolace | 콜카르일족 파괴자, 마그람일족 정찰꾼, 겔키스 바위정령, 스콜파시 집게전갈, 늙은 코도 | 제왕 아즈레토크 / Lord Azrethoc (5760) | LoadScreenKalimdor |
| 19 | 10/4 | 먼지진흙 습지대 / Dustwallow Marsh | 붉은늪지랩터, 암흑안개 거미, 진흙아가미멀록, 늪지악어, 진흙바위거북 | 대군주 모크모로크 / Overlord Mok'Morokk (4500) | LoadScreenKalimdor |
| 20 | 10/3 | 황야의 땅 / Badlands | 바위 정령, 대머리수리, 덩치 큰 바위산표범, 먼지목도리일족 투사, 화염의 새끼비룡 | 흑요암 / Obsidion (8400) | LoadScreenEasternKingdom |
| 21 | 10/3 | 타나리스 / Tanaris | 사막유랑단 약탈자, 모래망치 오우거, 모래언덕전갈, 불타는 로크, 유리비늘 바실리스크 | 파멸의 소리드 / Soriid the Devourer (8204) | LoadScreenKalimdor |
| 22 | 10/3 | 페랄라스 / Feralas | 골두니 오우거, 덩굴발일족 싸움꾼, 공작날개 히포그리프, 분노한 무쇠설인, 그로독 고릴라 | 아라쉬에디스 / Arash-ethis (5349) | LoadScreenKalimdor |
| 23 | 10/3 | 동부 내륙지 / The Hinterlands | 썩은가지부족 광전사, 긴발톱 은빛갈기늑대, 포악한 올빼미야수, 비취 수액괴물, 썩은가지부족 의술사 | 샤드라 / Shadra (2707) | LoadScreenEasternKingdom |
| 24 | 10/3 | 운고로 분화구 / Un'Goro Crater | 라바사우루스, 디메트로돈, 운고로 고릴라, 테러닥스, 데빌사우루스 | 폭군 모쉬 / King Mosh (6584) | LoadScreenKalimdor |
| 25 | 10/3 | 불타는 평원 / Burning Steppes | 불자루일족 오우거, 검은용혈족, 검은 새끼용, 검은바위부족 병사, 사나운 화염족 마귀 | 볼찬 / Volchan (10119) | LoadScreenEasternKingdom |
| 26 | 10/2 | 여명의 설원 / Winterspring | 눈사태일족 펄볼그, 눈호랑이, 서리바람 키메라, 얼음엉겅퀴설인, 톱니이빨곰 | 대족장 눈사태 / High Chief Winterfall (10738) | LoadScreenKalimdor |
| 27 | 10/3 | 동부 역병지대 / Eastern Plaguelands | 역병사냥개, 식인 구울, 역병박쥐, 공포의 지하마귀, 역병의 괴수 | 부패의 헤드무쉬 / Hed'mush the Rotting (10821) | LoadScreenEasternKingdom |
| 28 | 10/3 | 실리더스 / Silithus | 병정 하이브조라, 병정 하이브아쉬, 돌꼬리전갈, 황혼의 대지술사, 우레의 모래정령 | 왕자 스칼레녹스 / Prince Skaldrenox (15203) | LoadScreenKalimdor |
| 29 | 15/3 | 죽음의 폐광 / The Deadmines | 데피아즈단 광부, 데피아즈단 작업반장, 고블린 땜장이, 데피아즈단 해적, 데피아즈단 얼음마법사 | 에드윈 밴클리프 / Edwin VanCleef (639) | LoadScreenEasternKingdom |
| 30 | 15/4 | 통곡의 동굴 / Wailing Caverns | 송곳니의 드루이드, 돌연변이 약탈자랩터, 돌연변이 살무사, 돌연변이 덩굴손, 진화된 세포괴물 | 걸신들린 무타누스 / Mutanus the Devourer (3654) | LoadScreenKalimdor |
| 31 | 15/5 | 붉은십자군 수도원 / Scarlet Monastery | 붉은십자군 수도사, 붉은십자군 정예병, 붉은십자군 마술사, 절규하는 환영, 붉은십자군 용사 | 종교재판관 화이트메인 / High Inquisitor Whitemane (3977) | LoadScreenEasternKingdom |
| 32 | 15/5 | 울다만 / Uldaman | 바위동굴일족 투사, 어둠괴철로단 흑마법사, 바위 문지기, 흑요석 파수꾼, 비취돌기 바실리스크 | 아카에다스 / Archaedas (2748) | LoadScreenEasternKingdom |
| 33 | 15/5 | 줄파락 / Zul'Farrak | 성난모래부족 혈투사, 성난모래부족 흑마술사, 성난모래부족 영혼사냥꾼, 줄파락 좀비, 모래집게 술리투즈 | 가즈릴라 / Gahz'rilla (7273) | LoadScreenKalimdor |
| 34 | 15/5 | 마라우돈 / Maraudon | 셀레브라스의 드리아드, 채찍줄기 덩굴손, 태초의 거수, 텟살라 히드라, 지하 디메트로돈 | 공주 테라드라스 / Princess Theradras (12201) | LoadScreenKalimdor |
| 35 | 15/4 | 아탈학카르 신전 / Temple of Atal'Hakkar (Sunken Temple) | 아탈라이부족 전사, 아탈라이부족 의술사, 미라가 된 아탈라이트롤, 악몽의 고룡족, 축축한 수액괴물 | 에라니쿠스의 사령 / Shade of Eranikus (5709) | LoadScreenEasternKingdom |
| 36 | 15/5 | 검은바위 나락 / Blackrock Depths | 성난모루단 보초, 타오르는 화염수호정령, 뜨겁게 달궈진 전투골렘, 황혼의망치단 고문관, 덩치큰 핏빛사냥개 | 제왕 다그란 타우릿산 / Emperor Dagran Thaurissan (9019) | LoadScreenEasternKingdom |
| 37 | 15/4 | 검은바위 첨탑 / Blackrock Spire (Lower/Upper) | 가시불꽃부족 광전사, 뾰족바위일족 오우거마법사, 횃불부대 그런트, 성난발톱용혈족, 오색 새끼용 | 사령관 드라키사스 / General Drakkisath (10363) | LoadScreenEasternKingdom |
| 38 | 15/4 | 혈투의 전장 / Dire Maul | 야생혈족 도적, 고르독일족 투사, 굽이나무정령, 엘드레스 원혼, 불가사의한 피조물 | 이몰타르 / Immol'thar (11496) | LoadScreenDireMaul |
| 39 | 20/4 | 스칼로맨스 / Scholomance | 스칼로맨스 학생, 스칼로맨스 수습강령술사, 되살아난 경비병, 소생한 지하마귀, 연구원 유령 | 암흑스승 간들링 / Darkmaster Gandling (1853) | LoadScreenEasternKingdom |
| 40 | 20/3 | 스트라솔름 / Stratholme | 진홍십자군 보초, 게걸스러운 구울, 해골 수사, 투자딘 흑마술사, 독고름 누더기골렘 | 남작 리븐데어 / Baron Rivendare (10440) | LoadScreenEasternKingdom |
| 41 | 20/4 | 줄구룹 / Zul'Gurub | 구루바시부족 광전사, 구루바시부족 도끼투척병, 래즈자쉬 랩터, 학카르부족 사제, 줄리안 호랑이 | 학카르 / Hakkar (14834) | LoadScreenZulGurub |
| 42 | 20/4 | 화산 심장부 / Molten Core | 용암거인, 심장부 사냥개, 불꽃꼬리일족 전사, 굽이치는 용암 정령, 불의군주 | 라그나로스 / Ragnaros (11502) | LoadScreenMoltenCore |
| 43 | 20/2 | 오닉시아의 둥지 / Onyxia's Lair | 오닉시아의 새끼용, 오닉시아의 수호병, 오닉시아의 비룡, 화염갈기혈족 맹독전사, 화염갈기혈족 불꽃소환사 | 오닉시아 / Onyxia (10184) | LoadScreenKalimdor |
| 44 | 20/3 | 검은날개 둥지 / Blackwing Lair | 죽음의발톱 고룡수호병, 검은날개 마법사, 검은날개 부대원, 죽음의발톱 알지기, 오색용기병 | 네파리안 / Nefarian (11583) | LoadScreenBlackwingLair |
| 45 | 20/5 | 안퀴라즈 폐허 / Ruins of Ahn'Qiraj | 퀴라지 투사, 병정 하이브자라, 아누비사스 감시자, 흑요석 파괴자, 청소부 수액괴물 | 무적의 오시리안 / Ossirian the Unscarred (15339) | LoadScreenAhnQiraj (low) |
| 46 | 20/5 | 안퀴라즈 사원 / Temple of Ahn'Qiraj | 아누비사스 파수병, 퀴라지 용사, 병정 베크니스, 흑요석 파멸자, 퀴라지 세뇌관 | 쑨 / C'Thun (15727) | LoadScreenAhnQiraj (low) |
| 47 | 20/5 | 낙스라마스 / Naxxramas | 살아 움직이는 괴물, 기워 붙인 누더기골렘, 돌가죽 가고일, 청소부 그물거미, 썩은위액 누더기골렘 | 켈투자드 / Kel'Thuzad (15990) | LoadScreenNaxxramas |

## Other content

| Slot | Boss (KO / EN, npcId) | Where | Alternates |
|---|---|---|---|
| worldBoss | 군주 카자크 / Lord Kazzak (12397) | 저주받은 땅 | |
| worldBoss | 아주어고스 / Azuregos (6109) | 아즈샤라 | |
| worldBoss | 이손드레 / Ysondre (14887) | 에메랄드 꿈의 관문 (그늘숲/잿빛 골짜기/페랄라스/동부 내륙지) | |
| worldBoss | 레손 / Lethon (14888) | 에메랄드 꿈의 관문 | |
| worldBoss | 에메리스 / Emeriss (14889) | 에메랄드 꿈의 관문 | |
| worldBoss | 타에라 / Taerar (14890) | 에메랄드 꿈의 관문 | |
| raids.zakum | 라그나로스 / Ragnaros (11502) | 화산 심장부 | 청지기 이그젝큐투스 (12018) |
| raids.horntail | 오닉시아 / Onyxia (10184) | 오닉시아의 둥지 | 네파리안 (11583), 사피론 (15989) |
| raids.pinkbean | 쑨 / C'Thun (15727) | 안퀴라즈 사원 | 켈투자드 (15990) |
| dungeons.weapon | 불의군주 인센디우스 / Lord Incendius (9017) | 검은바위 나락 (검은 모루) | |
| dungeons.exp | 헤로드 / Herod (3975) | 붉은십자군 수도원 (무기고) | |
| dungeons.gear | 기계박사 텔마플러그 / Mekgineer Thermaplugg (7800) | 놈리건 | |
| dungeons.heroTraining | 조교 말리시아 / Instructor Malicia (10505) (displayId null, uses npcId) | 스칼로맨스 | |
| dungeons.enhancement | 골렘 군주 아젤마크 / Golem Lord Argelmach (8983) | 검은바위 나락 (제작소) | |

Arena backdrop: `Interface\Glues\LoadingScreens\LoadScreenWarsongGulch` (구루바시 투기장; fallback `LoadScreenEasternKingdom`).

Dummies: 훈련용 허수아비 (1921), 표적 허수아비 (2673), 고급 표적 허수아비 (2674), 일급 표적 허수아비 (12426), 박격포부대 고급 표적 허수아비 (12385), 언더시티 훈련용 허수아비 (5652), 허수아비골렘 보초 (114), 양 (1933)

Confidence: every npcId/name is verified against the creature DB (0 low). Medium = 9 (Onyxia/Naxx trash rows that AzerothCore rescaled for WotLK, Instructor Malicia with null displayId). Unverified: AQ loading screen name `LoadScreenAhnQiraj` (low, falls back to Kalimdor); other screen paths are medium. Korean names come from the koKR locale and may differ slightly in the Classic-era KR client.

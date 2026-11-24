-- 파티 퀘스트 4종 x 4난이도 (+ 탐험) and 몬스터파크 익스트림.
-- Party content is entered solo: player + 3 AI allies (party max 4 in the data).
--
-- API
--   ns.Content.PartyQuest: PQ.Enter(hero, questIndex, diffIndex) ; PQ.Expedition(hero, qi, di)
--                          PQ.IsUnlocked(hero, qi, di) -> ok, reason ; PQ.SetRepeat(hero, bool)
--   ns.Content.MonsterPark: MP.Enter(hero, stage, practice) ; MP.StarForce(hero) -> total equipped star force
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local C = ns.Content
local F = U.FormatNumber

---------------------------------------------------------------------------
-- Party quests
---------------------------------------------------------------------------
local PQ = {}
C.PartyQuest = PQ
local PD = D.ContentPartyQuests

-- PROVISIONAL (not in the data): party-quest time limit, wave size, revives and the unlock of quests
-- without a published chapter gate (dungeon level is used as the required hero level).
PQ.TIME_SEC = 300
PQ.WAVE_MOBS = 10
PQ.ALLIES = PD.partyMax - 1
-- PROVISIONAL: 탐험 (expedition) = 1 ticket -> 1 equipment of a cleared quest/difficulty.

C.RegisterState("partyQuest", {
    init = function(hero, ct)
        ct.pq = ct.pq or { cleared = {}, runs = 0, repeatOn = false }
        if not ct.pqTicketGiven then
            ct.pqTicketGiven = true
            Hero.Add(hero, "explorationTicket", PD.expeditionWeekly, "recharge")
        end
    end,
    weekly = function(hero, ct, elapsed)
        Hero.Add(hero, "explorationTicket", PD.expeditionWeekly * elapsed, "recharge")
    end,
})

local function key(qi, di) return qi .. "-" .. di end

function PQ.IsUnlocked(hero, qi, di)
    local q = PD.quests[qi]
    local dd = q and q.difficulties[di]
    if not dd then return false, "잘못된 난이도" end
    if q.id == "romeo" then
        local u = PD.unlocks.romeo
        if not C.StageReached(hero, u[1], u[2]) then return false, C.GateText(u[1], u[2]) end
        if di == 4 then
            u = PD.unlocks.romeoChaos
            if not C.StageReached(hero, u[1], u[2]) then return false, C.GateText(u[1], u[2]) end
        end
        return true
    end
    if hero.level < dd.level then return false, string.format("Lv.%d", dd.level) end
    return true
end

local PQFight = C.Proto()

local function lerp(a, b, t) return a + (b - a) * t end

function PQFight:Setup(b)
    self.wave = 0
    self:NextWave(b)
end

function PQFight:NextWave(b)
    local dd = self.dd
    local hc = b.heroCreature
    local x0 = (hc and hc.x or 0) + 1500
    local atk = dd.atkProvisional
    self.wave = self.wave + 1
    local lastWave = dd.mid and 3 or 2
    if self.wave == 1 then
        local n = self.waveMobs
        for i = 1, n do
            local t = (n > 1) and (i - 1) / (n - 1) or 0
            local nm = dd.normal
            self:Spawn(b, { name = self.mobName, hp = math.floor(lerp(nm.hpMin, nm.hpMax, t)), atk = atk.normal,
                def = math.floor(lerp(nm.defMin, nm.defMax, t)), avoid = math.floor(lerp(nm.avoidMin, nm.avoidMax, t)),
                x = x0 + i * 300, aggro = 1500, level = dd.level, tag = "mob" })
        end
    elseif self.wave == 2 and dd.mid then
        self.target = self:Spawn(b, { name = self.quest.nameKo .. " 중간보스", hp = dd.mid.hp, atk = atk.mid,
            def = dd.mid.def, avoid = dd.mid.avoid, boss = true, x = x0 + 600, level = dd.level, tag = "mid" })
    else
        self.target = self:Spawn(b, { name = self.quest.nameKo .. " 최종보스", hp = dd.boss.hp, atk = atk.boss,
            def = dd.boss.def, avoid = dd.boss.avoid, boss = true, x = x0 + 800, level = dd.level, tag = "boss" })
    end
    self.lastWave = lastWave
end

function PQFight:Tick(b)
    if self:EnemiesAlive(b) == 0 then
        if self.wave >= self.lastWave then b:End("clear") else self:NextWave(b) end
    end
end

function PQFight:UpdateTitle(b)
    self.title = string.format("%s %s · Wave %d/%d", self.quest.nameKo, self.dd.nameKo, self.wave, self.lastWave or 3)
end

-- one run's rewards: EXP (base clear, EXP% not applied) + accessory drop 25% (쉬움) / 20%
function PQ.RunRewards(qi, di, rng)
    local q = PD.quests[qi]
    local dd = q.difficulties[di]
    local out = { exp = dd.exp }
    local drop = PD.drop[dd.nameKo]
    if drop and rng:Float() * 1000 < drop.permille then
        out.gear = { { code = dd.gear, level = rng:Int(dd.itemLevel[1], dd.itemLevel[2]), source = "partyQuest",
            name = q.slotKo .. " (" .. q.nameKo .. ")" } }
    end
    return out
end

function PQFight:Finish(b, reason)
    local hero = self.hero
    local head = string.format("%s %s", self.quest.nameKo, self.dd.nameKo)
    if reason ~= "clear" then return C.Result(false, reason, head .. " " .. (C.REASON_KO[reason] or reason)) end
    local st = hero.content.pq
    local k = key(self.qi, self.di)
    st.cleared[k] = (st.cleared[k] or 0) + 1
    st.runs = (st.runs or 0) + 1
    local rewards = PQ.RunRewards(self.qi, self.di, b.rng)
    local lines = C.Grant(hero, rewards, "partyQuest")
    ns.Fire("PARTY_QUEST_CLEARED", hero, self.quest.id, self.di)
    return C.Result(true, reason, head .. " 클리어", lines, { rewards = rewards })
end

function PQFight:AfterFinish(res)
    -- auto repeat (restart estimate 15 s from party-experience-118.json)
    local hero = self.hero
    if res.ok and hero.content.pq.repeatOn and ns.Compat and ns.Compat.After and C_Timer then
        local qi, di = self.qi, self.di
        ns.Compat.After(PD.restartSec, function()
            if hero.content.pq.repeatOn and ns.Hero.Active() == hero and not C.Busy() then PQ.Enter(hero, qi, di) end
        end)
    end
end

function PQ.Enter(hero, qi, di)
    local ok, why = PQ.IsUnlocked(hero, qi, di)
    if not ok then return nil, why .. " 필요" end
    local q = PD.quests[qi]
    local dd = q.difficulties[di]
    local ctl = C.NewFight(PQFight, { kind = "partyQuest", modeKey = "pq_" .. q.id, qi = qi, di = di, quest = q,
        dd = dd, allies = PQ.ALLIES, revive = true, timeLimit = PQ.TIME_SEC * 1000, dungeonType = "PartyDungeon",
        difficulty = di - 1, waveMobs = PQ.WAVE_MOBS, mobName = q.regionKo .. " 몬스터",
        title = q.nameKo .. " " .. dd.nameKo })
    return C.Start(hero, ctl)
end

function PQ.Expedition(hero, qi, di)
    local q = PD.quests[qi]
    if not (hero.content.pq.cleared[key(qi, di)]) then return false, "클리어한 난이도로만 탐험을 보낼 수 있습니다." end
    if not Hero.Spend(hero, "explorationTicket", 1, "pqExpedition") then return false, "탐험 티켓이 없습니다." end
    local dd = q.difficulties[di]
    local rewards = { gear = { { code = dd.gear, level = U.rng:Int(dd.itemLevel[1], dd.itemLevel[2]),
        source = "pqExpedition", name = q.slotKo .. " (" .. q.nameKo .. ")" } } }
    local lines = C.Grant(hero, rewards, "pqExpedition")
    C.Record(hero, "pq_" .. q.id, C.Result(true, "clear", string.format("%s %s 탐험 완료", q.nameKo, dd.nameKo), lines))
    return true, nil, lines
end

function PQ.SetRepeat(hero, on) hero.content.pq.repeatOn = on and true or false end

for qi, q in ipairs(PD.quests) do
    local opts = {}
    for i, dd in ipairs(q.difficulties) do opts[i] = dd.nameKo end
    C.RegisterMode("pq_" .. q.id, {
        order = 50 + qi, group = "파티 퀘스트", title = q.nameKo,
        selectors = { { key = "diff", label = "난이도", options = opts } },
        info = function(hero, sel)
            local di = sel.diff or 1
            local dd = q.difficulties[di]
            local ok, why = PQ.IsUnlocked(hero, qi, di)
            local drop = PD.drop[dd.nameKo]
            local nm = dd.normal
            local lines = {
                string.format("%s · 던전 Lv.%d · 파티 4인 (나 + AI %d명) · %s", q.regionKo, dd.level, PQ.ALLIES,
                    ok and "입장 가능" or ("|cffff6060" .. why .. " 필요|r")),
                string.format("일반몹 HP %s~%s · %s보스 HP %s · 방어력 %s~%s", F(nm.hpMin), F(nm.hpMax),
                    dd.mid and ("중간보스 " .. F(dd.mid.hp) .. " · 최종") or "", F(dd.boss.hp), F(nm.defMin), F(dd.boss.def)),
                string.format("보상: 경험치 %s (경험치%% 미적용) · %s %.0f%% (Lv.%d~%d, 부옵션 1~3줄)", F(dd.exp), q.slotKo,
                    drop.permille / 10, dd.itemLevel[1], dd.itemLevel[2]),
                string.format("클리어 %d회 · 탐험 티켓 %d장 (매주 +%d) · 반복 %s", hero.content.pq.cleared[key(qi, di)] or 0,
                    Hero.Count(hero, "explorationTicket"), PD.expeditionWeekly, hero.content.pq.repeatOn and "켜짐" or "꺼짐"),
                "|cff999999제한시간·웨이브 구성·몬스터 공격력은 임시값|r",
            }
            return lines
        end,
        actions = {
            { label = "입장", fn = function(hero, sel) local b, e = PQ.Enter(hero, qi, sel.diff or 1); return b ~= nil, e end },
            { label = "탐험", fn = function(hero, sel) return PQ.Expedition(hero, qi, sel.diff or 1) end },
            { label = "반복 전환", fn = function(hero)
                PQ.SetRepeat(hero, not hero.content.pq.repeatOn)
                return true, nil, { "반복 " .. (hero.content.pq.repeatOn and "켜짐" or "꺼짐") } end },
        },
    })
end

---------------------------------------------------------------------------
-- 몬스터파크 익스트림
---------------------------------------------------------------------------
local MP = {}
C.MonsterPark = MP
local MD = D.ContentMonsterPark
-- PROVISIONAL (map / spawn tables not in the data): normal monsters kept alive and the jackalope rate.
MP.ALIVE = 12
MP.JACKALOPE_EVERY = 40
MP.ALLIES = MD.partyMax - 1

C.RegisterState("monsterPark", {
    init = function(hero, ct)
        ct.park = ct.park or { cleared = {}, runs = 0 }
        if not ct.parkTicketGiven then
            ct.parkTicketGiven = true
            C.Recharge(hero, "monsterParkTicket", MD.startTickets, MD.ticketCap)
        end
    end,
    weekly = function(hero, ct)
        C.Recharge(hero, "monsterParkTicket", MD.weeklyTickets, MD.ticketCap)
    end,
})

-- equipped preset star force (sum of item stars) when the equipment system exists
function MP.StarForce(hero)
    local E = ns.Equipment
    if not (E and E.EquippedItems) then return 0 end
    local ok, items = pcall(E.EquippedItems, hero)
    if not ok or not items then return 0 end
    local n = 0
    for _, it in pairs(items) do n = n + (it.star or 0) end
    return n
end

function MP.IsUnlocked(hero, stage)
    local u = MD.stages[stage].unlock
    return C.StageReached(hero, u[1], u[2]), C.GateText(u[1], u[2])
end

local MPFight = C.Proto()

function MPFight:Setup(b)
    self.missions = { 0, 0, 0, 0 }
    self.appear = 0
    self.spawned = 0
    self.bigfootHp = nil
    self:Refill(b)
end

function MPFight:Refill(b)
    local sd = MD.stages[self.stage]
    local hc = b.heroCreature
    local alive = self:EnemiesAlive(b, "mob") + self:EnemiesAlive(b, "jackalope")
    for _ = alive + 1, MP.ALIVE do
        self.spawned = self.spawned + 1
        local x = (hc and hc.x or 0) + 900 + b.rng:Int(0, 5000)
        if self.spawned % MP.JACKALOPE_EVERY == 0 then
            self:Spawn(b, { name = "미지의 재카로프", hp = sd.jackalope.hp, atk = sd.atkProvisional.normal,
                def = sd.jackalope.def, avoid = sd.jackalope.avoid, x = x, aggro = 1500, tag = "jackalope" })
        else
            local c = self:Spawn(b, { name = "몬스터파크 몬스터", hp = sd.normal.hp, atk = sd.atkProvisional.normal,
                def = sd.normal.def, avoid = sd.normal.avoid, x = x, aggro = 1500, tag = "mob" })
            c.mission = b.rng:Int(1, MD.missions)
        end
    end
end

function MPFight:MissionsDone()
    for i = 1, MD.missions do if self.missions[i] < MD.killsPerMission then return false end end
    return true
end

function MPFight:OnEnemyKilled(b, victim)
    if victim.tag == "bigfoot" then b:End("clear") return end
    if victim.tag == "jackalope" then
        for i = 1, MD.missions do self.missions[i] = self.missions[i] + MD.jackalopeMissionBonus end
    elseif victim.mission then
        self.missions[victim.mission] = self.missions[victim.mission] + 1
    end
end

function MPFight:Tick(b)
    local sd = MD.stages[self.stage]
    self:Refill(b)
    local bf = self.bigfoot
    if bf and bf.alive and self.fleeAt and b.time >= self.fleeAt then
        -- flees: missions reset, boss HP kept
        self.bigfootHp = bf.hp
        bf.alive = false
        self.bigfoot = nil
        self.missions = { 0, 0, 0, 0 }
    end
    if not self.bigfoot and self:MissionsDone() then
        self.appear = self.appear + 1
        local hc = b.heroCreature
        self.bigfoot = self:Spawn(b, { name = "빅풋", hp = sd.bigfoot.hp, atk = sd.atkProvisional.bigfoot,
            def = sd.bigfoot.def, avoid = sd.bigfoot.avoid, boss = true, x = (hc and hc.x or 0) + 1500, tag = "bigfoot" })
        if self.bigfootHp then self.bigfoot.hp = self.bigfootHp end
        local flee = MD.fleeSec[self.appear]
        self.fleeAt = flee and (b.time + flee * 1000) or nil
    end
end

function MPFight:UpdateTitle(b)
    local m = self.missions
    self.title = string.format("몬스터파크 %d단계 · 미션 %d/%d/%d/%d%s", self.stage, math.min(m[1], 15),
        math.min(m[2], 15), math.min(m[3], 15), math.min(m[4], 15), self.bigfoot and (" · 빅풋 " .. self.appear) or "")
end

function MPFight:Finish(b, reason)
    local hero = self.hero
    local sd = MD.stages[self.stage]
    local head = string.format("몬스터파크 익스트림 %d단계%s", self.stage, self.practice and " (도전 모드)" or "")
    if reason ~= "clear" then
        return C.Result(false, reason, head .. " " .. (C.REASON_KO[reason] or reason) .. " · 입장권 미사용")
    end
    local st = hero.content.park
    st.cleared[self.stage] = true
    st.runs = (st.runs or 0) + 1
    if self.practice then return C.Result(true, reason, head .. " 클리어 (보상 없음)") end
    -- the ticket is used only when the reward is claimed
    if not Hero.Spend(hero, "monsterParkTicket", 1, "monsterPark") then
        return C.Result(true, reason, head .. " 클리어 (입장권 없음: 보상 없음)")
    end
    local sf = MP.StarForce(hero)
    local exp = sf >= sd.starForce and sd.expBonus or sd.exp
    local rewards = { exp = exp }
    local lines = C.Grant(hero, rewards, "monsterPark")
    if sf >= sd.starForce then lines[#lines + 1] = string.format("스타포스 %d ≥ %d: +%d%%", sf, sd.starForce, MD.bonusPct) end
    return C.Result(true, reason, head .. " 클리어", lines, { rewards = rewards })
end

function MP.Enter(hero, stage, practice)
    local sd = MD.stages[stage or 1]
    if not sd then return nil, "잘못된 단계입니다." end
    local ok, gate = MP.IsUnlocked(hero, stage)
    if not ok then return nil, gate .. " 후 입장할 수 있습니다." end
    if not practice and Hero.Count(hero, "monsterParkTicket") < 1 then return nil, "입장권이 없습니다." end
    local ctl = C.NewFight(MPFight, { kind = "monsterPark", modeKey = "monsterPark", stage = stage, practice = practice,
        allies = MP.ALLIES, revive = true, timeLimit = MD.timeSec * 1000, dungeonType = "MonsterPark",
        noSupporter = MD.noSupporter, title = "몬스터파크 익스트림 " .. stage .. "단계" })
    return C.Start(hero, ctl)
end

C.RegisterMode("monsterPark", {
    order = 58, group = "파티 퀘스트", title = "몬스터파크 익스트림",
    selectors = { { key = "stage", label = "단계", min = 1, max = function() return #MD.stages end, default = function() return 1 end } },
    info = function(hero, sel)
        local stage = sel.stage or 1
        local sd = MD.stages[stage]
        local ok, gate = MP.IsUnlocked(hero, stage)
        return {
            string.format("%d단계 (%s) · 일반 HP %s · 빅풋 HP %s · 30분 · 파티 4인 (나 + AI %d명), 동료 불가", stage, gate,
                F(sd.normal.hp), F(sd.bigfoot.hp), MP.ALLIES) .. (ok and "" or " |cffff6060잠김|r"),
            string.format("미션 4종 × %d마리 → 빅풋 등장 (1~4번째 %s초 후 도망) · 재카로프 처치 시 모든 미션 +%d", MD.killsPerMission,
                table.concat(MD.fleeSec, "/"), MD.jackalopeMissionBonus),
            string.format("보상: 경험치 %s (스타포스 %d 이상 %s) · 현재 스타포스 %d", F(sd.exp), sd.starForce, F(sd.expBonus),
                MP.StarForce(hero)),
            string.format("입장권 %d장 (매주 월요일 +%d, 최대 %d) · 보상 수령 시에만 사용", Hero.Count(hero, "monsterParkTicket"),
                MD.weeklyTickets, MD.ticketCap),
        }
    end,
    actions = {
        { label = "입장", fn = function(hero, sel) local b, e = MP.Enter(hero, sel.stage or 1); return b ~= nil, e end },
        { label = "도전 모드", fn = function(hero, sel) local b, e = MP.Enter(hero, sel.stage or 1, true); return b ~= nil, e end },
    },
})

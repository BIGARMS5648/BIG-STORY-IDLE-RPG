-- 전직 (Job Advancement): at Lv30 / 60 / 100 the next job step needs its test cleared
-- (Data/JobAdvancement.lua). Skills of a job step above hero.jobStep stay locked
-- (SkillBook.RowUnlocked). The test can be retried freely; it has no reward besides the step.
--
-- API
--   ns.JobAdvance.Step(hero)          -> current job step (1..4)
--   ns.JobAdvance.Next(hero)          -> { step, level, test, ready } or nil when 4th job is done
--   ns.JobAdvance.Enter(hero)         -> battle | nil, err
-- Events: "JOB_ADVANCED"(hero, step)
local ADDON, ns = ...
local U = ns.U
local D = ns.Data
local Hero = ns.Hero
local C = ns.Content

local J = {}
ns.JobAdvance = J
local JA = D.JobAdvancement

-- the step a level allows (used once to migrate heroes saved before job tests existed)
function J.StepForLevel(level)
    local s = 1
    for step = 2, 4 do if level >= JA.levels[step] then s = step end end
    return s
end

Hero.RegisterSystem("jobAdvance", {
    init = function(hero)
        if hero.jobStep == nil then
            hero.jobStep = (hero.level or 1) > 1 and J.StepForLevel(hero.level) or 1
        end
    end,
})

function J.Step(hero) return hero.jobStep or 1 end

function J.Tests(hero)
    local job = Hero.Job(hero)
    return job and JA.byJob[job.index]
end

function J.Next(hero)
    local step = J.Step(hero) + 1
    if step > 4 then return nil end
    local tests = J.Tests(hero)
    local test = tests and tests[step]
    if not test then return nil end
    return { step = step, level = JA.levels[step], test = test, ready = hero.level >= JA.levels[step] }
end

function J.Describe(test)
    local F = U.FormatNumber
    if test.kind == "collect" then
        local names = {}
        for _, m in ipairs(test.mobs) do names[#names + 1] = m.look.nameKo end
        return string.format("%s에게서 %s %d개 획득 · %d초 · HP %s · 방어력 %s · 회피 %d", table.concat(names, ", "),
            test.item, test.need, test.timeSec, F(test.mobs[1].hp), F(test.mobs[1].def), test.mobs[1].avoid)
    end
    local parts = {}
    for _, bo in ipairs(test.bosses) do
        parts[#parts + 1] = string.format("%s (HP %s · 공격력 %s · 회피 %d)", bo.look.nameKo, F(bo.hp), F(bo.atk), bo.avoid)
    end
    return string.format("%s 처치 · %d초", table.concat(parts, ", "), test.timeSec)
end

---------------------------------------------------------------------------
-- fights
---------------------------------------------------------------------------
local Collect = C.Proto()
local Bosses = C.Proto()

function Collect:Setup(b)
    self.items = 0
    self.spawned = 0
    self:Refill(b)
end

function Collect:Refill(b)
    local hc = b.heroCreature
    for _ = self:EnemiesAlive(b) + 1, self.test.alive do
        self.spawned = self.spawned + 1
        local m = self.test.mobs[(self.spawned - 1) % #self.test.mobs + 1]
        self:Spawn(b, { name = m.look.nameKo, hp = m.hp, atk = m.atk, def = m.def, avoid = m.avoid, aggro = 1500,
            speed = m.speed, x = (hc and hc.x or 0) + 900 + b.rng:Int(0, 2500), model = { displayId = m.look.displayId, npcId = m.look.npcId } })
    end
end

function Collect:OnEnemyKilled(b, victim)
    self.items = self.items + 1
    if self.items >= self.test.need then b:End("clear") end
end

function Collect:Tick(b, dt)
    if self.items >= self.test.need then b:End("clear") return end
    self:Refill(b)
end

function Collect:UpdateTitle(b)
    self.title = string.format("%s 전직 시험 · %s %d/%d", JA.stepNames[self.step], self.test.item, self.items, self.test.need)
end

function Bosses:Setup(b)
    local hc = b.heroCreature
    self.bosses = {}
    for i, bo in ipairs(self.test.bosses) do
        local c = self:Spawn(b, { name = bo.look.nameKo, hp = bo.hp, atk = bo.atk, def = bo.def, avoid = bo.avoid, boss = true,
            x = (hc and hc.x or 0) + 2200 + (i - 1) * 900, model = { displayId = bo.look.displayId, npcId = bo.look.npcId } })
        self.bosses[#self.bosses + 1] = c
    end
end

function Bosses:Tick(b, dt)
    for _, c in ipairs(self.bosses) do if c.alive then return end end
    b:End("clear")
end

function Bosses:UpdateTitle(b)
    local left = 0
    for _, c in ipairs(self.bosses) do if c.alive then left = left + 1 end end
    self.title = string.format("%s 전직 시험 · 남은 대상 %d", JA.stepNames[self.step], left)
end

local function finish(self, b, reason)
    local hero = self.hero
    local name = JA.stepNames[self.step] .. " 전직"
    if reason ~= "clear" then
        return C.Result(false, reason, string.format("%s 시험 %s", name, C.REASON_KO[reason] or reason))
    end
    if J.Step(hero) < self.step then
        hero.jobStep = self.step
        Hero.Changed(hero, "job")
        ns.Fire("JOB_ADVANCED", hero, self.step)
    end
    return C.Result(true, reason, string.format("%s 완료! %s 스킬이 열렸습니다.", name, JA.stepNames[self.step]))
end
Collect.Finish, Bosses.Finish = finish, finish

function J.Enter(hero)
    local nx = J.Next(hero)
    if not nx then return nil, "모든 전직을 마쳤습니다." end
    if not nx.ready then return nil, string.format("%d 레벨 달성 필요", nx.level) end
    local proto = nx.test.kind == "collect" and Collect or Bosses
    local ctl = C.NewFight(proto, { kind = "jobAdvance", modeKey = "jobAdvance", step = nx.step, test = nx.test,
        timeLimit = nx.test.timeSec * 1000, dungeonType = "JobStepDungeon", noSupporter = true,
        title = JA.stepNames[nx.step] .. " 전직 시험" })
    return C.Start(hero, ctl)
end

C.RegisterMode("jobAdvance", {
    order = 1, group = "전직", title = "전직 시험",
    selectors = {},
    info = function(hero)
        local nx = J.Next(hero)
        if not nx then return { string.format("현재 %s · 모든 전직 완료", JA.stepNames[J.Step(hero)]) } end
        return {
            string.format("현재 %s · 다음 %s 전직: %d 레벨%s", JA.stepNames[J.Step(hero)], JA.stepNames[nx.step], nx.level,
                nx.ready and "" or "  |cffff6060(레벨 부족)|r"),
            J.Describe(nx.test),
            "시험에 통과하면 다음 전직 스킬이 열립니다 · 실패해도 다시 도전할 수 있습니다",
        }
    end,
    actions = {
        { label = "도전", fn = function(hero) local b, err = J.Enter(hero); return b ~= nil, err end,
          enabled = function(hero) local nx = J.Next(hero); return nx and nx.ready or false end },
    },
})

ns.On("HERO_LEVEL_UP", function(hero, level)
    for step = 2, 4 do
        if level == JA.levels[step] and J.Step(hero) < step then
            ns.Print("|cffffd100%s 전직 시험|r을 볼 수 있습니다. (콘텐츠 → 전직 시험)", JA.stepNames[step])
        end
    end
end)

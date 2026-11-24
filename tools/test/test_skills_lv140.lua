-- Verifies skill coefficients (per-hit %, hit counts, targets) at Lv140 with all
-- masteries against the reference engine snapshot exported from the spec.
package.path = "tools/test/?.lua;" .. package.path
local H = require("harness")
H.loadToc()
local ns = H.ns
local expected = dofile("tools/test/expected_lv140.lua")

local SB = ns.SkillBook
local total, ok, bad = 0, 0, 0
local report = {}
for _, job in ipairs(ns.Data.Jobs) do
    local learned = SB.AllMasteriesAt(job, 140)
    local set, statAdds = SB.Build({ jobKey = job.key, level = 140, masteries = learned })
    local b = ns.Battle.New({ seed = 1 })
    local hero = b:AddCreature({ name = job.key, side = 1, isHero = true, level = 140, job = job,
        stats = { adds = statAdds, ratios = {}, chains = {}, mults = {} }, skillSet = set })
    for _, L in ipairs(expected[job.key] or {}) do
        total = total + 1
        local inst = b:Inst(hero, b:Resolve(hero, L.src)) or b:Inst(hero, L.src)
        local ctx = { caster = hero, inst = inst, target = nil, opTargets = {}, depth = 0, rootSkill = L.root }
        local o = inst and inst.ops[L.op]
        if not o then
            bad = bad + 1
            report[#report + 1] = string.format("%s %d/%d op%d missing", job.key, L.root, L.src, L.op)
        else
            local ratio = b:OpValue(ctx, inst, L.op, 1)
            local hits = b:OpValue(ctx, inst, L.op, 3)
            local pct = b:LinePercent(ctx, inst, L.op, ratio, nil)
            local diff = math.abs(pct - L.one) / math.max(1, L.one)
            if diff < 0.002 and (hits == L.hits or L.hits == nil) then
                ok = ok + 1
            else
                bad = bad + 1
                report[#report + 1] = string.format("%-12s root %-6d src %-6d op%d  got %.2f%% x%d  want %.2f%% x%d",
                    job.key, L.root, L.src, L.op, pct, hits, L.one, L.hits or -1)
            end
        end
    end
end
for _, r in ipairs(report) do print(r) end
print(string.format("lines: %d  match: %d  mismatch: %d", total, ok, bad))

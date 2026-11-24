import json, sys, glob, os, csv, sqlite3
sys.path.insert(0, "/tmp/claude-0/-home-user-BIG-STORY-IDLE-RPG/f4db4718-c3e8-5335-9264-6dbe1627a364/scratchpad/mdb/scripts")
from common import *

# ---------------- merge source registries
S = {}
for f in sorted(glob.glob(SCRATCH + "/mdb/sources_build_*.json")):
    S.update(json.load(open(f, encoding="utf-8")))
SOURCES.clear(); SOURCES.update(S)

# ---------------- estimates (kept OUT of the verified datasets)
est = []
for st in range(141, 161):
    e = dict(dataset="hero_training_rewards", stage=st, field="repeat_clear_hero_tokens", estimate=240 + 10 * st,
             method="linear extrapolation of global 1.14 DungeonTable clear reward (exactly 240 + 10×stage for all 140 known stages)",
             confidence="medium for 141-150 (live KR stages, formula unbroken through 140); low for 151-160 (announced only)")
    e.update(meta("MSI_HERO_TOKEN", "estimate", "NOT verified. Use only as a placeholder until KR values are published."))
    est.append(e)
    if st % 10 == 0:
        e2 = dict(e); e2.update(field="first_clear_hero_tokens", estimate=1200 + 50 * st,
                                method="extrapolation of first-clear rewards on stages divisible by 10 (1200 + 50×stage for stages 10..140)")
        est.append(e2)
e = dict(dataset="daily_missions", stage=None, field="individual_daily_missions_red_diamond_total", estimate=2400,
         method="community daily red-diamond total 7,400 (MEKI_RD, IV731) minus official 8-mission header reward 5,000",
         confidence="low (community totals, may include other daily sources)")
e.update(meta("REPO_INCOME", "estimate", "Derived, not a published value."))
est.append(e)
write_dataset("estimates", "Estimates only (NOT verified data) with method and confidence", est, None,
              f"{len(est)} estimate rows; every row has verification_status='estimate'.")

# ---------------- sources.csv
cols = ["source_id", "source_url", "publisher", "source_type", "game_version", "region", "published_or_snapshot", "title", "retrieved_at", "local_copy", "notes"]
used = set()
for f in glob.glob(OUT + "/json/*.json"):
    for r in json.load(open(f, encoding="utf-8"))["records"]:
        used.add(r.get("source_id"))
with open(OUT + "/sources.csv", "w", encoding="utf-8-sig", newline="") as fh:
    w = csv.writer(fh)
    w.writerow(cols + ["records_citing"])
    counts = {}
    for f in glob.glob(OUT + "/json/*.json"):
        for r in json.load(open(f, encoding="utf-8"))["records"]:
            counts[r.get("source_id")] = counts.get(r.get("source_id"), 0) + 1
    for sid in sorted(SOURCES):
        s = SOURCES[sid]
        w.writerow([s.get(c, "") for c in cols] + [counts.get(sid, 0)])

# ---------------- SQLite
dbp = OUT + "/maple_idle.sqlite"
if os.path.exists(dbp):
    os.remove(dbp)
con = sqlite3.connect(dbp)
cur = con.cursor()
cur.execute("CREATE TABLE sources (" + ", ".join(c + " TEXT" for c in cols) + ", records_citing INTEGER, PRIMARY KEY(source_id))")
for sid in sorted(SOURCES):
    s = SOURCES[sid]
    cur.execute("INSERT INTO sources VALUES (" + ",".join("?" * (len(cols) + 1)) + ")", [s.get(c) for c in cols] + [counts.get(sid, 0)])
cur.execute("CREATE TABLE datasets (name TEXT PRIMARY KEY, description TEXT, record_count INTEGER, expected_record_count INTEGER, coverage_note TEXT)")
summary = []
for f in sorted(glob.glob(OUT + "/json/*.json")):
    d = json.load(open(f, encoding="utf-8"))
    name = d["dataset"]
    recs = d["records"]
    keys = []
    for r in recs:
        for k in r:
            if k not in keys:
                keys.append(k)
    def typ(k):
        vals = [r.get(k) for r in recs if r.get(k) is not None]
        if vals and all(isinstance(v, bool) for v in vals):
            return "INTEGER"
        if vals and all(isinstance(v, int) and not isinstance(v, bool) for v in vals):
            return "INTEGER"
        if vals and all(isinstance(v, (int, float)) and not isinstance(v, bool) for v in vals):
            return "REAL"
        return "TEXT"
    cur.execute(f'CREATE TABLE "{name}" (row_id INTEGER PRIMARY KEY, ' + ", ".join(f'"{k}" {typ(k)}' for k in keys) + ")")
    for i, r in enumerate(recs, 1):
        vals = []
        for k in keys:
            v = r.get(k)
            if isinstance(v, (dict, list)):
                v = json.dumps(v, ensure_ascii=False)
            elif isinstance(v, int) and not isinstance(v, bool) and abs(v) > 2**63 - 1:
                v = str(v)
            vals.append(v)
        cur.execute(f'INSERT INTO "{name}" VALUES (?, ' + ",".join("?" * len(keys)) + ")", [i] + vals)
    cur.execute("INSERT INTO datasets VALUES (?,?,?,?,?)", (name, d["description"], d["record_count"], d.get("expected_record_count"), d.get("coverage_note")))
    summary.append((name, d["record_count"], d.get("expected_record_count"), d.get("coverage_note")))
con.commit()
con.close()
for s in summary:
    print(s[0], s[1], s[2])
print("sources", len(SOURCES), "used", len(used))

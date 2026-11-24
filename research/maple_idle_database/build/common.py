"""Shared helpers for the maple_idle_database build (run with python3 -I)."""
import csv, json, os, re, html

SCRATCH = "/tmp/claude-0/-home-user-BIG-STORY-IDLE-RPG/f4db4718-c3e8-5335-9264-6dbe1627a364/scratchpad"
RAW = SCRATCH + "/mdb/raw"
OLDWEB = SCRATCH + "/web"
OUT = "/home/user/BIG-STORY-IDLE-RPG/research/maple_idle_database"
RETRIEVED = "2026-11-24"

FORUM_KR = "https://forum.nexon.com/maplestoryidle-kr/board_view?board={b}&thread={t}"
FORUM_GL = "https://forum.nexon.com/maplestoryidle/board_view?board={b}&thread={t}"

# Source registry: id -> dict. Every record cites one of these ids plus its URL.
SOURCES = {}


def src(sid, url, publisher, kind, game_version, region, published, title, local, notes=""):
    SOURCES[sid] = dict(source_id=sid, source_url=url, publisher=publisher, source_type=kind,
                        game_version=game_version, region=region, published_or_snapshot=published,
                        title=title, retrieved_at=RETRIEVED, local_copy=local, notes=notes)
    return sid


def fkr(sid, board, thread, title, date, notes=""):
    return src(sid, FORUM_KR.format(b=board, t=thread), "Nexon (official KR forum)", "official_notice",
               "live KR at " + date, "KR", date, title, f"mdb/raw/forum_txt/{board}_{thread}.txt", notes)


def meta(sid, status, notes="", game_version=None, region=None, url=None):
    s = SOURCES[sid]
    return dict(source_id=sid, source_url=url or s["source_url"], game_version=game_version or s["game_version"],
                region=region or s["region"], retrieved_at=RETRIEVED, verification_status=status, notes=notes)


def bigint(v):
    """Keep exact integers; values beyond int64 are returned as strings (JSON/SQLite safe)."""
    if v is None or v == "":
        return None
    if isinstance(v, str):
        v = v.replace(",", "")
        if re.fullmatch(r"-?\d+", v):
            v = int(v)
        else:
            try:
                return float(v)
            except ValueError:
                return v
    if isinstance(v, int) and abs(v) > 2**62:
        return str(v)
    return v


def forum_text(board, thread):
    p = f"{RAW}/forum_txt/{board}_{thread}.txt"
    return open(p, encoding="utf-8").read()


def write_dataset(name, description, records, expected=None, coverage_note="", extra=None):
    os.makedirs(OUT + "/json", exist_ok=True)
    os.makedirs(OUT + "/csv", exist_ok=True)
    doc = dict(dataset=name, description=description, generated_at=RETRIEVED,
               record_count=len(records), expected_record_count=expected,
               coverage_note=coverage_note)
    if extra:
        doc.update(extra)
    doc["records"] = records
    with open(f"{OUT}/json/{name}.json", "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
    cols = []
    for r in records:
        for k in r:
            if k not in cols:
                cols.append(k)
    with open(f"{OUT}/csv/{name}.csv", "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for r in records:
            row = []
            for c in cols:
                v = r.get(c)
                if isinstance(v, (dict, list)):
                    v = json.dumps(v, ensure_ascii=False)
                row.append("" if v is None else v)
            w.writerow(row)
    return doc

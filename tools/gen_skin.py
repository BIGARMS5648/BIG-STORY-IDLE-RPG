#!/usr/bin/env python3
"""Generate BigStoryIdleRPG/Data/SkinData.lua from research/skin/*.json:
world-map.json (chapters -> WoW zones/creatures), appearance-map.json (gear grade ->
WoW item looks) and skills-map.json (jobs/skills -> WoW classes/spells, optional).

Usage: python3 -I tools/gen_skin.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from luagen import write_lua  # noqa: E402

ROOT = os.path.dirname(HERE)
SKIN = os.path.join(ROOT, "research", "skin")
OUT = os.path.join(ROOT, "BigStoryIdleRPG", "Data", "SkinData.lua")

# the user's job -> class/spec mapping
JOBS = {
    "hero": ("WARRIOR", "무기", "무기 전사"),
    "darkKnight": ("WARRIOR", "분노", "분노 전사"),
    "paladin": ("PALADIN", "보호", "보호 성기사"),
    "archMageFP": ("WARLOCK", "파괴", "파괴 흑마법사"),
    "archMageIL": ("SHAMAN", "정기", "정기 주술사"),
    "bishop": ("PRIEST", "신성", "신성 사제"),
    "bowMaster": ("MAGE", "냉기", "냉기 마법사"),
    "marksman": ("HUNTER", "사격", "사격 사냥꾼"),
    "nightLord": ("ROGUE", "암살", "암살 도적"),
    "shadower": ("WARLOCK", "악마", "악마 흑마법사"),
    "viper": ("DRUID", "야성", "야성 드루이드"),
    "captain": ("HUNTER", "야수", "야수 사냥꾼"),
    "windBreaker": ("DRUID", "조화", "조화 드루이드"),
    "nightWalker": ("PRIEST", "암흑", "암흑 사제"),
    "soulMaster": ("PALADIN", "징벌", "징벌 성기사"),
    "flameWizard": ("MAGE", "화염", "화염 마법사"),
}
SPEC_ICON = {
    "hero": "Ability_Warrior_SavageBlow", "darkKnight": "Ability_Warrior_InnerRage",
    "paladin": "Spell_Holy_DevotionAura", "archMageFP": "Spell_Shadow_RainOfFire",
    "archMageIL": "Spell_Nature_Lightning", "bishop": "Spell_Holy_HolyBolt", "bowMaster": "Spell_Frost_FrostBolt02",
    "marksman": "Ability_Marksmanship", "nightLord": "Ability_Rogue_Eviscerate", "shadower": "Spell_Shadow_Metamorphosis",
    "viper": "Ability_Druid_CatForm", "captain": "Ability_Hunter_BeastTaming", "windBreaker": "Spell_Nature_StarFall",
    "nightWalker": "Spell_Shadow_ShadowWordPain", "soulMaster": "Spell_Holy_AuraOfLight",
    "flameWizard": "Spell_Fire_FireBolt02",
}


def load(name):
    p = os.path.join(SKIN, name)
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def creature(e):
    if not e:
        return None
    return {k: e.get(k) for k in ("npcId", "displayId", "nameKo", "nameEn")}


def main():
    world = load("world-map.json")
    looks = load("appearance-map.json")
    skills = load("skills-map.json")

    sw = {"chapters": {}, "content": {}}
    if world:
        for k, c in world["chapters"].items():
            sw["chapters"][int(k)] = {
                "zoneKo": c.get("zoneKo"), "zoneEn": c.get("zoneEn"), "loadingScreen": c.get("loadingScreen"),
                "monsters": [creature(m) for m in c.get("monsters", [])],
                "boss": creature(c.get("boss")),
            }
        cont = world.get("content", {})
        out = {}
        for k, v in cont.items():
            if isinstance(v, list):
                out[k] = [creature(x) if isinstance(x, dict) else x for x in v]
            elif isinstance(v, dict):
                if "npcId" in v or "displayId" in v:
                    out[k] = creature(v)
                else:
                    out[k] = {kk: (creature(vv) if isinstance(vv, dict) else vv) for kk, vv in v.items()}
            else:
                out[k] = v
        sw["content"] = out

    sl = {"armor": {}, "cape": {}, "weapons": {}}
    if looks:
        for cls, slots in looks["armor"].items():
            sl["armor"][cls] = {slot: {g: {"id": e["id"]} for g, e in grades.items() if e and e.get("id")}
                                for slot, grades in slots.items()}
        sl["cape"] = {g: {"id": e["id"]} for g, e in looks["cape"].items() if e and e.get("id")}
        for job, w in looks["weapons"].items():
            sl["weapons"][job] = {
                "mainHand": {g: {"id": e["id"]} for g, e in (w.get("mainHand") or {}).items() if e and e.get("id")},
                "offHand": {g: {"id": e["id"]} for g, e in (w.get("offHand") or {}).items() if e and e.get("id")},
            }

    sj = {}
    smap = (skills or {}).get("jobs", {})
    for key, (cls, spec, display) in JOBS.items():
        j = smap.get(key, {})
        entry = {
            "display": display, "classToken": cls, "specKo": spec,
            "specIcon": j.get("specIcon") or SPEC_ICON.get(key),
            "classIcon": j.get("classIcon"),
            "skills": {}, "masteries": {},
        }
        for part in ("skills", "masteries"):
            for sid, e in (j.get(part) or {}).items():
                entry[part][int(sid)] = {kk: e.get(kk) for kk in ("wowSpellId", "nameKo", "nameEn", "icon")}
        sj[key] = entry

    write_lua(OUT, [
        ("D.SkinJobs", sj, None),
        ("D.SkinWorld", sw, None),
        ("D.SkinLooks", sl, None),
    ], note="WoW skin data: names, icons, creature models and item appearances only.")
    print("chapters %d, looks classes %d, weapon jobs %d, skill jobs mapped %d" % (
        len(sw["chapters"]), len(sl["armor"]), len(sl["weapons"]), sum(1 for k in sj if sj[k]["skills"])))


if __name__ == "__main__":
    main()

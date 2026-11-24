#!/usr/bin/env python3
"""Battle-map themes and skill effect models from the WoW community listfile.

usage: gen_maps.py <community-listfile.csv> <addon dir>
writes <addon>/Data/MapThemes.lua (per chapter: terrain textures for the platform surface / body by
client FileDataID, fallback colours, layout style) and <addon>/Data/SkillEffects.lua (spell effect
models by FileDataID + keyword rules that map a skill's WoW spell name to missile / impact / area).
Only original-era files (FileDataID < 200000) are used so they exist in the classic client.
"""
import re, sys

CHAPTER_FOLDER = {
    1: "elwynn", 2: "durotar", 3: "ironforge", 4: "tirisfall", 5: "westwood", 6: "barrens", 7: "darkshore",
    8: "silverpine", 9: "redridge", 10: "stonetalon", 11: "duskwood", 12: "ashenvale", 13: "wetlands",
    14: "alteracmtns", 15: "thousandneedles", 16: "araithihighlands", 17: "stranglethorn", 18: "desolace",
    19: "duskwallow", 20: "the badlands", 21: "tanaris", 22: "feralas", 23: "aerie peaks", 24: "ungoro",
    25: "burningstepps", 26: "winterspring grove", 27: "plaguelandseast", 28: "silithis",
    # dungeons: the terrain of the zone around them
    29: "westwood", 30: "barrens", 31: "tirisfall", 32: "the badlands", 33: "tanaris", 34: "desolace",
    35: "swamp of sorrows", 36: "burningstepps", 37: "burningstepps", 38: "feralas", 39: "plaguelandswest",
    40: "plaguelandseast",
    # raids
    41: "zulgurub", 42: "burningstepps", 43: "duskwallow", 44: "burningstepps", 45: "silithis", 46: "silithis",
    47: "plaguelandseast",
}
SURFACE_KEYS = ["grass", "snow", "sand", "moss", "leaf", "needles", "ferns", "ash", "creep", "mud", "dirt", "crop", "cobble", "brick", "rock"]
DUNGEON_SURFACE = ["brick", "cobble", "road", "rock", "dirt", "sand"]
BODY_KEYS = ["rock", "cliff", "stone", "brick", "dirt"]
SPECIAL_SURFACE = {42: ["lava"], 44: ["brick", "rock"], 36: ["brick", "rock"], 47: ["corrupt", "creep", "dirt"]}
COLORS = {
    "grass": (0.36, 0.56, 0.2), "snow": (0.86, 0.9, 0.96), "sand": (0.82, 0.69, 0.43), "moss": (0.3, 0.45, 0.2),
    "leaf": (0.45, 0.5, 0.2), "needles": (0.38, 0.42, 0.22), "ferns": (0.28, 0.5, 0.22), "ash": (0.32, 0.29, 0.28),
    "creep": (0.42, 0.33, 0.45), "mud": (0.36, 0.3, 0.2), "dirt": (0.48, 0.35, 0.22), "crop": (0.55, 0.5, 0.25),
    "cobble": (0.5, 0.48, 0.44), "brick": (0.47, 0.42, 0.38), "rock": (0.4, 0.36, 0.32), "lava": (0.95, 0.38, 0.1),
    "corrupt": (0.45, 0.3, 0.45), "road": (0.5, 0.45, 0.36),
}
BAD = re.compile(r"(_s\.blp|alpha|highlight|test|water|footprint|bug|crack|tile)", re.I)

EFFECTS = [
    "fireball_missile_high", "fire_impactdd_high_chest", "fire_impactdd_med_chest", "pyroblast_missile",
    "fire_impactdd_uber_chest", "flamestrike_impact_base", "fireblast_impact_chest", "firenova_area",
    "rainoffire_missile", "rainoffire_impact_base", "hellfire_impact_base", "immolate_impact_chest",
    "conflagrate_impact_chest", "frostbolt", "ice_impactdd_high_chest", "frost_nova_area", "blizzard_impact_base",
    "frostbreath", "ice_impactdd_med_chest", "arcane_missile", "arcaneexplosion_base", "arcaneshot_missile",
    "magic_impact_chest", "lightningbolt_missile", "lightningbolt_impact_chest", "chainlightning_impact_chest",
    "earthshock_impact_chest", "missile_wave_nature", "moonfire_impact_base", "moonbeam_impact_base",
    "holysmite_low_chest", "holy_impactdd_high_chest", "holynova_impact_base", "holy_impactdd_med_chest",
    "exorcism_impact_chest", "consecration_impact_base", "holy_hammer_missile", "judgement_impact_chest",
    "holy_impactdd_uber_base", "holy_missile_high", "shadowbolt_missile", "shadowbolt_chest_impact",
    "shadow_impactdd_high_chest", "shadowwordpain_chest", "deathcoil_missile", "deathcoil_impact_chest",
    "corruption_impactdot_med_base", "lifedrain_missile", "shadow_nova_area", "cleave_impact_chest",
    "cleave_cast_base", "savageblow_impact_chest", "thunderclap_cast_base", "whirlwind_state_base",
    "backstab_impact_chest", "eviscerate_impact_chest", "sinisterstrike_impact_chest", "rake", "maulimpact",
    "aimedshot_impact_chest", "multishot_missile", "multishot_impact", "poison_impact_chest", "poisonshot_missile",
    "frostshot_missile", "fireshot_missile", "chargetrail", "heal_low_base", "renew_base", "rejuvenation_impact_base",
]
# keyword (lower-case, in the WoW spell name) -> (missile, impact, area)
RULES = [
    ("pyroblast", ("pyroblast_missile", "fire_impactdd_uber_chest", None)),
    ("fireball", ("fireball_missile_high", "fire_impactdd_high_chest", None)),
    ("firebolt", ("fireball_missile_high", "fire_impactdd_med_chest", None)),
    ("soul fire", ("fireball_missile_high", "fire_impactdd_uber_chest", None)),
    ("flamestrike", (None, None, "flamestrike_impact_base")),
    ("blast wave", (None, None, "firenova_area")),
    ("fire nova", (None, None, "firenova_area")),
    ("rain of fire", (None, "rainoffire_impact_base", "rainoffire_impact_base")),
    ("hellfire", (None, None, "hellfire_impact_base")),
    ("immolate", (None, "immolate_impact_chest", None)),
    ("conflagrate", (None, "conflagrate_impact_chest", None)),
    ("fire blast", (None, "fireblast_impact_chest", None)),
    ("scorch", (None, "fire_impactdd_med_chest", None)),
    ("searing", (None, "fire_impactdd_med_chest", None)),
    ("incinerate", (None, "fire_impactdd_high_chest", None)),
    ("flame shock", (None, "fireblast_impact_chest", None)),
    ("magma", (None, None, "firenova_area")),
    ("frostbolt", ("frostbolt", "ice_impactdd_high_chest", None)),
    ("frost nova", (None, None, "frost_nova_area")),
    ("blizzard", (None, None, "blizzard_impact_base")),
    ("cone of cold", (None, None, "frostbreath")),
    ("frost shock", (None, "ice_impactdd_med_chest", None)),
    ("frost", (None, "ice_impactdd_med_chest", None)),
    ("ice", (None, "ice_impactdd_med_chest", None)),
    ("arcane missiles", ("arcane_missile", "magic_impact_chest", None)),
    ("arcane explosion", (None, None, "arcaneexplosion_base")),
    ("arcane shot", ("arcaneshot_missile", "magic_impact_chest", None)),
    ("arcane", (None, "magic_impact_chest", None)),
    ("chain lightning", ("lightningbolt_missile", "chainlightning_impact_chest", None)),
    ("lightning", ("lightningbolt_missile", "lightningbolt_impact_chest", None)),
    ("thunder", (None, None, "thunderclap_cast_base")),
    ("earth shock", (None, "earthshock_impact_chest", None)),
    ("wrath", ("missile_wave_nature", "earthshock_impact_chest", None)),
    ("starfire", (None, "moonbeam_impact_base", None)),
    ("moonfire", (None, "moonfire_impact_base", None)),
    ("hurricane", (None, None, "moonbeam_impact_base")),
    ("insect", (None, "poison_impact_chest", None)),
    ("smite", (None, "holysmite_low_chest", None)),
    ("holy fire", (None, "holy_impactdd_high_chest", None)),
    ("holy nova", (None, None, "holynova_impact_base")),
    ("holy shock", (None, "holy_impactdd_med_chest", None)),
    ("holy wrath", (None, None, "holy_impactdd_uber_base")),
    ("exorcism", (None, "exorcism_impact_chest", None)),
    ("consecration", (None, None, "consecration_impact_base")),
    ("hammer of wrath", ("holy_hammer_missile", "holy_impactdd_high_chest", None)),
    ("hammer of justice", ("holy_hammer_missile", "judgement_impact_chest", None)),
    ("judgement", (None, "judgement_impact_chest", None)),
    ("starshards", ("holy_missile_high", "holy_impactdd_med_chest", None)),
    ("shadow bolt", ("shadowbolt_missile", "shadowbolt_chest_impact", None)),
    ("shadowburn", (None, "shadow_impactdd_high_chest", None)),
    ("mind blast", (None, "shadow_impactdd_high_chest", None)),
    ("mind flay", ("lifedrain_missile", "shadow_impactdd_high_chest", None)),
    ("shadow word", (None, "shadowwordpain_chest", None)),
    ("death coil", ("deathcoil_missile", "deathcoil_impact_chest", None)),
    ("corruption", (None, "corruption_impactdot_med_base", None)),
    ("curse", (None, "corruption_impactdot_med_base", None)),
    ("drain", ("lifedrain_missile", "shadow_impactdd_high_chest", None)),
    ("devouring", (None, None, "shadow_nova_area")),
    ("psychic", (None, None, "shadow_nova_area")),
    ("whirlwind", (None, None, "whirlwind_state_base")),
    ("cleave", (None, None, "cleave_cast_base")),
    ("sweeping", (None, None, "cleave_cast_base")),
    ("swipe", (None, None, "cleave_cast_base")),
    ("thunder clap", (None, None, "thunderclap_cast_base")),
    ("charge", ("chargetrail", "savageblow_impact_chest", None)),
    ("intercept", ("chargetrail", "savageblow_impact_chest", None)),
    ("mortal strike", (None, "savageblow_impact_chest", None)),
    ("execute", (None, "savageblow_impact_chest", None)),
    ("strike", (None, "cleave_impact_chest", None)),
    ("slam", (None, "savageblow_impact_chest", None)),
    ("overpower", (None, "cleave_impact_chest", None)),
    ("backstab", (None, "backstab_impact_chest", None)),
    ("ambush", (None, "backstab_impact_chest", None)),
    ("eviscerate", (None, "eviscerate_impact_chest", None)),
    ("sinister", (None, "sinisterstrike_impact_chest", None)),
    ("hemorrhage", (None, "sinisterstrike_impact_chest", None)),
    ("ghostly", (None, "sinisterstrike_impact_chest", None)),
    ("poison", (None, "poison_impact_chest", None)),
    ("rake", (None, "rake", None)),
    ("claw", (None, "rake", None)),
    ("shred", (None, "rake", None)),
    ("rip", (None, "rake", None)),
    ("maul", (None, "maulimpact", None)),
    ("bite", (None, "maulimpact", None)),
    ("pounce", (None, "maulimpact", None)),
    ("ravage", (None, "maulimpact", None)),
    ("multi-shot", ("multishot_missile", "multishot_impact", None)),
    ("volley", (None, None, "rainoffire_impact_base")),
    ("aimed shot", ("multishot_missile", "aimedshot_impact_chest", None)),
    ("serpent", ("poisonshot_missile", "poison_impact_chest", None)),
    ("scorpid", ("poisonshot_missile", "poison_impact_chest", None)),
    ("concussive", ("frostshot_missile", "ice_impactdd_med_chest", None)),
    ("shot", ("multishot_missile", "aimedshot_impact_chest", None)),
    ("explosive", (None, None, "firenova_area")),
    ("heal", (None, "heal_low_base", None)),
    ("renew", (None, "renew_base", None)),
    ("rejuvenation", (None, "rejuvenation_impact_base", None)),
]
# by WoW class when no rule matches: (missile, impact, area)
CLASS_DEFAULT = {
    "WARRIOR": (None, "cleave_impact_chest", None), "PALADIN": (None, "judgement_impact_chest", None),
    "HUNTER": ("multishot_missile", "aimedshot_impact_chest", None), "ROGUE": (None, "sinisterstrike_impact_chest", None),
    "PRIEST": (None, "holysmite_low_chest", None), "SHAMAN": ("lightningbolt_missile", "lightningbolt_impact_chest", None),
    "MAGE": ("fireball_missile_high", "fire_impactdd_med_chest", None), "WARLOCK": ("shadowbolt_missile", "shadowbolt_chest_impact", None),
    "DRUID": (None, "rake", None),
}


def main():
    listfile, addon = sys.argv[1], sys.argv[2]
    tiles, spells = {}, {}
    with open(listfile, encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if ";" not in line:
                continue
            fid, path = line.split(";", 1)
            try:
                fid = int(fid)
            except ValueError:
                continue
            if fid >= 200000:
                continue
            low = path.lower()
            if low.startswith("tileset/") and low.endswith(".blp"):
                parts = low.split("/")
                if len(parts) == 3:
                    tiles.setdefault(parts[1], []).append((fid, parts[2]))
            elif low.startswith("spells/") and low.endswith(".m2"):
                spells[low[len("spells/"):-3]] = fid
    out = ["-- Generated by tools/gen_maps.py from the WoW community listfile. Do not edit.",
           "-- Battle-map themes per chapter: platform surface / body terrain textures (client FileDataIDs),",
           "-- fallback colours and layout style (field / dungeon / raid).",
           "local ADDON, ns = ...", "ns.Data = ns.Data or {}", "local D = ns.Data", "D.MapThemes = {"]
    for ch in range(1, 48):
        folder = CHAPTER_FOLDER[ch]
        files = sorted(tiles.get(folder, []))
        good = [(fid, n) for fid, n in files if not BAD.search(n)]
        style = "field" if ch <= 28 else ("dungeon" if ch <= 40 else "raid")
        keys = SPECIAL_SURFACE.get(ch) or (DUNGEON_SURFACE if style != "field" else SURFACE_KEYS)

        def pick(order, exclude=None):
            for k in order:
                for fid, n in good:
                    if k in n and fid != exclude:
                        return fid, k, n
            return None, None, None
        sf, sk, sn = pick(keys)
        bf, bk, bn = pick(BODY_KEYS, sf)
        sc = COLORS.get(sk or "dirt", COLORS["dirt"])
        bc = COLORS.get(bk or "rock", COLORS["rock"])
        out.append('    [%d] = { folder = "%s", style = "%s", surface = %s, body = %s, top = { %.2f, %.2f, %.2f }, '
                   'bodyColor = { %.2f, %.2f, %.2f } }, -- %s / %s'
                   % (ch, folder, style, sf or "nil", bf or "nil", sc[0], sc[1], sc[2], bc[0] * 0.8, bc[1] * 0.8, bc[2] * 0.8,
                      sn, bn))
    out.append("}")
    with open(addon + "/Data/MapThemes.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    missing = [e for e in EFFECTS if e not in spells]
    eo = ["-- Generated by tools/gen_maps.py from the WoW community listfile. Do not edit.",
          "-- Spell effect models (client FileDataIDs) and keyword rules: WoW spell name -> missile / impact / area.",
          "local ADDON, ns = ...", "ns.Data = ns.Data or {}", "local D = ns.Data", "D.EffectModels = {"]
    for e in EFFECTS:
        if e in spells:
            eo.append('    ["%s"] = %d,' % (e, spells[e]))
    eo.append("}")
    eo.append("D.EffectRules = {")
    for kw, (m, i, a) in RULES:
        eo.append('    { "%s", %s, %s, %s },' % (kw, '"%s"' % m if m else "nil", '"%s"' % i if i else "nil", '"%s"' % a if a else "nil"))
    eo.append("}")
    eo.append("D.EffectClassDefault = {")
    for cls, (m, i, a) in CLASS_DEFAULT.items():
        eo.append('    %s = { %s, %s, %s },' % (cls, '"%s"' % m if m else "nil", '"%s"' % i if i else "nil", '"%s"' % a if a else "nil"))
    eo.append("}")
    with open(addon + "/Data/SkillEffects.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(eo) + "\n")
    print("themes 47, effects", len(EFFECTS) - len(missing), "missing", missing)


if __name__ == "__main__":
    main()

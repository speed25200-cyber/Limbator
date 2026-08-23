#!/usr/bin/env python3
"""Port Python de Limbator/Utilities/FrenchPhonology.swift.

On ne peut pas exécuter Swift sur Linux sans la toolchain Apple. Ce port suit
le code Swift ligne pour ligne : il permet d'EXÉCUTER l'algorithme de
phonétisation et de le confronter à de vraies paires d'homophones français.
Toute divergence trouvée ici est une divergence dans le Swift.
"""

VOWEL_LETTERS = set("aeiouyáàâäéèêëíîïóôöúùûüÿ")
ACCENTED = set("áàâäéèêëíîïóôöúùûüÿ")

ASPIRATE_H = {
    "hache","hachis","haie","haine","hall","halle","halte","hamac","hamburger",
    "hameau","hamster","hanche","handicap","hangar","hanter","happer","harceler",
    "hardi","hareng","hargne","haricot","harpe","hasard","hâte","hausse","haut",
    "hauteur","havre","hennir","hérisson","hernie","héros","hêtre","heurter",
    "hibou","hiérarchie","hip","hisser","hobby","hocher","hockey","hollande",
    "homard","hongrois","honte","hoquet","horde","hors","hotte","houle","housse",
    "hublot","huche","huer","huit","hurler","hutte",
}

ILL_AS_L = {
    "ville","villes","village","villages","villageois","villa","villas","mille",
    "milles","million","millions","milliard","milliards","millier","milliers",
    "milligramme","millimètre","tranquille","tranquilles","tranquillement",
    "tranquillité","distiller","osciller","bacille","pupille","codicille","imbécile",
}

CH_AS_K = ["chœur","choeur","chorale","choral","chore","chorégraph","chrom","chron",
           "chlor","christ","chaos","chaotique","cholest","chiromanc","chrysanth",
           "écho","orchestr","orchid","techn","psych","archéo","archa","archétype",
           "archange","trachée","eucharist","varech","krach","lichen"]

FINAL_R_PRONOUNCED = {"hier","hiver","mer","cher","chère","fer","ver","amer","fier",
                      "cancer","enfer","super","hamster","revolver","leader","cuiller",
                      "mouchoir","soir","noir","pour","sur","car","par","or","mur"}
FINAL_L_SILENT = {"gentil","outil","fusil","sourcil","persil","chenil","nombril",
                  "cul","soûl","saoul"}
FINAL_F_SILENT = {"clef","cerf","nerf","chef-d'œuvre"}


FOLD = {"à":"a","á":"a","â":"a","ä":"a",
        "í":"i","î":"i",
        "ó":"o","ô":"o","ö":"o",
        "ú":"u","ù":"u","û":"u"}

IRREGULAR = {
    "aient":"e","aie":"e","aies":"e","eu":"u","eue":"u","eus":"u","eut":"u",
    "sept":"set","huit":"Hit","fils":"fis","femme":"fam","monsieur":"mesjE",
    "messieurs":"mesjE","second":"segO","seconde":"segOd","automne":"oton",
    "oignon":"oNO","pays":"pei","aujourdhui":"oZuRdHi","aout":"u","plus":"plu",
    "oeufs":"E","boeufs":"bE","est":"e","ouest":"west","monsieurs":"mesjE",
}

SUFFIX_REWRITES = [("aient","ai"),("oient","oi"),("uient","ui")]


def preprocess(word):
    s = word.lower()
    s = s.replace("\u2019", "'").replace("œ", "oe").replace("æ", "ae").replace("'", "")
    s = "".join(FOLD.get(c, c) for c in s)
    s = "".join(c for c in s if c.isalpha() or c == "-")
    for suf, rep in SUFFIX_REWRITES:
        if s.endswith(suf) and len(s) > len(suf):
            s = s[:-len(suf)] + rep
            break
    return s


def _nasal_at(i, chars, n):
    def at(k):
        return chars[k] if 0 <= k < n else None

    def has(s, k):
        return k + len(s) <= n and "".join(chars[k:k + len(s)]) == s

    def nasalises(length):
        nxt = at(i + length)
        if nxt is None:
            return True
        if nxt in VOWEL_LETTERS:
            return False
        if nxt in ("n", "m"):
            return False
        return True

    for pat, snd in [("oin","wI"),("ain","I"),("aim","I"),("ein","I"),("eim","I"),
                     ("ien","jI"),("yen","jI"),("éen","eI")]:
        if has(pat, i) and nasalises(3):
            return snd, 3
    for pat, snd in [("an","A"),("am","A"),("en","A"),("em","A"),("on","O"),("om","O"),
                     ("in","I"),("im","I"),("un","I"),("um","I"),("yn","I"),("ym","I")]:
        if has(pat, i) and nasalises(2):
            return snd, 2
    return None


def _vowel_sound(c, chars, i, n, out):
    if c in "aàâáä": return "a"
    if c in "eéèêë": return "e"
    if c == "ï": return "i"
    if c == "ü": return "u"
    if c == "ÿ": return "i"
    if c in "iîïí":
        return "j" if i + 1 < n and chars[i + 1] in VOWEL_LETTERS else "i"
    if c in "oôóö": return "o"
    if c in "uûùúü":
        return "H" if i + 1 < n and chars[i + 1] in VOWEL_LETTERS else "u"
    if c in "yÿ":
        return "j" if i + 1 < n and chars[i + 1] in VOWEL_LETTERS else "i"
    return c


def _consonant_sound(c, chars, i, n):
    nxt = chars[i + 1] if i + 1 < n else None
    prv = chars[i - 1] if i - 1 >= 0 else None
    if c == "c":
        return "s" if nxt and nxt in "eiyéèêë" else "k"
    if c == "ç": return "s"
    if c == "g":
        return "Z" if nxt and nxt in "eiyéèê" else "g"
    if c == "s":
        if prv and nxt and prv in VOWEL_LETTERS and nxt in VOWEL_LETTERS:
            return "z"
        return "s"
    if c == "x":
        return "gz" if i == 0 else "ks"
    if c == "h": return ""
    if c == "q": return "k"
    if c == "j": return "Z"
    if c == "r": return "R"
    if c == "w": return "v"
    if c == "y": return "j"
    return c


SILENT_TAIL = set("stdzxpg")


def _is_silent_final(c, word, chars, n):
    if c == "e": return True
    if c in "stdzxp": return True
    if c == "g": return True
    if c == "l": return word in FINAL_L_SILENT
    if c == "f": return word in FINAL_F_SILENT
    if c == "r": return False
    if c == "c": return n >= 2 and chars[n - 2] == "n"
    if c in "mn": return False
    return False


def _ch_is_k(word):
    return any(p in word for p in CH_AS_K)


def transcribe(chars, silent_ent):
    n = len(chars)
    if n == 0: return ""
    word = "".join(chars)
    if not silent_ent and word in IRREGULAR:
        return IRREGULAR[word]
    out = []
    i = 0

    def at(k): return chars[k] if 0 <= k < n else None
    def is_vowel(k):
        c = at(k)
        return c in VOWEL_LETTERS if c else False
    def m(s, k):
        return k + len(s) <= n and "".join(chars[k:k + len(s)]) == s
    def ends_at(k): return k >= n

    while i < n:
        c = chars[i]
        last = (i == n - 1)

        if silent_ent and i == n - 3 and m("ent", i):
            break

        na = _nasal_at(i, chars, n)
        if na:
            out.append(na[0]); i += na[1]; continue

        if m("eau", i): out.append("o"); i += 3; continue
        if m("aux", i) and ends_at(i + 3): out.append("o"); i += 3; continue
        if m("eaux", i): out.append("o"); i += 4; continue
        if m("au", i): out.append("o"); i += 2; continue
        if m("oeu", i): out.append("E"); i += 3; continue
        if m("eu", i): out.append("E"); i += 2; continue
        if m("oy", i) and is_vowel(i + 2): out.append("waj"); i += 2; continue
        if m("oi", i): out.append("wa"); i += 2; continue
        if m("ou", i):
            out.append("w" if is_vowel(i + 2) else "U"); i += 2; continue
        if m("aî", i) or m("ai", i) or m("ei", i):
            out.append("e"); i += 2; continue
        if m("ay", i):
            out.append("ej" if is_vowel(i + 2) else "e"); i += 2; continue

        if m("ch", i):
            out.append("k" if _ch_is_k(word) else "S"); i += 2; continue
        if m("ph", i): out.append("f"); i += 2; continue
        if m("gn", i): out.append("N"); i += 2; continue
        if m("th", i): out.append("t"); i += 2; continue
        if m("qu", i): out.append("k"); i += 2; continue
        if m("gu", i) and at(i + 2) and at(i + 2) in "eiéèêy":
            out.append("g"); i += 2; continue
        if m("ill", i):
            out.append("il" if word in ILL_AS_L else "j"); i += 3; continue
        if m("sc", i) and at(i + 2) and at(i + 2) in "eiyéèê":
            out.append("s"); i += 2; continue
        if m("tion", i): out.append("sjO"); i += 4; continue
        if m("ss", i): out.append("s"); i += 2; continue

        if i == n - 2:
            if m("er", i):
                out.append("eR" if word in FINAL_R_PRONOUNCED else "e"); i += 2; continue
            if m("ez", i): out.append("e"); i += 2; continue
            if m("et", i): out.append("e"); i += 2; continue
            if m("es", i):
                stem = chars[:i]
                voiced = not any(ch in VOWEL_LETTERS for ch in stem)
                out.append("e" if voiced else ""); i += 2; continue

        if i > 0 and out and all(ch in SILENT_TAIL for ch in chars[i:]):
            break

        nx = at(i + 1)
        if nx is not None and nx == c and c not in VOWEL_LETTERS:
            out.append(_consonant_sound(c, chars, i, n)); i += 2; continue

        if last and _is_silent_final(c, word, chars, n):
            break

        if c in VOWEL_LETTERS:
            out.append(_vowel_sound(c, chars, i, n, "".join(out)))
        else:
            out.append(_consonant_sound(c, chars, i, n))
        i += 1

    return "".join(out)


def keys(word):
    cleaned = preprocess(word)
    if not cleaned: return [""]
    if "-" in cleaned:
        return ["".join(transcribe(list(p), False) for p in cleaned.split("-") if p)]
    chars = list(cleaned)
    primary = transcribe(chars, False)
    if cleaned.endswith("ent") and len(cleaned) > 4:
        alt = transcribe(chars, True)
        return [primary] if alt == primary else [primary, alt]
    return [primary]


def sound_key(word):
    return keys(word)[0]


def are_homophones(a, b):
    ka, kb = set(keys(a)), set(keys(b))
    if not ka or not kb: return False
    if ka == {""} or kb == {""}: return a == b
    return bool(ka & kb)


# =============================================================================
# Port de Limbator/Services/OrthographyEngine.swift (classification)
# =============================================================================
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def strip_accents(s):
    return "".join(c for c in unicodedata.normalize("NFD", s)
                   if unicodedata.category(c) != "Mn")


def normalize_typography(s):
    t = (s.replace("’", "'").replace("ʼ", "'")
          .replace(" ", " ").replace(" ", " ")
          .replace("–", "-").replace("—", "-")
          .replace("«", '"').replace("»", '"')
          .replace("“", '"').replace("”", '"')
          .replace("…", "..."))
    return re.sub(r"[ \t]+", " ", t).strip()


def skeleton(s):
    return "".join(c for c in strip_accents(s.lower())
                   if c.isalpha() or c in "-'")


def collapse_doubles(s):
    out, prev = [], None
    for ch in s:
        if prev == ch and ch not in VOWEL_LETTERS:
            continue
        out.append(ch)
        prev = ch
    return "".join(out)


def load_ro_traps():
    """Lit la table RomanianInterference.swift : la source de vérité reste le Swift."""
    text = (ROOT / "Limbator/Services/RomanianInterference.swift").read_text()
    traps = {}
    pattern = re.compile(
        r'\.init\(french:\s*"([^"]+)",\s*calques:\s*\[([^\]]*)\]', re.S)
    for french, calques in pattern.findall(text):
        items = re.findall(r'"([^"]*)"', calques)
        traps[french.lower()] = [c.lower() for c in items]
    return traps


RO_TRAPS = load_ro_traps()
RO_BY_CALQUE = {c: f for f, cs in RO_TRAPS.items() for c in cs}


def ro_trap(expected, written):
    e, w = expected.lower().strip(), written.lower().strip()
    if e == w:
        return None
    if RO_BY_CALQUE.get(w) == e:
        return e
    if e in RO_TRAPS:
        if strip_accents(collapse_doubles(w)) == strip_accents(collapse_doubles(e)):
            return e
    return None


VERB_ENDING_GROUPS = [
    {"er","é","ez","ée","és","ées","ai","aient","ait","ais","aie","aies"},
    {"ir","i","ie","is","it","ies","its"},
    {"u","ue","us","ues","ut"},
]
VERB_PAIRS = {("é","er"),("er","é"),("é","ez"),("ez","é"),("ée","er"),("és","er"),
              ("ées","er"),("ais","ait"),("ait","ais"),("ai","ais"),("ais","ai"),
              ("aient","ait"),("ait","aient"),("ai","é"),("é","ai")}
AGREEMENT_MARKS = {"s","e","es","x","aux","ux","nes","ne","le","les","te","tes"}
TREMA = set("ëïüÿ")


def _accent_subtype(expected, written):
    e, w = expected.lower(), written.lower()
    if "ç" in e and "ç" not in w: return "cedillaMissing"
    if "ç" in w and "ç" not in e: return "cedillaExtra"
    if any(c in TREMA for c in e) and not any(c in TREMA for c in w):
        return "tremaMissing"
    def marks(s):
        return [c for c in s if c in ACCENTED or c == "ç"]
    em, wm = marks(e), marks(w)
    if not wm and em: return "accentMissing"
    if not em and wm: return "accentExtra"
    if len(wm) < len(em): return "accentMissing"
    if len(wm) > len(em): return "accentExtra"
    return "accentWrong"


def _common_prefix(a, b):
    i = 0
    while i < len(a) and i < len(b) and a[i] == b[i]:
        i += 1
    return i


def _verb_ending(expected, written):
    common = _common_prefix(expected, written)
    if common < 2: return None
    e_end, w_end = expected[common:], written[common:]
    if not e_end and not w_end: return None
    for group in VERB_ENDING_GROUPS:
        if e_end in group and w_end in group:
            return "verbEnding"
    if (e_end, w_end) in VERB_PAIRS:
        return "verbEnding"
    return None


def _agreement(expected, written):
    if expected.startswith(written) and expected[len(written):] in AGREEMENT_MARKS:
        return "agreement"
    if written.startswith(expected) and written[len(expected):] in AGREEMENT_MARKS:
        return "agreement"
    if expected.endswith("aux") and written.endswith("als") and expected[:-3] == written[:-3]:
        return "agreement"
    if expected.endswith("als") and written.endswith("aux") and expected[:-3] == written[:-3]:
        return "agreement"
    return None


def classify(expected, written):
    e, w = normalize_typography(expected), normalize_typography(written)
    if e == w: return "typo"
    el, wl = e.lower(), w.lower()

    if el == wl: return "capitalization"
    if known_homophones(e, w): return "homophone"
    if ro_trap(e, w): return "romanianInterference"

    delig = lambda s: s.replace("œ", "oe").replace("æ", "ae")
    if delig(el) == delig(wl): return "ligature"

    if el.replace("'", "") == wl.replace("'", ""):
        return "elision" if ("'" in el and "'" not in wl) else "apostrophe"
    if ("'" in el) != ("'" in wl) and \
       skeleton(e).replace("'", "") == skeleton(w).replace("'", ""):
        return "elision"

    if el.replace("-", "") == wl.replace("-", ""): return "hyphen"
    if skeleton(e) == skeleton(w): return _accent_subtype(e, w)

    if collapse_doubles(el) == collapse_doubles(wl): return "doubleConsonant"
    if collapse_doubles(skeleton(e)) == collapse_doubles(skeleton(w)):
        return "doubleConsonant"

    r = _verb_ending(el, wl)
    if r: return r
    r = _agreement(el, wl)
    if r: return r

    if el.startswith(wl) and 0 < len(el) - len(wl) <= 2:
        if all(c in "estdxzpgh" for c in el[len(wl):]): return "silentLetter"
    if wl.startswith(el) and 0 < len(wl) - len(el) <= 2:
        if all(c in "estdxzpgh" for c in wl[len(el):]): return "silentLetter"

    if are_homophones(e, w): return "homophone"
    return "typo"



def load_homophone_sets():
    """Lit les familles d'homophones depuis OrthoSeeds.swift (source de vérité)."""
    text = (ROOT / "Limbator/Services/OrthoSeeds.swift").read_text()
    sets = []
    for block in re.findall(r'HomophoneSet\(id:\s*"([^"]+)".*?\n        \]\)', text, re.S):
        pass
    # Découpage simple : chaque famille commence par `HomophoneSet(id: "..."`.
    chunks = re.split(r'HomophoneSet\(id:\s*"', text)[1:]
    for chunk in chunks:
        sid = chunk.split('"')[0]
        forms = re.findall(r'\.init\(form:\s*"([^"]*)"', chunk)
        sound = re.search(r'sound:\s*"([^"]*)"', chunk)
        if forms:
            sets.append({"id": sid, "sound": sound.group(1) if sound else "",
                         "forms": [f.lower() for f in forms]})
    return sets


HOMOPHONE_SETS = load_homophone_sets()
FORM_TO_SET = {f: s for s in HOMOPHONE_SETS for f in s["forms"]}


def known_homophones(a, b):
    x = a.lower().strip()
    y = b.lower().strip()
    if x == y:
        return False
    s = FORM_TO_SET.get(x)
    return bool(s and y in s["forms"])

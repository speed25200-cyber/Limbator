#!/usr/bin/env python3
"""Un lexeur Swift minimal, partagé par les vérificateurs.

Le contenu pédagogique de Limbator est écrit en français et en roumain, à
l'intérieur de littéraux de chaîne. Toute analyse qui les lit comme du code
prend un nom propre pour un type manquant et une énumération de mots pour une
liste de cas. On les retire donc avant d'analyser quoi que ce soit.
"""
import re


def strip_noise(text: str) -> str:
    """Retire commentaires et littéraux, en préservant les retours à la ligne.

    Le contenu des interpolations `\\(…)` est conservé : c'est du vrai code.
    """
    out = []
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if ch == "/" and i + 1 < n and text[i + 1] == "*":
            depth, i = 1, i + 2
            while i < n and depth:
                if text.startswith("/*", i): depth += 1; i += 2
                elif text.startswith("*/", i): depth -= 1; i += 2
                else:
                    if text[i] == "\n": out.append("\n")
                    i += 1
            continue
        if text.startswith('"""', i):
            i += 3
            while i < n and not text.startswith('"""', i):
                if text[i] == "\n": out.append("\n")
                i += 1
            i += 3
            out.append(' ""$ ')
            continue
        if ch == '"':
            i += 1
            while i < n and text[i] != '"':
                if text.startswith("\\(", i):
                    depth, i = 1, i + 2
                    while i < n and depth:
                        if text[i] == "(": depth += 1
                        elif text[i] == ")": depth -= 1
                        if depth: out.append(text[i])
                        i += 1
                    continue
                if text[i] == "\\":
                    i += 2
                    continue
                i += 1
            i += 1
            out.append(' ""$ ')
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def enum_body(code: str, name: str) -> str:
    """Le corps d'une énumération, accolades appariées."""
    match = re.search(rf'\benum\s+{name}\b[^{{]*\{{', code)
    if not match:
        return ""
    start, depth, i = match.end(), 1, match.end()
    while i < len(code) and depth:
        if code[i] == "{": depth += 1
        elif code[i] == "}": depth -= 1
        i += 1
    return code[start:i]


def enum_cases(code: str, name: str) -> list:
    """Les cas déclarés, dans l'ordre. Gère les listes sur plusieurs lignes."""
    body = enum_body(code, name)
    names = []
    # Une déclaration de cas court jusqu'à la fin de ligne, sauf si elle se
    # termine par une virgule : la liste continue alors sur la suivante.
    buffer = ""
    for line in body.split("\n"):
        stripped = line.strip()
        if buffer:
            buffer += " " + stripped
        elif stripped.startswith("case "):
            buffer = stripped[5:]
        else:
            continue
        if buffer.rstrip().endswith(","):
            continue
        for part in buffer.split(","):
            token = part.strip().split("(")[0].split("=")[0].split(":")[0].strip()
            if re.fullmatch(r'[a-z]\w*', token) and token not in names:
                names.append(token)
        buffer = ""
    return names

#!/usr/bin/env python3
"""Dessine l'icône de Limbator.

Le motif est un **É** : un E de style didone — le classique typographique
français, à fort contraste entre pleins et déliés — surmonté d'un accent aigu
détaché, en or.

Le choix n'est pas décoratif. En français, l'accent n'est pas un ornement posé
sur une lettre : il fait partie du mot. « Eleve » n'est pas « élève » mal écrit,
c'est un mot qui n'existe pas. Montrer l'accent détaché, dans une autre matière
que la lettre, dit exactement ce que l'application enseigne.

Rendu à 4096 px puis réduit à 1024 en Lanczos : les hairlines du didone font
quelques pixels à la taille finale et ne survivent pas à un rendu direct.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Limbator/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

SUPER = 4          # facteur de suréchantillonnage
FINAL = 1024
SIZE = FINAL * SUPER

# Palette — la même que Theme.swift.
ENCRE      = (0x05, 0x06, 0x0F)
NUIT       = (0x0B, 0x10, 0x26)
NUIT_HAUT  = (0x16, 0x1E, 0x42)
BLEU       = (0x2A, 0x6D, 0xF4)
LAVANDE    = (0x8B, 0x6B, 0xFF)
OR         = (0xE8, 0xC5, 0x6A)
OR_CLAIR   = (0xF7, 0xE6, 0xB4)
OR_SOMBRE  = (0xB8, 0x8A, 0x38)
IVOIRE     = (0xFF, 0xF6, 0xE9)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    """Dégradé vertical, calculé ligne par ligne puis étiré."""
    strip = Image.new("RGB", (1, size))
    pixels = strip.load()
    for y in range(size):
        pixels[0, y] = lerp(top, bottom, y / max(1, size - 1))
    return strip.resize((size, size), Image.BILINEAR)


def radial_glow(size, color, center, radius, strength):
    """Halo radial doux, dessiné en anneaux concentriques puis flouté."""
    layer = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(layer)
    steps = 90
    for i in range(steps, 0, -1):
        t = i / steps
        r = radius * t
        alpha = int(strength * (1 - t) ** 2 * 255)
        if alpha <= 0:
            continue
        draw.ellipse([center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=alpha)
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.12))
    tint = Image.new("RGB", (size, size), color)
    return tint, layer


def guilloche(size, color, opacity):
    """Trame d'arcs concentriques très pâle.

    Invisible à 60 px dans une liste d'applications, perceptible sur la fiche
    de l'App Store : c'est le genre de détail qui fait qu'une icône ne paraît
    pas plate en grand format.
    """
    layer = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(layer)
    cx, cy = size * 0.5, size * 0.46
    width = max(1, size // 900)
    for i in range(26):
        r = size * (0.16 + i * 0.032)
        draw.ellipse([cx - r, cy - r * 0.96, cx + r, cy + r * 0.96],
                     outline=int(opacity * 255), width=width)
    layer = layer.filter(ImageFilter.GaussianBlur(size * 0.0016))
    tint = Image.new("RGB", (size, size), color)
    return tint, layer


# ---------------------------------------------------------------------------
# Le E didone
# ---------------------------------------------------------------------------

def draw_didone_e(draw, box, fill):
    """Trace un E à fort contraste dans la boîte (x, y, largeur, hauteur).

    Proportions d'un didone : la hampe verticale est épaisse, les barres
    horizontales sont des déliés, et chaque extrémité porte un empattement
    marqué. C'est ce contraste qui fait lire « typographie française ».
    """
    x, y, w, h = box
    stem = w * 0.205          # hampe : le plein
    hair = h * 0.058          # délié : le contraste didone tient à cet écart
    serif_w = w * 0.038       # débord des empattements
    serif_h = h * 0.040

    top_len = w * 0.800
    mid_len = w * 0.615
    bot_len = w * 0.880

    mid_y = y + h * 0.455 - hair * 0.5

    # Hampe.
    draw.rectangle([x, y, x + stem, y + h], fill=fill)

    # Barres, légèrement fuselées : plus épaisses contre la hampe, plus fines
    # au terminal. C'est ce très léger renflement qui distingue une lettre
    # dessinée d'un assemblage de rectangles.
    def tapered_bar(top_y, length, thickness):
        near = thickness * 1.09
        far = thickness * 0.91
        draw.polygon([
            (x, top_y - (near - thickness) * 0.5),
            (x + length, top_y + (thickness - far) * 0.5),
            (x + length, top_y + thickness - (thickness - far) * 0.5),
            (x, top_y + thickness + (near - thickness) * 0.5),
        ], fill=fill)

    tapered_bar(y, top_len, hair)
    tapered_bar(mid_y, mid_len, hair * 0.88)
    tapered_bar(y + h - hair, bot_len, hair)

    # Empattements aux extrémités des barres : un débord vertical, fin.
    draw.rectangle([x + top_len - serif_w, y - serif_h,
                    x + top_len, y + hair + serif_h], fill=fill)
    draw.rectangle([x + mid_len - serif_w * 0.85, mid_y - serif_h * 0.8,
                    x + mid_len, mid_y + hair + serif_h * 0.8], fill=fill)
    draw.rectangle([x + bot_len - serif_w, y + h - hair - serif_h,
                    x + bot_len, y + h + serif_h], fill=fill)

    # Empattements de la hampe : un débord à gauche, en haut et en bas.
    draw.rectangle([x - serif_w * 0.9, y - serif_h * 0.5,
                    x + stem + serif_w * 0.35, y + hair], fill=fill)
    draw.rectangle([x - serif_w * 0.9, y + h - hair,
                    x + stem + serif_w * 0.35, y + h + serif_h * 0.5], fill=fill)


def draw_acute(draw, cx, cy, length, thickness, angle_deg, fill):
    """Trace un accent AIGU : un coin qui MONTE vers la droite.

    Le sens n'est pas une préférence graphique. L'aigu monte (é), le grave
    descend (è), et ils désignent deux sons différents. Dans une application qui
    enseigne l'orthographe, dessiner l'un pour l'autre serait une faute affichée
    sur l'écran d'accueil du téléphone.

    L'angle est donc NÉGATIF : en coordonnées d'image l'axe vertical descend,
    et monter vers la droite veut dire y décroissant.

    La forme est un coin, épais en haut à droite et effilé en bas à gauche —
    la construction du didone, où l'accent est taillé comme au burin. Un simple
    rectangle incliné ferait « barre oblique ».
    """
    angle = math.radians(angle_deg)
    half = length / 2
    # Repère local : l'axe long de l'accent, puis sa perpendiculaire.
    ux, uy = math.cos(angle), math.sin(angle)
    px, py = -uy, ux

    thick_end = thickness
    thin_end = thickness * 0.34

    points = [
        (cx - ux * half - px * thin_end * 0.5,  cy - uy * half - py * thin_end * 0.5),
        (cx - ux * half + px * thin_end * 0.5,  cy - uy * half + py * thin_end * 0.5),
        (cx + ux * half + px * thick_end * 0.5, cy + uy * half + py * thick_end * 0.5),
        (cx + ux * half - px * thick_end * 0.5, cy + uy * half - py * thick_end * 0.5),
    ]
    draw.polygon(points, fill=fill)


def gradient_masked(size, top_color, bottom_color, mask):
    """Applique un dégradé vertical à travers un masque."""
    gradient = vertical_gradient(size, top_color, bottom_color)
    return gradient, mask


# ---------------------------------------------------------------------------

def build():
    size = SIZE
    canvas = vertical_gradient(size, NUIT_HAUT, ENCRE).convert("RGB")

    # Bloom bleu derrière la lettre.
    tint, mask = radial_glow(size, BLEU, (size * 0.5, size * 0.44), size * 0.60, 0.52)
    canvas = Image.composite(tint, canvas, mask.point(lambda v: int(v * 0.68)))

    # Nappe lavande décalée : donne de la profondeur sans virer au violet.
    tint, mask = radial_glow(size, LAVANDE, (size * 0.74, size * 0.72), size * 0.46, 0.40)
    canvas = Image.composite(tint, canvas, mask.point(lambda v: int(v * 0.30)))

    # Trame guilloché.
    tint, mask = guilloche(size, (0x9F, 0xB8, 0xFF), 0.055)
    canvas = Image.composite(tint, canvas, mask)

    # ---- La lettre --------------------------------------------------------
    letter_mask = Image.new("L", (size, size), 0)
    ldraw = ImageDraw.Draw(letter_mask)
    # Le E est asymétrique : son centre optique tombe vers 45 % de sa largeur
    # d'empattement. On le décale pour que le bloc entier paraisse centré.
    box = (size * 0.342, size * 0.356, size * 0.372, size * 0.388)
    draw_didone_e(ldraw, box, 255)

    # Ombre portée : la lettre doit sembler posée sur le fond, pas collée.
    shadow = letter_mask.filter(ImageFilter.GaussianBlur(size * 0.012))
    shadow = shadow.point(lambda v: int(v * 0.55))
    canvas = Image.composite(Image.new("RGB", (size, size), (0, 0, 0)), canvas,
                             shadow.transform(
                                 (size, size), Image.AFFINE,
                                 (1, 0, 0, 0, 1, -size * 0.010)))

    letter_gradient = vertical_gradient(size, (255, 255, 255), lerp(IVOIRE, BLEU, 0.30))
    canvas = Image.composite(letter_gradient, canvas, letter_mask)

    # ---- L'accent ---------------------------------------------------------
    accent_mask = Image.new("L", (size, size), 0)
    adraw = ImageDraw.Draw(accent_mask)
    # L'accent flotte franchement au-dessus de la lettre. En typographie il
    # serait plus proche ; ici l'écart est le propos de l'icône — l'accent est
    # une pièce à part, pas une décoration collée au E.
    draw_acute(adraw,
               cx=size * 0.510, cy=size * 0.272,
               length=size * 0.132, thickness=size * 0.046,
               angle_deg=-30, fill=255)

    # Halo doré autour de l'accent : c'est lui le sujet de l'icône.
    halo = accent_mask.filter(ImageFilter.GaussianBlur(size * 0.026))
    canvas = Image.composite(Image.new("RGB", (size, size), OR), canvas,
                             halo.point(lambda v: int(v * 0.70)))

    accent_gradient = vertical_gradient(size, OR_CLAIR, OR_SOMBRE)
    canvas = Image.composite(accent_gradient, canvas, accent_mask)

    # ---- Lumière de bord --------------------------------------------------
    # Un liseré clair en haut, comme sur une surface vernie.
    rim = Image.new("L", (size, size), 0)
    rdraw = ImageDraw.Draw(rim)
    rdraw.rectangle([0, 0, size, size * 0.012], fill=90)
    rim = rim.filter(ImageFilter.GaussianBlur(size * 0.010))
    canvas = Image.composite(Image.new("RGB", (size, size), (255, 255, 255)), canvas, rim)

    # ---- Vignette ---------------------------------------------------------
    vignette = Image.new("L", (size, size), 0)
    vdraw = ImageDraw.Draw(vignette)
    steps = 60
    for i in range(steps):
        t = i / steps
        inset = size * 0.5 * t
        vdraw.ellipse([inset - size * 0.18, inset - size * 0.18,
                       size - inset + size * 0.18, size - inset + size * 0.18],
                      outline=0, width=1)
    vignette = Image.new("L", (size, size), 0)
    vdraw = ImageDraw.Draw(vignette)
    for i in range(50):
        t = i / 50
        r = size * (0.78 + t * 0.42)
        vdraw.ellipse([size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r],
                      outline=int(t * 90), width=int(size * 0.012))
    vignette = vignette.filter(ImageFilter.GaussianBlur(size * 0.03))
    canvas = Image.composite(Image.new("RGB", (size, size), (0, 0, 0)), canvas,
                             vignette.point(lambda v: int(v * 0.42)))

    final = canvas.resize((FINAL, FINAL), Image.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Les icônes de l'App Store doivent être opaques et sans canal alpha.
    final.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"{OUT.relative_to(ROOT)} — {FINAL}x{FINAL}, {OUT.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    build()

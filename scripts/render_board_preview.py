"""Рендер превью доски «Рэндзю для Дианы» — имитация Flutter-дизайна:
тёплая деревянная доска, сетка пересечений, звёздные точки, объёмные камни
с бликом и тенью, кольцо последнего хода, победная линия."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle
from matplotlib.colors import LinearSegmentedColormap
import numpy as np

CREAM = "#FFF8E7"
WOOD_LIGHT = "#E2B87C"
WOOD_MID = "#D4A574"
WOOD_DARK = "#B8864E"
LINE = "#5D4037"
STONE_BLACK = "#1A1A1A"
STONE_BLACK_HI = "#6E6E6E"
STONE_WHITE = "#FBFBF6"
STONE_WHITE_EDGE = "#C9C2B5"
CORAL = "#FF7A5C"
SUNFLOWER = "#FFC857"
TEXT = "#3E2723"

N = 9
fig, ax = plt.subplots(figsize=(7.2, 7.2), dpi=110)
fig.patch.set_facecolor(CREAM)
ax.set_facecolor(CREAM)

gradient = np.linspace(0, 1, 256).reshape(-1, 1)
cmap = LinearSegmentedColormap.from_list("wood", [WOOD_LIGHT, WOOD_MID, WOOD_DARK])
ax.imshow(gradient, extent=[0, N, 0, N], origin="lower", aspect="auto", cmap=cmap, alpha=0.95)

for i in range(8):
    ax.axhline(0.3 + i * (N - 0.6) / 7, color=(0, 0, 0, 0.04), lw=1, zorder=1)

off = 0.5
for i in range(N):
    ax.plot([off + 0, off + (N - 1)], [off + i, off + i], color=LINE, lw=1.6, zorder=2)
    ax.plot([off + i, off + i], [off + 0, off + (N - 1)], color=LINE, lw=1.6, zorder=2)

stars = [(2, 2), (6, 2), (4, 4), (2, 6), (6, 6)]
for (x, y) in stars:
    ax.add_patch(Circle((off + x, off + y), 0.07, color=LINE, zorder=3))

def stone(x, y, color):
    cx, cy = off + x, off + y
    ax.add_patch(Circle((cx + 0.04, cy - 0.06), 0.42, color=(0, 0, 0, 0.28), zorder=4))
    r = 0.42
    grad = np.linspace(0, 1, 50).reshape(-1, 1)
    if color == STONE_BLACK:
        c = LinearSegmentedColormap.from_list("blk", [STONE_BLACK_HI, STONE_BLACK])
    else:
        c = LinearSegmentedColormap.from_list("wht", ["#FFFFFF", STONE_WHITE, STONE_WHITE_EDGE])
    ax.imshow(grad, extent=[cx - r, cx + r, cy - r, cy + r], origin="lower",
              aspect="equal", cmap=c, zorder=5)
    ax.add_patch(Circle((cx - 0.14, cy + 0.14), 0.08, color=(1, 1, 1, 0.55), zorder=6))

win_line = [(4, 6), (5, 6), (6, 6), (7, 6), (8, 6)]
black = [(0, 4), (1, 4), (4, 6), (5, 6), (6, 6), (4, 7), (3, 3), (7, 2)] + win_line
white = [(2, 4), (3, 2), (5, 3), (6, 3), (4, 5), (2, 6), (7, 5)]

for (x, y) in black:
    stone(x, y, STONE_BLACK)
for (x, y) in white:
    stone(x, y, STONE_WHITE)

lx, ly = 8, 6
ax.add_patch(Circle((off + lx, off + ly), 0.46, fill=False, ec=SUNFLOWER, lw=3, zorder=7))

x0, y0 = off + win_line[0][0], off + win_line[0][1]
x1, y1 = off + win_line[-1][0], off + win_line[-1][1]
ax.plot([x0, x1], [y0, y1], color=SUNFLOWER, lw=8, alpha=0.65, zorder=6.5, solid_capstyle="round")
for (x, y) in win_line:
    ax.add_patch(Circle((off + x, off + y), 0.48, fill=False, ec=SUNFLOWER, lw=2.5, zorder=6.8))

ax.set_xlim(-0.3, N + 0.3)
ax.set_ylim(-0.3, N + 0.5)
ax.set_aspect("equal")
ax.axis("off")

ax.text(N / 2, N + 0.15, "Рэндзю для Дианы", ha="center", va="bottom",
        fontsize=22, fontweight="bold", color=TEXT)
ax.text(N / 2, -0.2, "Чёрные собрали пять — победа!", ha="center", va="top",
        fontsize=13, color=CORAL)

plt.tight_layout()
plt.savefig("/home/z/my-project/download/board_preview.png", dpi=110, bbox_inches="tight",
            facecolor=CREAM)
print("saved /home/z/my-project/download/board_preview.png")

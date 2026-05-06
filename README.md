# image_dots

Sketch Processing qui convertit une image en nuage de points par **Poisson Disk Sampling à densité variable**.

---

## Principe

On génère directement la distribution finale en faisant varier `r` (la distance minimale entre deux points) en fonction de la luminosité du pixel sous chaque candidat :

```
zone sombre  →  r petit  →  points rapprochés  →  haute densité
zone claire  →  r grand  →  points espacés     →  faible densité
```

La propriété **blue noise** est maintenue à toutes les échelles : pas de clusters, pas de trous. La distribution est perceptuellement uniforme à la densité locale dictée par l'image.

---

## Formule de r_local

Mapping log-linéaire (exponentiel en r) :

```
r_local = r_min × contrast ^ (t_norm ^ gamma)
```

- `t_norm` ∈ [0, 1] : luminosité normalisée du pixel après clamp sur `[min_value, max_value]`, puis inversion optionnelle
- `t_norm = 0` (noir) → `r_local = r_min` (haute densité)
- `t_norm = 1` (blanc) → `r_local = r_min × contrast` = `r_max` (basse densité)

Ce mapping garantit qu'un même écart de luminosité multiplie `r` par le même facteur sur toute la plage de tons, quel que soit le niveau de gris de départ.

---

## Architecture

| Fichier | Rôle |
|---------|------|
| `image_dots.pde` | Setup, draw loop, HUD |
| `DataGlobal.pde` | `ImageDotsData` — agrège image, style, dots, shape |
| `DataDots.pde` | Paramètres Poisson + GUI onglet Dots |
| `DataShape.pde` | Paramètres rendu + GUI onglet Shape |
| `DataGUI.pde` | `MainPanel` — assemble les 5 onglets |
| `DotsGenerator.pde` | Algorithme Poisson Disk Sampling à densité variable |
| `DotsRenderer.pde` | Dessin des points (mode point ou polygone régulier) |

---

## Paramètres Dots

| Paramètre | Défaut | Rôle |
|-----------|--------|------|
| `density` | 0.5 | Densité de base — `r_min = 1 / density` |
| `contrast` | 10 | Ratio `r_max / r_min` — écart entre zones sombres et claires |
| `gamma` | 1.0 | Courbe de densité : `> 1` espace les demi-teintes, `< 1` les resserre |
| `min_value` | 0 | Pixels en dessous traités comme noir (dense) |
| `max_value` | 255 | Pixels au dessus traités comme blanc (vide) |
| `invert` | false | Inverser : zones claires = denses |
| `seed` | 42 | Graine aléatoire |

## Paramètres Shape

| Paramètre | Défaut | Rôle |
|-----------|--------|------|
| `mode` | Point | `Point` ou `Polygon` |
| `sides` | 6 | Nombre de côtés du polygone régulier |
| `size` | 3.0 | Rayon du polygone (en px) |

---

## Détails d'implémentation

### Grille spatiale

La cellule vaut `r_min / √2`, ce qui garantit qu'une cellule contient au plus un point.  
Le rayon d'inspection est `ceil(r_max / cell) + 1` cellules dans chaque direction, pour couvrir tous les voisins potentiels même quand `r_max >> r_min`.

### Génération progressive

La génération s'effectue en tranches de 500 ms (`start()` + `resume()`), ce qui maintient la fluidité de l'interface pendant le calcul. Le HUD affiche le nombre de points et le temps de calcul en temps réel.

### Déclenchement automatique

Le générateur redémarre automatiquement dès qu'un paramètre image ou dots change. Les paramètres style et shape sont appliqués sans recalcul.

---

## Conseils d'utilisation

- Un ratio `contrast` de **5 à 15** donne des résultats équilibrés. Au-delà de 20 les zones claires deviennent quasi-vides.
- `gamma > 1` (ex : 2–3) protège les demi-teintes et évite une transition trop abrupte entre sombre et clair.
- `min_value` / `max_value` permettent de cropper la plage tonale de l'image sans retouche externe.
- En mode **Polygon**, `sides = 3` donne des triangles, `sides = 6` des hexagones — bien adapté aux traceurs.

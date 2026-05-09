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
- `threshold` à 240–250 suffit à purger les points résiduels dans les zones quasi-blanches sans perturber les demi-teintes.
- En mode **Polygon**, `sides = 3` donne des triangles, `sides = 6` des hexagones — bien adapté aux traceurs.

---

## Changelog

### 2026-05-09
- **Threshold (seuil dur)** : ajout du paramètre `threshold` dans `DataDots` et du slider correspondant. Tout candidat dont le pixel dépasse le seuil est rejeté immédiatement dans `_getRLocal`, avant le calcul de `r_local`. Nettoie les quelques points résiduels qui apparaissent dans les zones totalement blanches malgré un `contrast` élevé.

### 2026-05-07 — branche `test/density_pause` (→ main)
- **README** : réécriture complète pour refléter l'état réel du code (formule log-linéaire, architecture, paramètres exacts, conseils).
- **Fix** : suppression d'une valeur statique résiduelle dans `DataDots`.
- **HUD progressif** : affichage du nombre de points et du temps de calcul en temps réel pendant la génération (`totalCalcMillis`, `lastResumeMillis`). Ajout de `StringUtils.formatDuration()` et `StringUtils.formatInt()`.

### 2026-05-06 — branche `test/density_pause`
- **Poisson à densité variable (Direction B)** : refonte complète du `DotsGenerator`. On ne filtre plus une distribution uniforme — on génère directement la distribution finale en calculant un `r_local` pour chaque candidat à partir de la luminosité du pixel sous sa position.
- **Mapping log-linéaire** : `r_local = r_min × contrast ^ (t_norm ^ gamma)`. Remplace le mapping linéaire prévu initialement — chaque pas de luminosité multiplie `r` par le même facteur sur toute la plage de tons.
- **Paramètre `density`** : remplace `r_min` en entrée GUI (`r_min = 1 / density`), plus intuitif.
- **Paramètre `contrast`** : ratio `r_max / r_min`, remplace un `r_max` absolu.
- **Paramètres `min_value` / `max_value`** : clamp de la plage tonale avant normalisation — permettent de cibler une sous-plage de l'histogramme.
- **Paramètre `invert`** : inverse `t_norm` pour que les zones claires soient denses.
- **Suppression de `DotsFilter`** : le filtre de post-traitement et `DataFilter` sont supprimés — inutiles avec la génération directe.
- **`DotsRenderer`** : extraction du rendu dans une classe dédiée, séparé du générateur. Supporte le mode `Point` et le mode `Polygon` (polygone régulier centré sur chaque point).
- **`DataShape`** : nouveaux paramètres `mode`, `sides`, `size` pour le rendu, avec onglet GUI dédié.
- **Grille spatiale adaptée** : cellule = `r_min / √2`, rayon d'inspection = `ceil(r_max / cell) + 1` pour couvrir tous les voisins même quand `r_max >> r_min`.

### 2026-05-04 — branche `main`
- **Génération progressive** (`resume()`) : la génération Poisson s'effectue en tranches de 500 ms pour ne pas bloquer l'interface.
- **`DataShape` + `DotsRenderer`** (v1) : premier ajout du rendu en polygones réguliers.
- **Commentaires** : documentation de `DotsGenerator` et `DotsFilter`.

### 2026-05-02 — branche `main`
- **Premiers fichiers** : setup Processing, centrage de l'image, export PDF/SVG/DXF.
- **Grille de points** : première implémentation du Poisson Disk Sampling uniforme avec grille spatiale.
- **Densité uniforme** : paramètre `density` basique.
- **Seed** : paramètre `seed` pour la reproductibilité.
- **Filtre binaire** (`DotsFilter`) : premier filtre de post-traitement — suppression des points au-dessus d'un seuil de luminosité.

# image_dots — branche `variable-density-poisson`

## Direction B : Poisson Disk Sampling à densité variable

### Problème de l'approche de base

La version `main` génère une distribution blue noise **uniforme**, puis supprime des points
aléatoirement selon la luminosité de l'image. Cette destruction aléatoire casse la propriété
blue noise : des clusters et des trous apparaissent là où l'image dicte un retrait massif de points.

La Direction A (branche `filter-spatial-awareness`) corrige partiellement le problème en post-traitement,
mais ne peut pas garantir une distribution blue noise stricte car elle dépend de l'ordre de traitement.

---

### Principe de la Direction B

On ne génère **plus** une grille uniforme qu'on filtre ensuite.  
On génère **directement** la distribution finale en faisant varier `r` (la distance minimale entre deux points)
en fonction de la valeur du pixel au point candidat :

```
zone sombre  → r petit  → points rapprochés  → haute densité
zone claire  → r grand  → points espacés     → faible densité
```

À chaque tentative de placement d'un candidat, on lit le pixel de l'image sous ce candidat,
on calcule un `r_local` adapté, et on valide la distance par rapport aux voisins avec **ce r local**.

La propriété blue noise est maintenue à toutes les échelles : pas de clusters, pas de trous —
la distribution reste perceptuellement uniforme à la densité locale dictée par l'image.

---

### Formule de r_local

```
r_local = r_max - (r_max - r_min) × prob_image
```

- `prob_image` ∈ [0, 1] : intensité du pixel normalisée après pipeline (clamp, normalisation, gamma, mode noir/blanc)
- `prob_image = 1` (zone très sombre en mode black) → `r_local = r_min` → points très rapprochés
- `prob_image = 0` (zone très claire en mode black) → `r_local = r_max` → points très espacés

---

### Grille spatiale

La grille doit être construite avec `r_min / √2` comme taille de cellule
(le plus petit r possible), afin de garantir qu'aucune cellule ne contient plus d'un point.
C'est plus coûteux en mémoire que la version uniforme si `r_min` est petit,
mais le coût de vérification reste O(1) par candidat.

La vérification de voisinage utilise un rayon variable :
on valide `dist(candidat, voisin) >= r_local` (le r du candidat).  
Alternativement, on peut utiliser `max(r_candidat, r_voisin)` pour une symétrie stricte.
On choisit `r_local` pour la simplicité et la cohérence avec Bridson.

---

### Conséquence sur le DotsFilter

Avec cette approche, le `DotsFilter` n'est **plus nécessaire** pour la qualité de distribution.
Il reste disponible comme outil optionnel pour :
- masquer des zones (retrait par seuil dur)
- ajuster globalement la densité (threshold)

---

### Paramètres

| Paramètre | Rôle |
|-----------|------|
| `r_min` | Distance minimale dans les zones les plus sombres — contrôle la densité maximale |
| `r_max` | Distance minimale dans les zones les plus claires — contrôle la densité minimale |
| `maxCandidates` | Tentatives par point actif (inchangé) |
| `seed` | Graine aléatoire (inchangé) |
| `gamma` | Courbe de contraste appliquée à la valeur pixel avant calcul de r_local |
| `black` | Zones sombres = dense (true) ou zones claires = dense (false) |

Les paramètres `gamma`, `black`, `min_value`, `max_value` sont partagés avec le `DotsFilter` existant
ou migrés dans `DataDots` selon l'implémentation finale.

---

### Génération progressive

La génération reste progressive (tranches de 500 ms via `start()` + `resume()`).
La seule différence : `start()` doit recevoir l'image en plus de `DataDots`
pour pouvoir lire les pixels pendant la génération.

---

### Limite connue

Si `r_max` est très grand, les zones claires peuvent avoir très peu de points et des zones
quasi-vides visuellement — c'est l'effet voulu (représentation fidèle), mais il faut choisir
`r_max` en cohérence avec `r_min` pour éviter des contrastes trop brutaux.
Un ratio `r_max / r_min` de 3 à 8 est un bon point de départ.

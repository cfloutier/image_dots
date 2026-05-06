# image_dots

Générateur de stippling (pointillisme) piloté par une image source.  
Exporte en PDF / SVG pour traceur ou impression.

---

## Principe général

1. **Génération blue noise** (`DotsGenerator`) — Poisson Disk Sampling (Bridson 2007)  
   Remplit la surface d'une grille de points uniformément espacés d'au moins `minDist` pixels.  
   La distribution est *perceptuellement uniforme* : pas de clusters, pas de trous.

2. **Filtrage par l'image** (`DotsFilter`)  
   Chaque point est conservé ou supprimé selon la luminosité du pixel correspondant dans l'image source.  
   Un pipeline par point : clamp → normalisation → gamma → probabilité → tirage aléatoire.

3. **Rendu** (`DataShape`)  
   Chaque point survivant est dessiné en mode *point* (pixel) ou *polygone* régulier (cercle approximé à n côtés).

---

## Branches

### `main` — version de base

Filtrage purement statistique : chaque point est tiré indépendamment selon sa probabilité.  
**Limite connue** : le tirage aléatoire sans regard pour les voisins peut créer des clusters (zones trop sombres) et des trous (zones trop claires), dégradant localement la qualité blue noise.

---

### `filter-spatial-awareness` — Direction A : filtrage spatialement conscient

**Problème adressé** : le filtrage aléatoire détruit la distribution uniforme du blue noise.  
Deux points très proches peuvent être gardés tous les deux (cluster) ou supprimés tous les deux (trou).

**Approche** : pendant le filtrage, on maintient une grille spatiale des points *déjà acceptés*.  
Avant d'accepter un nouveau point, on compte ses voisins déjà retenus dans un rayon `influence_radius`.  
Plus il y a de voisins, plus la probabilité d'acceptation est réduite :

```
prob_finale = prob_image × (1 - neighbor_count / max_neighbors)
```

- 0 voisin → prob inchangée (comportement identique à `main`)
- `max_neighbors` voisins ou plus → prob = 0 (zone saturée, point rejeté)

**Option shuffle** : avant d'itérer, les points sources sont mélangés aléatoirement (`Collections.shuffle`).  
Sans shuffle, l'ordre de parcours (ligne par ligne) biaise les zones du haut, qui sont traitées avant les autres et ont donc moins de voisins à ce moment-là. Le shuffle supprime ce biais directionnel.  
Disponible comme toggle dans l'onglet *Dots* de l'interface.

**Paramètres ajoutés** dans l'onglet *Filter* :
- `influence_radius` — rayon de regard en pixels (suggéré : 1.5× à 2× `minDist`)
- `max_neighbors` — nombre de voisins au-delà duquel la probabilité tombe à 0 (suggéré : 2 à 4)

**Limite** : la correction reste partielle car l'ordre de traitement influence encore le résultat (atténué par le shuffle). Ne garantit pas une distribution blue noise stricte, améliore la perception visuelle.

---

### `variable-density-poisson` *(à venir)* — Direction B : Poisson Disk à densité variable

**Approche** : faire varier `r` (distance minimale) directement pendant la génération, en fonction de la valeur du pixel. Zones sombres → `r` petit → haute densité. Zones claires → `r` grand → faible densité.  
Plus besoin de filtrage : la distribution respecte l'image *et* conserve la propriété blue noise à toutes les échelles.

---

## Paramètres principaux

| Onglet | Paramètre | Rôle |
|--------|-----------|------|
| Dots | `minDist` | Distance minimale entre points (px) |
| Dots | `maxCandidates` | Tentatives par point actif — plus élevé = grille plus dense, plus lent |
| Dots | `seed` | Graine aléatoire — reproductibilité |
| Dots | `shuffle` | Mélange les points avant filtrage (réduit le biais d'ordre) |
| Filter | `threshold` | Densité globale [0–255] |
| Filter | `gamma` | Courbe de contraste (< 1 : favorise clairs, > 1 : favorise sombres) |
| Filter | `min_value` / `max_value` | Plage de tonalités prise en compte |
| Filter | `black` | Zones sombres = dense (true) ou zones claires = dense (false) |
| Shape | `mode` | Point ou polygone régulier |
| Shape | `sides` | Nombre de côtés du polygone (3–12) |
| Shape | `size` | Taille du polygone en pixels |

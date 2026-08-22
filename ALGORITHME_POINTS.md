# Comment le programme pose les points

## Le principe.

on part d'un premier point au centre, puis fait "germer" de nouveaux points
autour de chaque point déjà posé, un peu comme une plante qui pousse ou une 
colonie de bactéries des branches dans toutes les directions — jusqu'à ce 
que la page soit pleine.

Là où l'image est sombre, les points ont le droit de se serrer davantage ;
là où elle est claire, ils doivent rester éloignés (ou n'apparaissent pas du
tout). C'est cette règle de distance qui, au final, fait apparaître le dessin.

## Étape par étape

1. **Un premier point au centre.**
   Ce point est ajouté à une liste de points "actifs" — des points qui ont
   encore le droit de faire naître des voisins.

2. **On choisit un point actif au hasard** dans cette liste, et on essaie de
   lui trouver un voisin.

3. **On tire un voisin candidat à une distance aléatoire**, dans une
   direction aléatoire elle aussi (un angle au hasard sur 360°). La distance
   n'est pas totalement libre : elle est tirée dans une fourchette qui dépend
   de la densité voulue localement (voir plus bas).

4. **On vérifie que ce candidat est valide :**
   - Il doit rester dans les limites de la page.
   - Le pixel de l'image à cet endroit ne doit pas être trop clair (sinon,
     rejet immédiat — c'est le seuil "threshold").
   - Il doit être assez loin de *tous* les points déjà posés autour de lui.
     La distance minimale exigée dépend elle-même de la clarté du pixel à cet
     endroit : sombre → les points peuvent être proches ; clair → il faut
     plus d'espace.

5. **Si le candidat est valide**, il devient un nouveau point posé, et il
   rejoint à son tour la liste des points actifs (il pourra faire naître ses
   propres voisins plus tard).

6. **Le programme retente plusieurs fois** (7 essais) avant d'abandonner un
   point actif. Si aucun des 7 candidats ne convient, ce point est retiré de
   la liste des actifs : il a fini de germer, on ne cherchera plus de voisins
   autour de lui.

7. **On recommence** en piochant un autre point actif au hasard, encore et
   encore, jusqu'à ce qu'il n'y ait plus aucun point actif. À ce moment-là,
   toute la page a été explorée et remplie du mieux possible : c'est terminé.

## Cas particulier : le premier point échappe à la règle

Le tout premier point, celui posé au centre à l'étape 1, ne passe **pas** par
la vérification de l'étape 4 : il est posé sans regarder ce que dit l'image à
cet endroit. Même si le centre de l'image est clair au point de ne
normalement autoriser aucun point (trop clair, ou au-delà du seuil
"threshold"), ce point central sera quand même dessiné.

Il rejoint quand même la liste des points actifs et essaie de faire naître
des voisins normalement, avec la vraie règle cette fois. Si la zone autour du
centre est trop claire pour permettre le moindre voisin valide, ses 7 essais
échouent tous, il est retiré de la liste des actifs, et il reste seul : on se
retrouve avec un point isolé au centre de l'image, même dans une zone qui
aurait dû rester complètement vide.

## Pourquoi la densité varie selon l'image

Chaque fois qu'on teste un candidat, le programme regarde la valeur du pixel
de l'image à cet endroit précis (clair ou sombre) et calcule une distance
minimale "sur mesure" :

- **Densité** : le réglage de base — plus il est élevé, plus les points
  peuvent être serrés dans les zones sombres.
- **Contraste** : l'écart entre l'espacement dans les zones sombres et
  l'espacement dans les zones claires. Un contraste élevé accentue la
  différence entre zones denses et zones vides.
- **Gamma** : la façon dont la transition se fait entre sombre et clair —
  plutôt progressive ou plutôt brusque dans les demi-teintes.
- **Min value / Max value** : les bornes en dessous / au-dessus desquelles un
  pixel est considéré comme totalement noir / totalement blanc.
- **Threshold (seuil dur)** : au-delà de cette clarté, aucun point n'est
  posé du tout — la zone reste blanche.
- **Invert** : inverse la règle, pour rendre les zones claires denses plutôt
  que les zones sombres.

## Un détail malin (mais pas indispensable à comprendre) : la grille

Pour éviter de comparer chaque nouveau candidat à *tous* les points déjà
posés (ce qui deviendrait très lent quand il y en a des milliers), le
programme range les points dans un quadrillage invisible. Quand il teste un
candidat, il ne regarde que les points rangés dans les cases voisines. C'est
une astuce de rapidité, elle ne change rien au résultat visuel.

## La graine ("seed")

Le hasard utilisé pour choisir les distances et les angles est en réalité
généré à partir d'un nombre de départ, la "seed". Avec la même image et la
même seed, on obtient exactement le même nuage de points à chaque fois — ce
qui permet de reproduire ou de comparer des résultats. Changer la seed donne
une nouvelle disposition, tout en gardant le même rendu global (la même
image reconnaissable, juste "semée" différemment).

// ============================================================
// DotsGenerator — Poisson Disk Sampling (algorithme de Bridson, 2007)
//
// PRINCIPE GÉNÉRAL :
//   On veut placer des points aléatoires tels qu'aucun point n'est
//   plus proche d'un autre que la distance minimale _r (minDist).
//   C'est ce qu'on appelle le "blue noise" : une distribution
//   visuellement uniforme, sans agglomérats ni zones vides.
//
// ALGORITHME EN 3 ÉTAPES :
//   1. Placer un premier point aléatoire, l'ajouter à la liste "active"
//   2. Tant qu'il reste des points actifs :
//      a. Prendre un point actif au hasard
//      b. Essayer jusqu'à maxCandidates positions dans l'anneau [r, 2r]
//      c. Si un candidat est valide (distance > r de tous ses voisins),
//         l'accepter et l'ajouter aux actifs
//      d. Si aucun candidat n'est valide, retirer ce point des actifs
//   3. Quand la liste active est vide → grille entièrement remplie
//
// OPTIMISATION CLÉ — LA GRILLE SPATIALE :
//   Vérifier la distance à TOUS les points existants serait O(n²).
//   On divise l'espace en cellules de taille r/√2 : dans une telle
//   cellule, il ne peut tenir qu'un seul point (car sa diagonale = r).
//   Pour valider un candidat, on ne regarde que les cellules dans un
//   voisinage 5×5 autour de lui → O(1) par test.
//
// GÉNÉRATION PROGRESSIVE :
//   Pour ne pas bloquer l'interface, on découpe le travail en tranches
//   de MAX_MILLIS ms via start() + resume() appelé à chaque frame.
// ============================================================

class DotsGenerator
{
  // Liste finale de tous les points acceptés (coordonnées centrées sur l'origine)
  ArrayList<PVector> points = new ArrayList<PVector>();

  // Vrai dès que la liste active est vide (génération terminée)
  boolean isComplete = true;

  // Durée du dernier appel à resume() en millisecondes (affiché dans le HUD)
  int lastResumeMillis = 0;

  // Ratio d'avancement [0..1] estimé à partir du nb de points vs maximum théorique
  float progressRatio = 0;

  // Nombre maximum de points estimé pour calculer la progression
  // (utilisé seulement comme dénominateur de progressRatio)
  private int _estimatedMax = 1;

  // Liste des points "actifs" : ceux depuis lesquels on tente encore de générer des voisins.
  // Un point reste actif tant qu'un candidat valide peut en être issu.
  // Il est retiré dès que tous ses maxCandidates tentatives ont échoué.
  private ArrayList<PVector> _active;

  // Grille spatiale plate (tableau 1D, indexé par gx + gy * _cols).
  // Chaque cellule contient l'index du point qui l'occupe, ou -1 si vide.
  private int[] _grid;

  // Nombre de colonnes de la grille (largeur / taille de cellule)
  private int _cols;

  // Taille d'une cellule = r / √2
  // Choisie pour qu'une cellule ne contienne jamais plus d'un point :
  // la diagonale d'une cellule carrée de côté (r/√2) vaut exactement r.
  private float _cell;

  // Décalage origine : les points sont en coordonnées centrées (-w/2..w/2),
  // mais la grille est indexée en positif (0..cols). _ox/_oy convertissent.
  private float _ox, _oy;

  // Dimensions de la zone de génération (égales aux dimensions de l'image)
  private float _w, _h;

  // Distance minimale entre deux points (= minDist du paramètre)
  private float _r;

  // Nombre de candidats tentés par point actif avant de l'abandonner.
  // Plus ce nombre est élevé, plus la grille est dense mais plus c'est lent.
  private int _maxCandidates;

  // Budget temps maximum par appel à resume() avant de rendre la main à draw()
  static final int MAX_MILLIS = 500;

  // -------------------------------------------------------
  // start() : initialise l'état et place le premier point
  // Appelé quand l'image ou les paramètres changent.
  // -------------------------------------------------------
  void start(DataDots data, float w, float h)
  {
    // Réinitialise la liste des points acceptés
    points.clear();

    // Marque la génération comme en cours
    isComplete = false;

    lastResumeMillis = 0;
    progressRatio    = 0;

    // Estimation du nombre maximum de points :
    // Nombre de cellules de grille × 0.7 (taux de remplissage empirique du Poisson Disk).
    // ceil(w / cell) × ceil(h / cell) = nombre total de cellules.
    // Cette valeur sert uniquement à estimer la progression, pas à arrêter l'algo.
    _estimatedMax = max(1, (int)(0.7 * ceil(w / (data.minDist / sqrt(2))) * ceil(h / (data.minDist / sqrt(2)))));
    println("DotsGenerator estimated max points: " + _estimatedMax);

    println("DotsGenerator.start() minDist=" + data.minDist + " maxCandidates=" + data.maxCandidates + " seed=" + data.seed);

    // Fixe la graine aléatoire pour que le résultat soit reproductible
    randomSeed(data.seed);

    _r             = data.minDist;
    _maxCandidates = data.maxCandidates;

    // Taille de cellule = r/√2 : garantit qu'une cellule ≤ 1 point
    _cell = _r / sqrt(2);

    _w = w;
    _h = h;

    // Décalage pour passer des coordonnées centrées aux indices de grille
    _ox = w / 2;
    _oy = h / 2;

    // Dimensions de la grille en nombre de cellules
    _cols    = ceil(w / _cell);
    int rows = ceil(h / _cell);

    // Crée la grille et initialise toutes les cellules à "vide" (-1)
    _grid = new int[_cols * rows];
    java.util.Arrays.fill(_grid, -1);

    // Initialise la liste des points actifs (vide au départ)
    _active = new ArrayList<PVector>();

    // Place le premier point aléatoirement dans la zone, l'enregistre et l'active
    PVector first = new PVector(random(-w/2, w/2), random(-h/2, h/2));
    _addPoint(first);   // → enregistre dans points[] et dans _grid
    _active.add(first); // → candidat de départ pour générer ses voisins
  }

  // -------------------------------------------------------
  // resume() : exécute l'algorithme pendant au plus MAX_MILLIS ms,
  // puis rend la main. Retourne true si la génération est terminée.
  // -------------------------------------------------------
  boolean resume()
  {
    // Déjà terminé : rien à faire
    if (isComplete) return true;

    // Mémorise l'heure de début pour calculer lastResumeMillis et respecter le budget
    long t0       = System.currentTimeMillis();
    long deadline = t0 + MAX_MILLIS; // heure limite avant de rendre la main

    // Boucle principale : tant qu'il reste des points actifs
    while (_active.size() > 0)
    {
      // Si on a dépassé le budget temps → suspendre et revenir au prochain frame
      if (System.currentTimeMillis() >= deadline)
      {
        lastResumeMillis = (int)(System.currentTimeMillis() - t0);
        // Progression = nb de points acceptés / estimation du maximum théorique
        progressRatio = min(1.0, (float)points.size() / _estimatedMax);
        return false; // pas encore terminé
      }

      // Choisit un point actif au hasard (évite les biais directionnels)
      int idx   = (int)random(_active.size());
      PVector p = _active.get(idx);

      // Indique si au moins un candidat valide a été trouvé depuis ce point actif
      boolean found = false;

      // Tente maxCandidates fois de placer un nouveau point dans l'anneau [r, 2r] autour de p
      for (int n = 0; n < _maxCandidates; n++)
      {
        // Direction aléatoire uniforme sur le cercle
        float angle = random(TWO_PI);

        // Distance aléatoire dans l'anneau [r, 2r] :
        // - trop proche (< r) : violerait la contrainte de distance minimale
        // - trop loin  (> 2r) : laisserait des "trous" impossibles à remplir depuis p
        float d = random(_r, 2 * _r);

        // Position du candidat en coordonnées centrées
        PVector candidate = new PVector(p.x + cos(angle) * d,
                                        p.y + sin(angle) * d);

        // Rejette les candidats hors de la zone de génération
        if (candidate.x < -_w/2 || candidate.x > _w/2 ||
            candidate.y < -_h/2 || candidate.y > _h/2) continue;

        // Convertit la position du candidat en indice de cellule de grille
        int cgx = (int)((candidate.x + _ox) / _cell);
        int cgy = (int)((candidate.y + _oy) / _cell);

        // Vérifie que le candidat est bien à distance ≥ r de tous ses voisins proches.
        // On inspecte un voisinage 5×5 centré sur la cellule du candidat.
        // Pourquoi 5×5 ? Un cercle de rayon r peut toucher au maximum 2 cellules
        // de chaque côté (r / cell = r / (r/√2) = √2 ≈ 1.41 → arrondi à 2).
        boolean ok = true;
        for (int dy = -2; dy <= 2 && ok; dy++) {
          for (int dx = -2; dx <= 2 && ok; dx++) {
            int nx = cgx + dx; // colonne de la cellule voisine
            int ny = cgy + dy; // ligne   de la cellule voisine

            // Ignore les cellules hors des limites de la grille
            if (nx < 0 || nx >= _cols || ny < 0 || ny >= (_grid.length / _cols)) continue;

            // Récupère l'index du point dans cette cellule voisine (-1 = vide)
            int pidx = _grid[nx + ny * _cols];
            if (pidx == -1) continue; // cellule vide : pas de conflit

            // Récupère le point voisin et mesure la distance euclidienne
            PVector neighbor = points.get(pidx);
            if (dist(candidate.x, candidate.y, neighbor.x, neighbor.y) < _r) {
              ok = false; // trop proche : candidat invalide
            }
          }
        }

        if (ok) {
          // Candidat valide : on l'accepte
          _addPoint(candidate);  // enregistre dans points[] et _grid
          _active.add(candidate); // devient lui-même un point actif
          found = true;
          break; // on passe au prochain point actif
        }
      }

      // Aucun candidat valide trouvé en maxCandidates tentatives :
      // ce point actif est "saturé", on le retire de la liste.
      // Les points qui l'entourent sont trop proches pour qu'un nouveau voisin s'y insère.
      if (!found)
        _active.remove(idx);
    }

    // La liste active est vide → toute la zone est couverte, génération terminée
    isComplete       = true;
    lastResumeMillis = (int)(System.currentTimeMillis() - t0);
    progressRatio    = 1.0;
    println("DotsGenerator: " + points.size() + " points generated");
    return true;
  }

  // Affichage debug : dessine tous les points générés (avant filtrage image)
  void draw()
  {
    for (PVector p : points) {
      current_graphics.point(p.x, p.y);
    }
  }

  // -------------------------------------------------------
  // _addPoint() : enregistre un point dans la liste ET dans la grille spatiale
  // -------------------------------------------------------
  private void _addPoint(PVector p)
  {
    // Ajoute le point à la liste finale
    points.add(p);

    // Calcule la cellule correspondante en coordonnées de grille (positives)
    int gx = (int)((p.x + _ox) / _cell);
    int gy = (int)((p.y + _oy) / _cell);

    // Stocke l'index du point dans la cellule (pour la recherche de voisins en O(1))
    _grid[gx + gy * _cols] = points.size() - 1;
  }
}

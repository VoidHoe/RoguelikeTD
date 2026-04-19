# Framework d'Équilibrage Tower Defense - V2 (Système Mathématique)

Ce document définit les règles de calcul pour le design des héros, la progression et la résolution des combats.

---

## Conversion Pixels / Mètres

**1 mètre = 50 pixels** *(mis à jour Step 8 — tile 64×32px, échelle ÷2)*

La tile isométrique fait 64×32px. La distance minimale entre un héro posé
adjacent au chemin et un ennemi sur le chemin est ~72px (≈1.44m).
Toute portée inférieure à **75px** rend le héro inutilisable.

---

## 1. La Formule de Dégâts Finale

$$D_{final} = (D_{base} \times M_{type}) \times (1 - R_{armor})$$

### Variables :
* **D_base** : Dégâts bruts du héros par attaque.
* **M_type** : Multiplicateur de type (voir Matrice des Types).
    * Faiblesse : 1.5
    * Neutre : 1.0
    * Résistance : 0.75
* **R_armor** : Réduction de dégâts liée à l'armure (ex: 0.20 pour 20% de réduction).
    * Note : Le Feu ignore l'armure.

---

## 2. Le Budget de Puissance (Power Budget)

**Formule de Budget :** `Points = 100 + (Lvl - 1) × 15`

### Coût des Statistiques :
| Statistique      | Unité     | Coût en Points |
| :---             | :---      | :---           |
| **Dégâts**       | 1 Dégât   | 5 pts          |
| **Portée**       | 1 Mètre   | 8 pts          |
| **Vitesse Atk**  | +1%       | 2 pts          |
| **Zone (AoE)**   | +1m Rayon | 20 pts         |
| **Ralentissement** | +10%    | 15 pts         |

---

## 3. Héros Niveau 1 — Valeurs Actuelles (Godot)

> ℹ️ **Tile ÷2 (Step 8)** — TILE_SIZE est passé à 64×32px (scale=1.0). Toutes les portées
> ont été divisées par 2 pour conserver le même ressenti en tuiles. La règle minimale
> est maintenant **portée > 75px**. Vitesse ennemis conseillée : 40px/s (= 0.625 tuile/s).
> Ajuste `attack_radius` dans l'Inspecteur de chaque scène héros si besoin.

| Héros        | Type       | Dégâts | Portée px  | Portée m | Vitesse | Budget Total |
| :---         | :---       | :---   | :---       | :---     | :---    | :---         |
| Bladedancer  | Tranchant  | 8      | **90px**   | 1.8m     | 1.2     | 40+14+40 = **94 pts** |
| Pyromancer   | Feu        | 15     | **110px**  | 2.2m     | 1.0     | 75+18+0  = **93 pts** |
| Stormshard   | Électrique | 12     | **100px**  | 2.0m     | 1.1     | 60+16+20 = **96 pts** |

### Détail du Calcul par Héros

**Bladedancer** — Corps-à-corps rapide, courte portée
- Dégâts : 8 × 5 = 40 pts
- Portée : 1.8m × 8 = 14 pts
- Vitesse : +20% × 2 = 40 pts
- **Total : 94 / 100 pts**

**Pyromancer** — Attaquant longue portée, ignore l'armure
- Dégâts : 15 × 5 = 75 pts
- Portée : 2.2m × 8 = 18 pts
- Vitesse : base (1.0) = 0 pts
- **Total : 93 / 100 pts**

**Stormshard** — Mi-portée polyvalent
- Dégâts : 12 × 5 = 60 pts
- Portée : 2.0m × 8 = 16 pts
- Vitesse : +10% × 2 = 20 pts
- **Total : 96 / 100 pts**

---

## 4. Optimisation des Compétences Spéciales

1. **Enchaînement (Chain) :**
    - Coût = 20 pts + (5 pts × nombre de rebonds).
    - Réduction de dégâts par rebond conseillée : -25%.
2. **Transpercement (Pierce) :**
    - Coût fixe = 30 pts.
3. **Dégâts sur le Temps (DoT) :**
    - Bonus budget : -10% sur le coût des dégâts (dégâts non instantanés).

---

## 5. Matrice de Référence des Ennemis

| Ennemi      | Armure | Faiblesse (×1.5) | Résistance (×0.75)  |
| :---        | :---   | :---              | :---                |
| **Orc**     | 0.15   | Feu, Magie        | Perçant, Tranchant  |
| **Squelette** | 0.0  | Magie, Feu        | Perçant, Tranchant  |
| **Vampire** | 0.0    | Feu, Perçant      | Magie               |
| **Golem**   | 0.40   | Magie, Électrique | Tranchant, Perçant  |
| **Démon**   | 0.10   | Magie, Électrique | Feu                 |

---

## 6. Économie

### Système de Draft (Step 7 implémenté)

**Au démarrage de la run :**
- Le joueur voit 3 cartes héros (1 parmi les 3 disponibles, aléatoire).
- Il en choisit 1 **gratuitement** → placement immédiat.
- Après placement du premier héros, le bouton "Lancer la vague" apparaît.

**Après chaque vague (entre les vagues) :**
- 3 cartes s'affichent : jusqu'à 1 déverrouillage de héros + 2 reliques (mélangées).
- Choisir une carte est **toujours gratuit**.
  - **Déverrouillage héros** : le héros rejoint la boutique (achat avec Or requis ensuite).
  - **Relique** : effet passif activé immédiatement (affichage dans le HUD).

**Boutique en cours de run :**
- Accessible via le bouton "Boutique" (visible si ≥ 1 héros déverrouillé).
- Acheter un héros coûte son prix en Or, le retire de la boutique.
- Après achat → mode placement → cliquer un slot vide → héros posé.

### Or de départ
80 or → permet de poser 1 héros depuis la boutique après le draft initial.

### Coût des Héros
| Héros        | Coût  | Justification                        |
| :---         | :---  | :---                                 |
| Bladedancer  | 50 or | Corps-à-corps, budget 94 pts         |
| Stormshard   | 55 or | Mi-portée, budget 96 pts             |
| Pyromancer   | 65 or | Longue portée + ignore armure        |

### Récompenses Ennemis
| Ennemi             | Or  | HP  |
| :---               | :-- | :-- |
| Skeleton Warrior   | 10  | 60  |
| Skeleton Rogue     | 8   | 40  |
| Skeleton Knight    | 25  | 180 |
| Skeleton Bonelord  | 80  | 500 |

### Or par Vague (si tout tué)
| Vague | Composition                    | Or  |
| :---  | :---                           | :-- |
| 1     | 5 warriors                     | 50  |
| 2     | 3 warriors + 3 rogues          | 54  |
| 3     | 4 rogues + 1 knight            | 57  |
| 4     | 3 warriors + 2 knights         | 80  |
| 5     | 3 knights + 1 bonelord         | 155 |
| **Total** |                            | **396** |

Or total max (80 départ + 396) = **476 or**
Board complet (2× chaque héros × 6 slots) = **340 or**
→ Le joueur peut remplir le board s'il joue bien.

---

## 7. Guide de Level Up

À chaque niveau (+15 points) :
* **Héros DPS Pur :** 10 pts en Dégâts, 5 pts en Vitesse.
* **Héros Utilitaire :** 10 pts en Portée/Effet, 5 pts en Dégâts.

# UI Art Direction — Roguelike TD

## Vision globale

Interface **dark fantasy brutaliste** : pierre gravée, métal forgé, runes qui luisent faiblement.
Aucune couleur vive. Tout est usé, sombre, légèrement menaçant.
L'UI doit sentir le donjon, pas le menu mobile.

---

## Palette UI

| Rôle | Couleur | Hex |
|---|---|---|
| Fond de panneau | Pierre noire | `#12141a` |
| Fond de carte / slot | Bleu-gris sombre | `#1e2130` |
| Bordure principale | Bleu-gris | `#3a3d45` |
| Bordure accent | Or terne | `#c8973a` |
| Texte principal | Blanc cassé | `#d8d4c8` |
| Texte secondaire | Gris pierre | `#7a7870` |
| Texte désactivé | Gris foncé | `#3a3840` |
| Surbrillance / hover | Or doux | `#e8b84a` |
| Danger / HP bas | Rouge brique | `#8a2010` |

### Couleurs par type de dégâts

| Type | Couleur | Hex |
|---|---|---|
| Magic | Violet | `#7040a0` |
| Electric | Jaune électrique | `#c0b020` |
| Fire | Orange braise | `#c86030` |
| Slashing | Bleu acier | `#4060a0` |
| Crushing | Brun-rouge | `#703020` |

---

## Typographie

| Usage | Style |
|---|---|
| Titres de panneau | Serif condensé, lettres espacées, tout en caps |
| Corps / descriptions | Sans-serif léger, taille modeste |
| Valeurs numériques | Monospace ou chiffres tabulaires |
| Runes / flavor text | Italique, couleur `#7a7870` |

> Pas de police fantaisie illisible. La lisibilité prime, le style vient de la couleur et des bordures.

---

## Composants UI

### Panneaux & conteneurs

- Fond `#12141a` avec légère texture grain (bruit subtil, opacité 5-8%)
- Bordure double : ligne extérieure `#3a3d45`, ligne intérieure `#1a1c20` (1px chacune)
- Coins : carrés ou légèrement biseautés (pas de border-radius rond)
- Ombre portée vers le bas, couleur `#00000088`

### Boutons

| État | Style |
|---|---|
| Normal | Fond `#1e2130`, bordure `#3a3d45`, texte `#d8d4c8` |
| Hover | Fond `#2a2e40`, bordure `#c8973a`, texte `#e8b84a` |
| Pressed | Fond `#12141a`, bordure `#c8973a` inset, texte `#c8973a` |
| Disabled | Fond `#14161c`, bordure `#2a2c30`, texte `#3a3840` |

Forme : rectangulaire, pas de pill. Hauteur fixe, padding horizontal généreux.

### Cartes héros (draft)

```
┌─────────────────────┐
│  [PORTRAIT 64×64]   │  ← sprite isométrique centré
│  ─────────────────  │  ← séparateur or terne
│  NOM DU HÉROS       │  ← caps, blanc cassé
│  Classe / type      │  ← petit, gris pierre
│                     │
│  ♥ 120  ⚔ 18       │  ← stats icônes + valeurs
│  ───────────────    │
│  [Passif court]     │  ← flavor text italique
└─────────────────────┘
```

Bordure or `#c8973a` sur la carte sélectionnée / au hover.

### Cartes reliques

Même structure que les cartes héros, sans portrait.
Icône 32×32 centrée en haut, fond `#1a1c20`.
Rareté indiquée par la couleur de bordure :

| Rareté | Bordure |
|---|---|
| Commune | `#3a3d45` |
| Rare | `#4060a0` |
| Épique | `#7040a0` |
| Légendaire | `#c8973a` (glow subtil) |

### Barre de vie (base & héros)

- Fond : `#1a1c20`
- Remplissage : dégradé `#6a1010` → `#c83020` (sombre à gauche, vif à droite)
- Passage en danger (<25%) : pulsation lente, couleur `#8a2010`
- Bordure : `#3a3d45`
- Pas d'animation de rebond. Transition linéaire 0.2s.

### Indicateurs de résistance

Icône du type de dégâts + état :

| État | Visuel |
|---|---|
| Inconnu | Icône grisée `#3a3840`, `?` |
| Résistant | Icône couleur type, flèche ↓ |
| Normal | Icône couleur type |
| Faible | Icône couleur type, flèche ↑, léger glow |

### Aperçu de vague (wave preview)

Liste horizontale d'icônes ennemis avec compteur.
Fond bandeau `#12141a`, séparé du jeu par une bordure `#3a3d45`.
Boss wave : bordure du bandeau en `#c86030`, icône boss plus grande.

### Écran de draft (choix upgrade)

3 cartes côte à côte, centrées, sur fond overlay `#00000099`.
Titre en haut : `"CHOISIR UNE AMÉLIORATION"` — caps, espacé, `#c8973a`.
Pas d'animation d'entrée complexe. Fade-in 0.15s suffit.

### Écran d'événement narratif

Panneau centré, largeur ~60% écran.
Portrait événement à gauche (64×96 ou 96×96).
Texte narratif à droite, italique, `#d8d4c8`.
Choix : 2-3 boutons empilés en bas du panneau.

---

## Iconographie

- Style : pixel art, 16×16 ou 32×32
- Outline : 1px noir `#1a1c20`
- Pas de dégradé dans les icônes — aplats + ombre portée manuelle
- Les icônes de type de dégâts utilisent la couleur définie dans la palette types

---

## Effets & feedback visuel

| Action | Feedback |
|---|---|
| Héros attaque | Flash blanc 1 frame sur le sprite |
| Ennemi touché | Flash couleur du type de dégâts, 2 frames |
| Ennemi meurt | Dissolve pixel par pixel, 0.3s |
| Upgrade choisi | Carte sélectionnée pulse or, les autres fade-out |
| Base touchée | Vignette rouge bords d'écran, 0.5s |
| Nouveau round | Bandeau "VAGUE X" slide depuis le haut, 0.4s |

---

## Ce qu'on évite absolument

- Blanc pur `#ffffff` ou noir pur `#000000`
- Border-radius > 3px
- Animations de bounce, elastic, spring
- Couleurs saturées ou néon (sauf Electric en contexte de dégât)
- Ombres portées colorées
- Panneaux translucides floutés (glassmorphism)
- Polices decoratives illisibles

# UI Plan — Roguelike TD

> Agent UI · v1 · 2026-04-19
> Basé sur : UI_ART_DIRECTION.md + analyse codebase + recherche (Slay the Spire, Hades, Into the Breach, Monster Train, Kingdom Rush)

---

## 1. Inventaire des écrans

| Écran | Statut actuel | Priorité |
|---|---|---|
| **HUD de jeu** (in-run) | Partiel (labels bruts) | P0 |
| **DraftScreen** (choix upgrade) | Fonctionnel, pas stylisé | P0 |
| **ShopPanel** | Fonctionnel, pas stylisé | P0 |
| **WavePreview** | Label seul | P0 |
| **RunEndScreen** (victoire/défaite) | Absent | P1 |
| **MainMenu** | Absent | P1 |
| **PauseMenu** | Absent | P1 |
| **EventScreen** (post-boss) | Fonctionnel, pas stylisé | P1 |
| **EnemyInspect** (tooltip ennemi) | Absent | P1 |
| **HeroTooltip** | Absent | P2 |
| **RelicTooltip** | Absent | P2 |
| **DifficultySelect** | Absent | P2 |
| **SettingsMenu** | Absent | P3 |

---

## 2. Composants réutilisables à créer

Ces composants sont la base de tous les écrans. Créer en premier.

### 2.1 `DarkPanel` — conteneur de base
```
Fond : #12141a + noise texture 6% opacité
Bordure double : extérieure #3a3d45 (1px), intérieure #1a1c20 (1px)
Coins biseautés 2px (pas de border-radius rond)
Ombre : offset (0,4), couleur #00000088, blur 8
```
Usage : tous les panneaux, cartes, menus.

### 2.2 `DarkButton` — bouton standard
```
4 états (Normal / Hover / Pressed / Disabled) selon art direction
Hauteur fixe : 36px
Padding horizontal : 20px
Texte : sans-serif, caps, 13px
Pas de pill shape
```

### 2.3 `HeroCard` / `RelicCard`
```
Dimensions : 160×220px
Fond slot : #1e2130
Séparateur or terne : #c8973a, 1px, opacité 60%
Sélection/hover : bordure #c8973a, glow subtil (shader ou modulate)
Rareté (relique) : couleur de bordure selon palette
```

### 2.4 `HPBar`
```
Fond : #1a1c20, bordure #3a3d45
Remplissage : dégradé #6a1010 → #c83020
< 25% : modulate pulse lent (0.8s), teinte #8a2010
Transition : linear 0.2s (Tween)
Pas de rebond
```

### 2.5 `DamageTypeIcon`
```
16×16 pixel art
Outline 1px #1a1c20
Couleur selon palette types (Magic/Electric/Fire/Slashing/Crushing)
États : inconnu (grisé + ?), résistant (↓), normal, faible (↑ + glow)
```

### 2.6 `FloatingLabel` — texte tooltip overlay
```
Fond #12141a90, bordure #3a3d45
Apparaît 0.1s après hover, disparaît immédiatement
Position : suit la souris, évite les bords d'écran
```

### 2.7 `SectionTitle`
```
Texte : serif condensé, caps, letter-spacing 3px
Couleur : #c8973a
Décoration : ligne #3a3d45 sur toute la largeur dessous
```

---

## 3. Spécifications par écran

---

### 3.1 HUD DE JEU (in-run) — P0

**Layout général (1920×1080) :**

```
┌──────────────────────────────────────────────────────────────────────┐
│ [BASE HP]  [GOLD]  [WAVE X/N]          [RELICS ROW]    [BTN WAVE] │  ← top bar 56px
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                     ZONE DE JEU                                      │
│              (isometric map, heroes, enemies)                        │
│                                                                      │
├──────────────────────────────────────────────────────────────────────┤
│  [WAVE PREVIEW BANDEAU]                                              │  ← bottom bar 48px
└──────────────────────────────────────────────────────────────────────┘
```

**Top bar (56px, fond #12141a, bordure bas #3a3d45) :**

- **Gauche :** Base HP `♥ 18 / 20` — icône cœur + valeur, couleur danger si < 25%
- **Gauche+** : Gold `⬡ 120` — icône hexagone or + montant
- **Centre :** `VAGUE 3 / 8` — SectionTitle, centré
- **Droite :** Relic row — icônes 24×24 côte à côte, tooltip au hover
- **Droite+** : Bouton `LANCER LA VAGUE` (DarkButton, désactivé pendant la vague)

**Bottom bar — Wave Preview (48px) :**
- Fond #12141a, bordure top #3a3d45
- Liste horizontale d'icônes ennemis (24×24) + compteur `×12`
- Séparateurs `|` entre groupes d'ennemis différents
- **Boss wave :** bordure top #c86030, icône boss 32×32

**Leçons intégrées :**
- *Into the Breach* : toute l'info visible avant de lancer, pas de surprise
- *Dead Cells* : HUD top ne bloque pas le jeu
- *Kingdom Rush* : info contextuelle, pas de panels flottants permanents

---

### 3.2 DRAFT SCREEN (choix upgrade) — P0

**Layout :**
```
[OVERLAY #00000099 full screen]
┌─────────────────────────────────────────────────────┐
│          CHOISIR UNE AMÉLIORATION                   │  ← SectionTitle, #c8973a
│                                                     │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐        │
│  │ HeroCard │   │ HeroCard │   │RelicCard │        │
│  │  ou      │   │  ou      │   │   ou     │        │
│  │RelicCard │   │RelicCard │   │UpgrCard  │        │
│  └──────────┘   └──────────┘   └──────────┘        │
│                                                     │
│                  [PASSER]                           │  ← petits, grisés
└─────────────────────────────────────────────────────┘
```

**Interactions :**
- Hover : bordure or #c8973a + glow 4px
- Click : carte pulse or 0.15s, les autres fade-out (opacity 0.3)
- Pas de slide/bounce. Fade-in overlay 0.15s.

**Contenu des cartes :**

*HeroCard :*
```
[Portrait 64×64]
─── séparateur ───
NOM DU HÉROS          ← caps, #d8d4c8
Classe                ← #7a7870, petit
♥ 120  ⚔ 18          ← stats
─── séparateur ───
[Passive / description]   ← italique, #7a7870
```

*RelicCard :*
```
[Icône 32×32, centré]
─── séparateur ───
NOM RELIQUE           ← caps
● RARE                ← point couleur rareté + label
─── séparateur ───
[Description]         ← italique
```

*UpgradeCard :*
```
[Icône héros 32×32]
─── séparateur ───
UPGRADE : BLADEDANCER
Dégâts +15%           ← stat modifiée, couleur type
─── séparateur ───
[Effet court]
```

**Leçons intégrées :**
- *Slay the Spire* : 3 choix max, évite la paralysie
- *Vampire Survivors* : pause jeu pendant le choix, feedback immédiat
- *Monster Train* : preview clair de l'effet avant de confirmer

---

### 3.3 SHOP PANEL — P0

**Layout (side panel 280px, droite de l'écran) :**
```
┌────────────────────────────────┐
│  SHOP                          │  ← SectionTitle
│  ─────────────────────────     │
│  ┌─────────┐  Bladedancer      │
│  │ portrait│  Classe : Melee   │
│  │  48×48  │  ⬡ 60             │  ← coût
│  └─────────┘  [ACHETER]        │
│  ─────────────────────────     │
│  ┌─────────┐  Pyromancer       │
│  │ portrait│  (déjà acheté)    │
│  │  48×48  │  ✓                │  ← check icon, grisé
│  └─────────┘  [PLACÉ]          │
└────────────────────────────────┘
```

Apparaît uniquement entre les vagues. Slide-in depuis la droite (0.2s linear).

---

### 3.4 WAVE PREVIEW (bandeau bas) — P0

Voir §3.1 HUD. Composant séparé `WavePreviewBar.tscn`.

Données requises de WaveController :
- Liste de `{scene_path, count}` pour la prochaine vague
- Flag `is_boss`

Icônes ennemis : 24×24 px, même style que DamageTypeIcon.

---

### 3.5 RUN END SCREEN — P1

**Victoire :**
```
┌──────────────────────────────────────────────────┐
│                                                  │
│              VICTOIRE                            │  ← SectionTitle, gold
│                                                  │
│  Vagues survivées : 8/8                          │
│  Ennemis tués    : 147                           │
│  Or restant      : 230                           │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  Reliques obtenues                         │  │
│  │  [icône][icône][icône]                     │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│     [REJOUER]          [MENU PRINCIPAL]          │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Défaite :** Même layout, titre `DÉFAITE`, teinte rouge #8a2010, vignette rouge bords.

---

### 3.6 MAIN MENU — P1

```
[Fond : carte de jeu figée, assombrie 60%]
┌──────────────────────────────────────────────────┐
│                                                  │
│                                                  │
│           ████  ROGUELIKE TD  ████               │  ← titre jeu, large
│                                                  │
│               [NOUVELLE PARTIE]                  │
│               [CONTINUER]                        │  ← grisé si pas de save
│               [PARAMÈTRES]                       │
│               [QUITTER]                          │
│                                                  │
│                              v0.1 · itch.io      │
└──────────────────────────────────────────────────┘
```

Boutons empilés, alignés centre. Pas d'animation complexe.

---

### 3.7 PAUSE MENU — P1

Overlay #00000099. Panel centré 400×300.
Boutons : `REPRENDRE`, `MENU PRINCIPAL`, `QUITTER`.
Touche Escape pour toggle.

---

### 3.8 ENEMY INSPECT (tooltip) — P1

Apparaît au hover sur un ennemi vivant. Panel flottant 200×160.

```
┌───────────────────────────────┐
│ [Sprite 32×32]  SKELETON ROGUE│  ← nom
│                               │
│  ♥ 45 / 80    [HP BAR]        │
│                               │
│  RÉSISTANCES                  │
│  [🔥↓][⚡↑][⚔ ][🔮 ][💀 ]   │  ← DamageTypeIcon × 5
└───────────────────────────────┘
```

Icônes de résistance selon états (inconnu/résistant/normal/faible).
Position : suit curseur, décalage +20px, évite bords.

---

### 3.9 EVENT SCREEN (post-boss) — P1

```
[OVERLAY #00000099]
┌──────────────────────────────────────────────────────┐
│  ┌──────────┐   TITRE ÉVÉNEMENT                      │
│  │ Portrait │                                         │
│  │ 64×96   │   Texte narratif, italique, #d8d4c8     │
│  └──────────┘   (2-4 lignes max)                     │
│                                                      │
│  ─────────────────────────────────────────────────  │
│                                                      │
│              [OPTION A]                              │
│              [OPTION B]                              │
│              [OPTION C]  ← si applicable             │
└──────────────────────────────────────────────────────┘
```

---

## 4. Thème Godot (`dark_fantasy.theme`)

Créer une ressource Theme centralisée qui encode :

| Stylebox | Usage |
|---|---|
| `StyleBoxFlat` panel | DarkPanel (fond + bordure double) |
| `StyleBoxFlat` button_normal | DarkButton normal |
| `StyleBoxFlat` button_hover | DarkButton hover |
| `StyleBoxFlat` button_pressed | DarkButton pressed |
| `StyleBoxFlat` button_disabled | DarkButton disabled |
| `StyleBoxFlat` progress_fill | HPBar fill |
| `StyleBoxFlat` progress_bg | HPBar fond |

Fonts :
- `font_title` : Cinzel ou équivalent libre (serif condensé)
- `font_body` : Roboto Condensed Light ou Noto Sans Light
- `font_mono` : JetBrains Mono (valeurs numériques)

> Godot 4 : utiliser `.tres` pour la ressource Theme, référencée dans Project Settings > Theme.

---

## 5. Ordre d'implémentation

### Phase 1 — Infrastructure (faire en premier)
1. Créer `dark_fantasy.theme` avec StyleBoxes de base
2. Créer `DarkPanel.tscn` + `DarkButton.tscn` comme scenes préfab
3. Créer `HPBar.tscn` (version héros + version ennemi)
4. Créer `DamageTypeIcon.tscn`

### Phase 2 — HUD in-run (cœur du jeu)
5. Refaire le top bar HUD (`GameHUD.tscn`)
6. Créer `WavePreviewBar.tscn`
7. Ajouter `EnemyInspectPanel.tscn` (hover tooltip)

### Phase 3 — Écrans entre les vagues
8. Refaire `DraftScreen.tscn` avec HeroCard / RelicCard
9. Refaire `ShopPanel.tscn`
10. Refaire `EventScreen.tscn`

### Phase 4 — Écrans de navigation
11. `RunEndScreen.tscn` (victoire + défaite)
12. `MainMenu.tscn`
13. `PauseMenu.tscn`

### Phase 5 — Polish
14. Tooltips sur reliques et héros
15. Transitions (fade-in DraftScreen, slide ShopPanel)
16. Feedback visuels (vignette base touchée, bandeau vague)
17. `DifficultySelect.tscn`

---

## 6. Règles d'implémentation Godot

- Utiliser `CanvasLayer` pour tous les overlays (HUD, menus) — jamais dans le world space
- `Control` nodes en mode `ANCHOR_FULL_RECT` pour les panels full-screen
- Tweens pour toutes les animations : `create_tween().set_trans(Tween.TRANS_LINEAR)`
- Pas d'AnimationPlayer pour les micro-transitions UI (< 0.3s)
- Thème appliqué au node racine de chaque scene, pas en inline sur chaque widget
- Tous les textes via `Label` avec le bon font override, pas de RichTextLabel sauf descriptions longues
- `theme_type_variation` pour les variantes (ex : `DangerLabel` hérite de `Label` avec couleur #8a2010)

---

## 7. Ce qu'on ne fera PAS

- Pas d'animations d'entrée complexes (pas de slide multi-axes, spring, bounce)
- Pas de glassmorphism (pas de BackBufferCopy + blur)
- Pas de border-radius > 2px dans les StyleBoxes
- Pas de couleurs saturées sauf Electric en contexte dégât
- Pas de polices décoratives (Cinzel est lisible, c'est acceptable)
- Pas de HUD elements dans le world space (tout en CanvasLayer)

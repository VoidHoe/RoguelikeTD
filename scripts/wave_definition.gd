class_name WaveDefinition
extends Node

## Définit une vague.
## Ajoute des nœuds WaveEntry comme enfants pour définir les ennemis.
## is_boss = true → vague finale du chapitre (déclenche un Event au lieu du Draft).
@export var spawn_interval: float = 1.5
@export var is_boss: bool = false

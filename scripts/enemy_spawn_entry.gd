class_name EnemySpawnEntry
extends Resource

## Données d'un groupe d'ennemis à spawner dans une vague.
## Ajouter dans le tableau "entries" d'un WaveDefinition via l'Inspecteur.
@export_file("*.tscn") var scene_path: String = ""
@export var count: int = 1

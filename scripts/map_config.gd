class_name MapConfig
extends Node

## Métadonnées de la map — configurable dans l'Inspecteur.
## Duplique la scène et modifie ces valeurs pour créer de nouvelles maps.
## Le nombre de chapitres est déterminé automatiquement par les enfants
## ChapterDefinition du WaveController : pas besoin de le déclarer ici.
@export var map_name: String = "Les Catacombes"
@export var difficulty_label: String = "Normal"
@export var description: String = "Un ancien complexe souterrain infesté de morts-vivants."

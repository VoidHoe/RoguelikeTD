class_name HeroBoard
extends Node

var _slots: Array[PlacementSlot] = []

signal hero_placed(slot: PlacementSlot)
signal hero_removed(slot: PlacementSlot)

func register_slot(slot: PlacementSlot) -> void:
	_slots.append(slot)

func place_hero_at(slot: PlacementSlot, hero: Node) -> void:
	if slot.is_occupied:
		return
	slot.place_hero(hero)
	hero_placed.emit(slot)

func remove_hero_at(slot: PlacementSlot) -> void:
	if not slot.is_occupied:
		return
	slot.remove_hero()
	hero_removed.emit(slot)

func get_empty_slots() -> Array[PlacementSlot]:
	var result: Array[PlacementSlot] = []
	result.assign(_slots.filter(func(s: PlacementSlot) -> bool: return not s.is_occupied))
	return result

func get_occupied_slots() -> Array[PlacementSlot]:
	var result: Array[PlacementSlot] = []
	result.assign(_slots.filter(func(s: PlacementSlot) -> bool: return s.is_occupied))
	return result

func get_slot_count() -> int:
	return _slots.size()

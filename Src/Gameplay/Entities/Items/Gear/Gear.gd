extends Item
class_name Gear

export var health_stat : int = 0
export var mana_stat : int = 0
export var attack_power_stat : int = 0
export var spell_power_stat : int = 0
export var movement_speed_stat : int = 0

var health_modifier = Modifier.new(Enums.ModifierType.Additive, health_stat)
var mana_modifier = Modifier.new(Enums.ModifierType.Additive, mana_stat)
var attack_power_modifier = Modifier.new(Enums.ModifierType.Additive, attack_power_stat)
var spell_power_modifier = Modifier.new(Enums.ModifierType.Additive, spell_power_stat)
var movement_speed_modifier = Modifier.new(Enums.ModifierType.Additive, movement_speed_stat)

var slot = Enums.GearSlot.NOTSET

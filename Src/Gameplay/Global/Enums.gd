extends Node


enum TargetType { Unset, Self, Unit, Position }
enum ModifierType { Additive, Multiplicative }
enum Team { Ally, Enemy }
enum ActionSource { Spell, Inventory, Equip }
enum ButtonSource { Bag, Spellbook, ActionBar, Equipment }
enum UnitAnimationType { IDLE, WALKING, CASTING, DEAD }
enum GearSlotType { HEAD, CHEST, LEGS, FEET, HANDS, WEAPON }
enum Stat { HEALTH, MANA }

enum AbilityEntity {
	FIREBALL
}

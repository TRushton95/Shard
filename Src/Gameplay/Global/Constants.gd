extends Node

const SERVER_ID := 1

const GLOBAL_COOLDOWN := 1.0
const INDEFINITE_DURATION := 0.0 # Used for zones and status
const ONE_SHOT_DURATION := -1.0 # Used for zones only

class ClassNames:
	const ACTION_BUTTON = "ActionButton"
	const UNIT = "Unit"

class StateNames:
	const IDLE_NAVIGATION = "IdleNavigationState"
	const MOVEMENT_NAVIGATION = "MovementNavigationState"
	const PURSUE_NAVIGATION = "PursueNavigationState"
	const IDLE_COMBAT = "IdleCombatState"
	const ATTACKING_COMBAT = "AttackingCombatState"
	const CASTING_COMBAT = "CastingCombatState"
	const CHANNELLING_COMBAT = "ChannellingCombatState"

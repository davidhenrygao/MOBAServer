local DEFINE = {}

DEFINE.PROPERTY = {
	LEVEL = 1,
	EXP = 2,
	GOLD = 3,
}

DEFINE.UPDATE_PROPERTY = {
	LV_EXP = 1,
	GOLD = 2,
}

DEFINE.PLAYER_STATE = {
	UNLAUNCH = 1,
	NORMAL = 2,
	BATTLE = 3,
}

DEFINE.PLAYER_BATTLE_STATE = {
	FREE = 1,
	MATCHING = 2,
	FIGHTING = 3,
}

DEFINE.MATCH_STATE = {
	MATCHING = 1,
	MATCHED = 2,
}

DEFINE.CARD_DECK_SIZE = 6

return DEFINE

local retcode = {}

-- 0-999 are reserved for system use.
retcode.SUCCESS = 0
retcode.INTERNAL = 1
retcode.UNKNOWN_CMD = 2
retcode.PROTO_UNSERIALIZATION_FAILED = 3
retcode.PLAYER_STATE_ILLEGAL = 4

-- 1000-9999 are used for login
retcode.LOGIN_CLIENT_KEY_LEN_ILLEGAL = 1000
retcode.LOGIN_HANDSHAKE_FAILED = 1001
retcode.LOGIN_PROCESSING_IN_OTHER_PLACE = 1002
retcode.REGISTER_DB_ERR = 1003
retcode.CREATE_PLAYER_DB_ERR = 1004
retcode.ACCOUNT_PLAYER_NOT_EXIST = 1005

-- 10000-19999 are used for agent
-- 10000-10199 are used for player basic module
retcode.PLAYER_ID_NOT_EXIT = 10000
retcode.PLAYER_NOT_LOGIN = 10001
retcode.CHANGE_PLAYER_NAME_DB_ERR = 10002
retcode.GM_CHANGE_PLAYER_PROPETY_ERR_OPCODE = 10003
retcode.GM_CHANGE_PLAYER_PROPETY_SET_LV_VAL_ERR = 10004
retcode.GM_CHANGE_PLAYER_PROPETY_ADD_EXP_VAL_ERR = 10005
retcode.USER_RELOGIN_IN_OTHER_PLACE = 10006

-- 10200-10399 are used for card module
retcode.CREATE_PLAYER_CARD_INFO_DB_ERR = 10200
retcode.CARD_ID_NOT_EXIST = 10201
retcode.CARD_IS_NOT_UNLOCK = 10202
retcode.CARD_LV_EXCEED_MAX_LV = 10203
retcode.CARD_LV_UP_AMOUNT_NOT_ENOUGH = 10204
retcode.CARD_STATE_IS_NOT_NEW = 10205
retcode.CARD_DECK_INDEX_ILLEGAL = 10206
retcode.CARD_DECK_POS_ILLEGAL = 10207
retcode.CARD_ALREADY_IN_CARD_DECK = 10208
retcode.CARD_IS_UNLOCK_STATE = 10209
retcode.CARD_LV_UP_GOLD_NOT_ENOUGH = 10210

-- 10400-10599 are used for battle module
retcode.MATCH_TYPE_ERR = 10400
retcode.PLAYER_ALREADY_IN_MATCHING = 10401
retcode.PLAYER_ALREADY_IN_BATTLE = 10402
retcode.PLAYER_NOT_IN_MATCHING = 10403
retcode.PLAYER_ALREADY_MATCH_SUCCESS = 10404
retcode.PLAYER_NOT_IN_BATTLE = 10405
retcode.BATTLE_NOT_FOUND = 10406
retcode.BATTLE_ACTION_FRAME_ID_ERROR = 10407

return retcode

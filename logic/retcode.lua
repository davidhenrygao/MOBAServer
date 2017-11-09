local retcode = {}

-- 0-999 are reserved for system use.
retcode.SUCCESS = 0
retcode.INTERNAL = 1
retcode.UNKNOWN_CMD = 2
retcode.PROTO_UNSERIALIZATION_FAILED = 3

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

-- 10200-10399 are used for card module
retcode.CREATE_PLAYER_CARD_INFO_DB_ERR = 10200
retcode.CARD_ID_NOT_EXIST = 10201
retcode.CARD_IS_NOT_UNLOCK = 10202
retcode.CARD_LV_EXCEED_MAX_LV = 10203
retcode.CARD_LV_UP_AMOUNT_NOT_ENOUGH = 10204
retcode.CARD_STATE_IS_NOT_NEW = 10205
retcode.CARD_DECK_INDEX_ILLEGAL = 10206
retcode.CARD_DECK_POS_ILLEGAL = 10207

return retcode

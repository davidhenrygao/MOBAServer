local retcode = {}

-- 0-999 are reserved for system use.
retcode.SUCCESS = 0
retcode.INTERNAL = 1
retcode.UNKNOWN_CMD = 2
retcode.PROTO_UNSERIALIZATION_FAILED = 3

-- 1000-9999 are used for login
retcode.ACCOUNT_ALREADY_EXIST = 1000
retcode.ACCOUNT_NOT_EXIST = 1001
retcode.REGISTER_DB_ERR = 1002
retcode.CREATE_PLAYER_DB_ERR = 1003
retcode.ACCOUNT_PLAYER_NOT_EXIST = 1004
retcode.WRONG_PASSWORD = 1005

-- 10000-19999 are used for agent
retcode.PLAYER_ID_NOT_EXIT = 10000
retcode.PLAYER_NOT_LOGIN = 10001
retcode.CHANGE_PLAYER_NAME_DB_ERR = 10002

return retcode

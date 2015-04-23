-- user configuration --
LUALOG.UserConfig.logDirs = {sbox1 = "/home/steam/sb1/garrysmod/logs", jb1 = "/home/steam/jb1/garrysmod/logs", zs1 = "/home/steam/zs1/garrysmod/logs",
				dr1 = "/home/steam/dr1/garrysmod/logs", ph1 = "/home/steam/ph1/garrysmod/logs", tt1 = "/home/steam/tt1/garrysmod/logs"};
LUALOG.UserConfig.fileMask = "L*.log"
LUALOG.UserConfig.ShouldArchiveFiles = true;
LUALOG.UserConfig.targetDB = "/var/db/srcdslog.db"
LUALOG.UserConfig.ShouldFlushDB = false;

LUALOG.UserConfig.ShouldProcessLuaErrors = false;
LUALOG.UserConfig.ShouldProcessRcon = false;
LUALOG.UserConfig.ShouldProcessUnknown = true;
--LUALOG.UserConfig.ShouldProcessAdminSay = false; -- not yet implemented
--LUALOG.UserConfig.ShouldProcessPrivateSay = false; -- not yet implemented
-- logging level
LUALOG.UserConfig.ShowLogLevel = LOGTYPE_INFO
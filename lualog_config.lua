-- user configuration --
LUALOG.Config.logDirs = {sbox1 = "/home/steam/sb1/garrysmod/logs", jb1 = "/home/steam/jb1/garrysmod/logs", zs1 = "/home/steam/zs1/garrysmod/logs",
				dr1 = "/home/steam/dr1/garrysmod/logs", ph1 = "/home/steam/ph1/garrysmod/logs", tt1 = "/home/steam/tt1/garrysmod/logs"};
LUALOG.Config.fileMask = "L*.log"
LUALOG.Config.ShouldArchiveFiles = true;
LUALOG.Config.targetDB = "/var/db/srcdslog.db"
LUALOG.Config.ShouldFlushDB = false;

LUALOG.Config.ShouldProcessLuaErrors = false;
LUALOG.Config.ShouldProcessRcon = false;
LUALOG.Config.ShouldProcessUnknown = true;
LUALOG.Config.ShouldProcessAdminSay = false; -- not yet implemented
LUALOG.Config.ShouldProcessPrivateSay = false; -- not yet implemented
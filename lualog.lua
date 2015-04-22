
if not LUALOG then
	LUALOG = {}
	LUALOG.Config = {}
end



local driver = require "luasql.sqlite3"
require "lualog_config"



-- psuedo enums --
-- Establish some positional info for matches
local LOGDT_START, LOGDT_END, LOGTM_START, LOGTM_END, LOGENTRY_START = 3,12, 16,23, 26

-- Establish internal logging types
local LOGTYPE_ERROR, LOGTYPE_WARNING, LOGTYPE_INFO, LOGTYPE_DEBUG  = 1,2,3,4
local LOGTYPEMSG = {"Error", "Warning", "Info", "Debug"}

-- Establish context types for srcds log entries
local LOGCONTEXT_UNKNOWN, LOGCONTEXT_SAY, LOGCONTEXT_CONNECT, LOGCONTEXT_VALIDATED, LOGCONTEXT_ENTERED, LOGCONTEXT_ULXCMD, LOGCONTEXT_RCON, LOGCONTEXT_BANID, LOGCONTEXT_LUAERROR, LOGCONTEXT_LUAERRORDETAIL, LOGCONTEXT_SAYTEAM, LOGCONTEXT_DISCONNECTED = 1,2,3,4,5,6,7,8,9,10,11,12
local LOGCONTEXTMSG = {"Unknown","Say", "Connected", "Validated", "Entered", "ULX Command", "RCON", "Ban", "Lua Error", "Lua Error Detail", "SayTeam", "Disconnected"}

-- Establish basic check pattents
local LOGCONTEXT_SICHECKS = {"say_team", "say", "connected, address", "STEAM USERID validated", "entered the game", "disconnected"}
local LOGCONTEXT_SICHECKID = {LOGCONTEXT_SAYTEAM, LOGCONTEXT_SAY,LOGCONTEXT_CONNECT, LOGCONTEXT_VALIDATED, LOGCONTEXT_ENTERED, LOGCONTEXT_DISCONNECTED}

-- Establish secondary checks
local LOGCONTEXT_NONSICHECKS = {"%[ULX%]","rcon from","Banid:", "Lua Error:"}
local LOGCONTEXT_NONSICHECKID = {LOGCONTEXT_ULXCMD, LOGCONTEXT_RCON, LOGCONTEXT_BANID, LOGCONTEXT_LUAERROR}


-- logging level
local ShowLogLevel = LOGTYPE_INFO

------------------------------------------------------------------------------------------------------------------------

-- Misc --
local linesWritten = 0;
local ProcessingLuaError = false
local lastLuaErrorDate, lastLuaErrorTime = "",""
local currLogFileTag = ""
local currServer =""
local con, env


-- Some helper functions --
local function log(type, ...)
	if (type == nil) then type = LOGTYPE_INFO end;
	if (type > ShowLogLevel) then return end;
	local printResult = LOGTYPEMSG[type] .. "\t"
	
	for i,v in ipairs(arg) do
		printResult = printResult .. tostring(v) .. "\t"
	end
	print (printResult);
end


local function DeleteExistingTag(logtag)
	log(LOGTYPE_INFO,"Removing entries for "..currServer..logtag)
	res = assert (con:execute(string.format([[DELETE from logs where logfile = '%s']], currServer..logtag)))
end


local function MoveFile(logfile)
	os.rename(logfile, logfile..".archive")
end


function quotetrim(s)
  -- from PiL2 20.4
  s = s:gsub("^%s*(.-)%s*$", "%1")
  return (s:gsub("^\"*(.-)\"*$", "%1"))
end


local function IsLineValid(logline)
	local t = string.match(logline, 'L %d%d/%d%d/%d%d%d%d [-] %d%d:%d%d:%d%d: ')
	if (t == nil) then return false
	else return true end
end


----- Main code

local function ProcessLineContext(logdt, logtm, logentry)
	
	log (LOGTYPE_DEBUG, "Processing context: ", logentry);
	local contextid = LOGCONTEXT_UNKNOWN
	local nick, steamid, slot, ip, team, truelogentry = "","","","",""
	local cmd1, cmd2 = "",""
	
	-- Do basic checks for a standard steam info line plus context
	nick, slot, steamid, team, truelogentry  = string.match(logentry, '"(.*)<(%d+)><(.+)><(.*)>" (.*)')
	if (steamid ~= nil) then -- we have a typical Steam entry, like a say or a join
		log(LOGTYPE_DEBUG, "Steam Info parse:", nick, steamid, slot, ip, team, contextid, truelogentry)
		for key,value in pairs(LOGCONTEXT_SICHECKS) do
			local part1, part2 = string.match(truelogentry, '^('..value..')(.*)')
			if (part1 ~= nil) then
				contextid = LOGCONTEXT_SICHECKID[key]
				truelogentry = quotetrim(part2)
				break
			end
		end
		
	else  
		truelogentry = logentry -- default
		nick, steamid, slot, ip, team = "","","","",""  -- clear them
		log (LOGTYPE_DEBUG, "No Steam Info found", logentry)
		
		-- There are other checks to do.
		for key,value in pairs(LOGCONTEXT_NONSICHECKS) do
			local part1 = string.match(truelogentry, '^('..value..')')
			if (part1 ~= nil) then
				contextid = LOGCONTEXT_NONSICHECKID[key]
				truelogentry = truelogentry
				break
			end
		end
		
	end
	
	-- if we're processing lua error details out of bound and we get something other than unknown, turn off error processing
	if (ProcessingLuaError and contextid ~= LOGCONTEXT_UNKNOWN) then
		ProcessingLuaError = false;
	end

	-- if we encountered a lua error, prep to record future lines against it
	if (contextid == LOGCONTEXT_LUAERROR and LUALOG.Config.ShouldProcessLuaErrors) then
		ProcessingLuaError = true;
		lastLuaErrorDate = logdt
		lastLuaErrorTime = logtm
	end
	
	-- we have an unknown line during lua error processing -- it's the stack.
	if (contextid == LOGCONTEXT_UNKNOWN and ProcessingLuaError) then
		contextid = LOGCONTEXT_LUAERRORDETAIL
	end
	
	if (contextid == LOGCONTEXT_RCON and LUALOG.Config.ShouldProcessRcon == false) then
		return
	end
	
	log(LOGTYPE_DEBUG,LOGCONTEXTMSG[contextid], nick, steamid, slot, ip, team, truelogentry)
	
	if (contextid ~= LOGCONTEXT_UNKNOWN or LUALOG.Config.ShouldProcessUnknown == true) then
		linesWritten = linesWritten + 1
		local logdatetime = logdt .. ' ' .. logtm
		
		res = assert (con:execute(string.format([[INSERT INTO logs (server, logfile, logrowid, logdatetime, context, logentry, nick, steamid, ip, team)
		VALUES ('%s','%s', %d, '%s', '%s', '%s', '%s', '%s','%s','%s')]], currServer, currServer..currLogFileTag,linesWritten, logdatetime,LOGCONTEXTMSG[contextid], con:escape(truelogentry), con:escape(nick), steamid, ip, team )))		
	end
end


local function ProcessLine(rownum, logline)
	log (LOGTYPE_DEBUG, "Processing line # "..rownum, logline);
	if (IsLineValid(logline)) then
		local logdt = string.sub(logline,LOGDT_START,LOGDT_END)
		local logtm = string.sub(logline,LOGTM_START,LOGTM_END)
		local logentry = string.sub(logline,LOGENTRY_START)
		ProcessLineContext(logdt, logtm, logentry)
	else
		if (ProcessingLuaError) then
			ProcessLineContext(lastLuaErrorDate, lastLuaErrorTime, logline)
		else
			log (LOGTYPE_DEBUG, "Row number "..rownum.." rejected. Not a valid log entry");
		end
	end
end

local function ProcessFile(logfile)
	log (nil, "Processing: "..logfile);
	currLogFileTag = string.match(logfile, ".-([^\\/]-%.?[^%.\\/]*)$")
	currLogFileTag = string.match(currLogFileTag,"([^%.]*)")
	DeleteExistingTag(currLogFileTag)
	
	lines = {}
    for line in io.lines(logfile) do 
		log(LOGTYPE_DEBUG, line)
		lines[#lines+1] = line;
	end
	log(nil, "Lines loaded: "..#lines);
	linesWritten = 0;
	for key,logline in pairs(lines) do
		ProcessLine(key, logline)
	end
	log(nil, "Lines written: "..linesWritten);
end


local function CheckAndCreateTable()
	-- reset our table
	if (LUALOG.Config.ShouldFlushDB) then res = con:execute"DROP TABLE logs" end
	res = assert (con:execute[[
	CREATE TABLE IF NOT EXISTS logs(
	server varchar(50),
	logfile varchar(50),
	logrowid int,
	logdatetime datetime,
	nick varchar(50),
	steamid varchar(50),
	slot int,
	ip varchar(50),
	context varchar(50),
	team varchar(50),
	logentry varchar(255)
	)
	]])
end


-- Entry point --

env = assert (driver.sqlite3())
con = assert (env:connect(LUALOG.Config.targetDB))
CheckAndCreateTable()
for key, value in pairs(LUALOG.Config.logDirs) do

	local filesToProcess = {}
	dir = value
	currServer = key
	log (nil,"Building log file list")
	local p = io.popen('find "'..dir..'" -type f -name "'..LUALOG.Config.fileMask..'" | xargs ls -1tr')  

	for file in p:lines() do                         --Loop through all files
	   filesToProcess[#filesToProcess + 1] = file;
	   log (LOGTYPE_DEBUG, "Queued for processing: "..filesToProcess[#filesToProcess]);
	end
	for key,logfile in pairs(filesToProcess) do
		ProcessFile(logfile)
		
		-- don't archive the last file, it's most likely in use.
		if next(filesToProcess,key) ~= nil and LUALOG.Config.ShouldArchiveFiles == true then
			MoveFile(logfile)
		end
	end
			
end
con:close()
env:close()	

		
		
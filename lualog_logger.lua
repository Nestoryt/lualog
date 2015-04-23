-- Establish internal logging types
LOGTYPE_ERROR, LOGTYPE_WARNING, LOGTYPE_INFO, LOGTYPE_DEBUG  = 1,2,3,4
LOGTYPEMSG = {"Error", "Warning", "Info", "Debug"}

-- Some helper functions --
function LUALOG.log(type, ...)
	if (type == nil) then type = LOGTYPE_INFO end;
	if (type > LUALOG.UserConfig.ShowLogLevel) then return end;
	local printResult = LOGTYPEMSG[type] .. "\t"
	
	for i,v in ipairs(arg) do
		printResult = printResult .. tostring(v) .. "\t"
	end
	print (printResult);
end




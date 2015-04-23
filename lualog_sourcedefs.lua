LUALOG.SourceDefs.SourceTypes = {  	{TypeName="SrcdsLog"},
									{TypeName = "ConsoleLog"},
									{TypeName = "EventHook"}
								}

LUALOG.SourceDefs.Specs = {}								
								
LUALOG.SourceDefs.Specs["SrcdsLog"] = { Text = "Log data from standard srcds log files" }
LUALOG.SourceDefs.Specs["ConsoleLog"] = { Text = "Log data from console log files" }
LUALOG.SourceDefs.Specs["EventHook"] = { Text = "Log data from event hooks" }


tprint(LUALOG.SourceDefs)










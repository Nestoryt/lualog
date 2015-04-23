LUALOG.SourceDefs.SourceTypes = {  	{TypeName="SrcdsLog"},
									{TypeName = "ConsoleLog"},
									{TypeName = "EventHook"}
								}

LUALOG.SourceDefs.Specs = {}								
								
LUALOG.SourceDefs.Specs["SrcdsLog"] = { 	Text = "Log data from standard srcds log files",
											Date_Start = 3, Date_End = 12, Time_Start = 16, Time_End = 23, Entry_Start = 26
									  }
									  
LUALOG.SourceDefs.Specs["ConsoleLog"] = { Text = "Log data from console log files" }
LUALOG.SourceDefs.Specs["EventHook"] = { Text = "Log data from event hooks" }


LUALOG.tprint(LUALOG.SourceDefs)










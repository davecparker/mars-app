-----------------------------------------------------------------------------------------
--
-- msgText.lua
--
-- The text of all messages sent in the Mars App game.
-----------------------------------------------------------------------------------------

-- Messages have a named index id and a text value.
local msgText = {

	sas1 = "[== Messaging system online with Sierra Automated System (SAS) ==]",

	stasis1 = "SAS - You have been brought out of stasis. Automated systems compromised. " ..
	          "Manual course correction required. Report to the bridge immediately.",	  

	correct1 = "SAS - Automated systems compromised. Manual course correction required. " ..
	           "Restore trajectory. Use the attitude thusters to restore the heading vector directly toward Mars.",

	data1 = "SAS - Data corruption, multiple files. Data retrieval in progress.",

	antFail = "SAS - Antenna array status report\n" .. 
			  "Critical antenna array failure. Communication with Mission Control offline.",
	
	panel1 = "SAS - Power generator failure. Panel 22A reconfiguration required. Report to engineering.",

	podStatus = "SAS - Stasis pod status report\n" ..
				"Pod 1, Jordan, empty\n" ..
				"Pod 2, Maxwell, empty\n" ..
				"Pod 3, Shaw, damaged, occupant deceased\n" ..
				"Pod 4, Ellis, damaged, occupant deceased\n" ..
				"Pod 5, Graham, empty\n" ..
				"Pod 6, You, empty\n" ..
				"Pod 7, Webb, damaged, occupant deceased\n" ..
				"Pod 8, Moore, empty",

	green1 = "SAS - Report to the Greenhouse. Automation failure. Food supply inadequate. " ..
	         "Restore food level to 150 kg minumum.",

	panel2 = "SAS - Water recirculator failure. Panel 57C reconfiguration required. Report to Lab.",

	correct2 = "SAS - Approaching Mars. Manual trajectory alignment required. Report to the bridge " ..
	           "immediately and restore heading vector.",

	panel3 = "SAS - Failure in Kitchen unit 2. Report to Lounge.",

	land = "SAS - Mars orbit achieved. Commence Sierra landing procedure.",

	landed = "SAS - Landing target achieved. Congratulations Sierra crew, " ..
	         "you've just established the first settlement on Mars!",	

}

return msgText

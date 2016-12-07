-----------------------------------------------------------------------------------------
--
-- msgText.lua
--
-- The text of all messages sent in the Mars App game.
-----------------------------------------------------------------------------------------

-- Messages have a named index id and a text value.
local msgText = {

	sas1 = "[== Personal messaging device online with Sierra Automated System (SAS). ==]",

	stasis1 = 	"SAS - You have been brought out of stasis. \n" ..
				"Automated systems compromised. \n" ..
				"Crew compromised. \n" ..
				"Trajectory compromised. \n" ..
				"Manual course correction required. \n" ..
				"Report to Bridge immediately.",

-- trigger for correct1 when Enter Bridge  

	correct1 = 	"SAS - Manual mode engaged. \n" ..
				"Restore trajectory. Use attitude thusters to restore heading vector directly toward Mars.",

-- Trigger for Trajectory game

	data1 = "SAS - Data corruption, multiple files. File recovery in progress. " ..
			"Retrieval notifications to follow.",

-- Triggers for docs and SAS message notifications including time delays:
	fileS1 = "SAS - Partial file retrieval. Document on Shaw's terminal.",

-- Insert trigger
	fileJ1 = "SAS - Partial file retrieval. Document on Jordan's terminal.",

	codes= 	"SAS - Security update: restricted \n" ..
			"Protocol trigger: command change \n" ..
			"Authorized personnel: ranking officer \n" ..
			"Medium security access code: 1010",

	
	panel1 = "SAS - Power generator failure. Panel 22A reconfiguration required. Report to Engineering.",

-- Insert trigger
-- SAS - Partial file retrieval. Document on Graham's terminal. (Graham - personal log)

	antFail =	"SAS - Antenna array status report:\n" .. 
				"Critical antenna array failure. Communication offline.",

	mcSignal = "SAS - Mission Control signal last received: 37 hours, 14 minutes.",


-- Insert trigger
-- SAS - Partial file retrieval. Document on Moore's terminal. (Moore - personal log)

	green1 = 	"SAS - Automated irrigation failure. Food supply inadequate. " ..
				"Restore food level to at least 150 kg. Report to Greenhouse immediately.",

-- Insert triggers
-- greenhouse panel game 
-- SAS - Partial file retrieval. Document on Shaw's terminal. (Shaw - personal log)

	podStatus = "SAS - Stasis pod status report: \n" ..
				"Pod 1, Jordan, empty \n" ..
				"Pod 2, Maxwell, empty \n" ..
				"Pod 3, Shaw, damaged, occupant deceased \n" ..
				"Pod 4, Ellis, damaged, occupant deceased \n" ..
				"Pod 5, Graham, empty \n" ..
				"Pod 6, You, empty \n" ..
				"Pod 7, Webb, damaged, occupant deceased \n" ..
				"Pod 8, Moore, empty",

	panel2 = "SAS - Water recirculator failure. Panel 57C reconfiguration required. Report to Lab.",

-- Insert triggers
-- Lab panel game
-- SAS - Partial file retrieval. Document on Graham's terminal. (Graham - personal log 2)
-- SAS - Partial file retrieval. Document on Lounge terminal. (Message History)

	correct2 = 	"SAS - Approaching Mars. Manual piloting required. Insert into Mars orbit. " ..
				"Report to Bridge immediately.",

-- Insert triggers
-- Trajectory 2/Orbit game 
-- SAS - Partial file retrieval. Document on Jordan's terminal. (Jordan - personal log 2)

	panel3 = "SAS - Failure in Kitchen unit 2. Report to Lounge.",

-- Insert triggers
-- Kitchen panel game
-- SAS - Partial file retrieval. Document on Jordan’s terminal. (Classified - device)
-- SAS - Partial file retrieval. Document on Jordan’s terminal. (Classified - energy)
-- SAS - Partial file retrieval. Document on Ellis's terminal. (Ellis - personal log)
-- SAS - Partial file retrieval. Document on Webb's terminal. (Webb - personal log)
-- (Shaw2 ?)

    docs = "SAS - Partial file retrieval. Multiple files. Documents on crew terminals.",

	land = "SAS - Mars orbit stable. Landing site in range. Commence Sierra landing procedure.",

	landed = 	"SAS - Landing target achieved. Congratulations Sierra crew, " ..
				"you've just established the first settlement on Mars!",	

	mars1 = 	"SAS - Resume primary mission objectives: \n" .. 
				"1. Explore surface and drill for water. \n" ..
				"2. Manage greenhouse food production. \n" ..
				"3. Investigate artifacts.",
	
	mars2 = 	"SAS - Hostile bugs attacking food supply. \n" .. 
				"Report to Engineering to access Cargo Bay",

	foodOut =	"SAS - CRITICAL ALERT: Food supplies exhausted. Replenish immediately. \n" ..
				"Rover use disabled.",

	resOut =	"SAS - CRITICAL EMERGENCY: Food and water supplies exhaused. \n" ..
				"Report to lab for emergency stasis.",	

	regenerated = 	"SAS - Stasis terminated. Emergency water supply has been generated. " ..
					"Food supply exhausted. Replenish immediately",
}

return msgText

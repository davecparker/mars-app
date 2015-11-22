-----------------------------------------------------------------------------------------
--
-- msgText.lua
--
-- The text of all messages sent in the Mars App game.
-----------------------------------------------------------------------------------------

-- Messages have a named index id and a text value.
local msgText = {

	sas1 = "[== Personal messaging device online with Sierra Automated System (SAS). ==]",

	stasis1 = "SAS - You have been brought out of stasis.\n" ..
                  "Automated systems compromised.\n" ..
                  "Crew compromised.\n" ..
		  "Trajectory compromised.\n" ..
	          "Manual course correction required.\n" ..
                  "Report to Bridge immediately.",

-- Insert trigger for correct1 when Enter Bridge  

	correct1 = "SAS - Automated systems compromised. Manual course correction required. " ..
	           "Restore trajectory. Use attitude thusters to restore heading vector directly toward Mars.",

-- Insert trigger for Trajectory game

	data1 = "SAS - Data corruption, multiple files. Data recovery in progress. Retrieval notifications to follow.",

-- Insert triggers for docs and SAS message notifications including time delays:
-- SAS - Partial file retrieval. Document on Bridge terminal. (The Sierra)
-- SAS - Partial file retrieval. Document on Bridge terminal. (Crew Manifest)
-- SAS - Partial file retrieval. Document on Shaw's terminal. (Shaw - personal log)

	antFail = "SAS - Antenna array status report:\n" .. 
			  "Critical antenna array failure. Communication offline.",

	msgRpt = "SAS - Mission Control signal last received: 37 hours, 14 minutes.",

-- Insert trigger
-- SAS - Partial file retrieval. Document on Jordan's terminal. (Jordan - personal log)

-- Player will have two inaccessible rooms by the time they receive the next message with door codes.
-- If that isn't OK for game flow, I'll change the sequence of info. Please advise.

	codes= "SAS - Security update: classified\n" ..
				"Protocol trigger: command change\n" ..
				"Authorized personnel: ranking officer\n" ..
				"0007\n" ..
				"1010\n" ..
				"0122\n" ..
				"1578\n" ..
				"1776\n" ..
				"1812\n" ..
				"3141\n" ..
				"2439\n" ..
				"4242\n" ..
				"4859\n" ..
				"5678\n" ..
				"6482\n" ..
				"6965\n" ..
				"7595\n" ..
				"9928",	
	
	panel1 = "SAS - Power generator failure. Panel 22A reconfiguration required. Report to Engineering.",

-- Insert trigger
-- SAS - Partial file retrieval. Document on Graham's terminal. (Graham - personal log)

	podStatus = "SAS - Stasis pod status report:\n" ..
				"Pod 1, Jordan, empty\n" ..
				"Pod 2, Maxwell, empty\n" ..
				"Pod 3, Shaw, damaged, occupant deceased\n" ..
				"Pod 4, Ellis, damaged, occupant deceased\n" ..
				"Pod 5, Graham, empty\n" ..
				"Pod 6, You, empty\n" ..
				"Pod 7, Webb, damaged, occupant deceased\n" ..
				"Pod 8, Moore, empty",

-- Insert trigger
-- SAS - Partial file retrieval. Document on Moore's terminal. (Moore - personal log)

	green1 = "SAS -  Critical irrigation failure. Food supply inadequate. " ..
	         "Restore food level to 150 kg. Report to Greenhouse immediately.",

-- Insert triggers
-- greenhouse panel game 
-- SAS - Partial file retrieval. Document on Shaw's terminal. (Shaw - personal log)

	panel2 = "SAS - Water recirculator failure. Panel 57C reconfiguration required. Report to Lab.",

-- Insert triggers
-- Lab panel game
-- SAS - Partial file retrieval. Document on Graham's terminal. (Graham - personal log 2)
-- SAS - Partial file retrieval. Document on Lounge terminal. (Message History)

	correct2 = "SAS - Approaching Mars. Manual piloting required. Achieve Mars orbit. " ..
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


	land = "SAS - Mars orbit achieved. Commence Sierra landing procedure.",

	landed = "SAS - Landing target achieved. Congratulations Sierra crew, " ..
	         "you've just established the first settlement on Mars!",	

}

return msgText

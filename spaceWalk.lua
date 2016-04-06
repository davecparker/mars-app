-----------------------------------------------------------------------------------------
--
-- spaceWalk.lua
--
-- Joe Cracchiolo
-- The spacewalk game to fix the solar panels
-----------------------------------------------------------------------------------------
------------------------- OverHead ---------------------------------------------------------
-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()
-------------------------- Variables ------------------------------------------------------
local player
local playerY          -- saves the player location for swipe event
local panelT = false   -- area for the panel repairs T is top, M is middle and B is bottom
local panelM = true
local panelB = false
local repairBar        -- the visual repair bar

------------------------- Functions -------------------------------------------------------

-- swipe event for the player
local function swipePlayer( event )
	if event.phase == "began" then
		playerY = event.y

	elseif event.phase == "ended" then
		--swiped down
		if event.y > playerY + 20 then
			if player.pos == 2 then
				transition.to( player, { y = player.y + 120, time = 500, transition = easing.outQuad} )
				player.pos = 3
			elseif player.pos == 1 then
				transition.to( player, { y = player.y + 120, time = 500, transition = easing.outQuad} )
				player.pos = 2
			end
		-- swipe up
		elseif event.y < playerY - 20 then
			if player.pos == 3 then
				transition.to( player, { y = player.y - 120, time = 500, transition = easing.outQuad} )
				player.pos = 2
			elseif player.pos == 2 then
				transition.to( player, { y = player.y - 120, time = 500, transition = easing.outQuad} )
				player.pos = 1
			end
		end
	end
end

-- player taping to repair the panels
local function repairTap( event )
	-- stuff
end

------------------------- Start of Activity -------------------------------------------------

-- Init the act
function act:init()

	-- create the background
	bg = act:newImage("background.jpg", {width = act.width})
	bg:addEventListener( "touch", swipePlayer )

	-- create the player
	player = act:newImage( "Astronaut.png", {width = 100} )
	player.x = act.xCenter
	player.y = act.yCenter
	player.pos = 2   -- position of player 1 = top, 2 = middle and 3 = bottom
	player:addEventListener( "tap", repairTap )

end

-- runtime checking where the player is and changing logic accordingly
--function act:enterFrame( event )
--	if panelT == true then
--		repair()
--	end
--end

------------------------- End of Activity ----------------------------------------------------
-- Corona needs the scene object returned from the act file
return act.scene

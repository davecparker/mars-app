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
local spaceBgs         -- Space background image
local brokenTop        -- borken parts
local brokenMid
local brokenBottom
local player
local playerY          -- saves the player location for swipe event
local panelT = false   -- area for the panel repairs T is top, M is middle and B is bottom
local panelM = true
local panelB = false
local repairBar        -- the visual repair bar

------------------------- Functions -------------------------------------------------------

-- Handle new frame events
function act:enterFrame()
	-- Continuous scroll of the endless space background
	for i = 1, 2 do
		local bg = spaceBgs[i]
		bg.y = bg.y + 0.5
		if bg.y > act.yMax then
			bg.y = act.yMin - act.height
		end
	end
end

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

	-- Space background images (2 for continuous scrolling)
	spaceBgs = {
		act:newImage( "space.jpg", { y = act.yMin, anchorY = 0, height = act.height, folder = "media/mainAct"}  ),
	 	act:newImage( "space.jpg", { y = act.yMin - act.height, anchorY = 0, height = act.height, folder = "media/mainAct" }  ),
	 }

	-- create the background
	bg = act:newImage("solarPanel.png", {width = act.width})
	bg:addEventListener( "touch", swipePlayer )

	-- display borken parts
	brokenTop = act:newImage("topBreak.png", { width = 80, x = act.xCenter - 60, y = act.yCenter - 150})
	brokenMid = act:newImage("midBreak.png", { width = 110, x = act.xCenter + 70, y = act.yCenter + 10})
	brokenBottom = act:newImage("bottomBreak.png", { width = 100, x = act.xCenter - 80, y = act.yCenter + 140})

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

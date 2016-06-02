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
local spaceBgs                         -- Space background image
local brokenTop                        -- borken parts
local brokenMid
local brokenBottom
local HTPBorder                        -- How to play border
local HTPText                          -- how to play text
local danger                           -- danger sign
local meteorReset                      -- the meteor reset function
local meteor                           -- the meteor object
local player                           -- table for the player, player.pos gives the players position
local playerY                          -- saves the player location for swipe event
local playerGroup                      -- a group for all the stuff that needs to animate together
local gameOverCheck = false            -- checks game over state
local barPos = {                       -- properties of the status bar
	{y = act.yCenter - 120, progress = 0, fixed = false} ,
	{y = act.yCenter, progress = 0, fixed = false},
	{y = act.yCenter + 120, progress = 0, fixed = false},
}

------------------------- Functions -------------------------------------------------------

-- function to remove status bar
local function barRemove (pos)
	barPos[pos].statusBarBorder:removeSelf()
	barPos[pos].statusBarBorder = nil
	barPos[pos].statusBar:removeSelf()
	barPos[pos].statusBar = nil
	barPos[pos].progress = 0
end

-- go back to previous act
local function goBack()
	game.gotoAct ( "mainAct", {effect = "slideRight"} )
end

-- Game Over function
local function gameOver()
	if barPos[1].fixed == true and barPos[2].fixed == true and barPos[3].fixed == true then
		local winBorder = display.newRoundedRect( act.group, act.xCenter, act.yCenter, 300, 70, 12 )
		winBorder:setFillColor( 1, 184/255, 0 )
		local winText = display.newText( act.group, "Repairs Complete", act.xCenter, act.yCenter,  native.systemFontBold, 30 )
		transition.cancel( )
		gameOverCheck = true
		timer.performWithDelay( 3000,  goBack) 
	end
end

-- Function for handeling the fixing of a panel
local function fixed (pos)
	barPos[pos].fixed = true
	if pos == 1 then
		brokenTop:removeSelf()
		brokenTop = nil
	elseif pos == 2 then
		brokenMid:removeSelf()
		brokenMid = nil
	else
		brokenBottom:removeSelf()
		brokenBottom = nil
	end
	gameOver()
end

-- Sends a meteor at a random spot and at a random time
local function sendMeteor ()
	-- make sure the game is not over
	if gameOverCheck == false then
		-- resets the meteor
		function meteorReset ()
			if danger then
				danger:removeSelf( )
				danger = nil
				meteor:removeSelf( )
				meteor = nil
				math.randomseed(os.time())
				local meteorInterval = math.random(500, 5000)
				timer.performWithDelay(meteorInterval, sendMeteor)
			end
		end
		
		math.randomseed(os.time())
		local meteorPosition = math.random(1, 3)
		danger = act:newImage("danger.png",{y = barPos[meteorPosition].y, x = xCenter, width = act.width/2})
		meteor = act:newImage("meteor.png",{y = barPos[meteorPosition].y, x = act.width + 100, width = 50})
		meteor.pos = meteorPosition
		transition.to( meteor, {time = 1000, delay = 500, x = -150, rotation = 360, onComplete = meteorReset} )
	end
end

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
	
	-- Progress bar decreases with time
	for i = 1, 3 do
		if barPos[i].progress > 0 then
			barPos[i].statusBar.width = barPos[i].progress
			barPos[i].progress = barPos[i].progress - 0.2
			
			-- remove the status bar if meter reaches zero
			if barPos[i].progress < 1 then
				barRemove(i)
			end
		end
		-- removes an empty status bar if the player moves away
		if barPos[i].progress < 1 and player.pos ~= i and barPos[i].statusBarBorder then
			barRemove(i)
		end
		if barPos[i].progress > 240 then
			fixed(i)
			barRemove(i)
		end
	end

	-- if there is a danger sign move it to the front
	if danger then
		danger:toFront( )
	end

	-- checks for a hit
	if meteor then
		if (meteor.x < (act.xCenter + 25)) and (player.pos == meteor.pos) then
			-- if its a hit remove the progress
			transition.cancel( meteor )
			meteorReset ()
			for i = 1, 3 do
				if barPos[i].statusBarBorder then
					barRemove (i)	
				end
				if i == 1 and barPos[i].fixed == true then
					brokenTop = act:newImage("topBreak.png", { width = 80, x = act.xCenter - 60, y = act.yCenter - 150})
					playerGroup:insert( brokenTop )
					playerGroup:insert( player )
				elseif i == 2 and barPos[i].fixed == true then
					brokenMid = act:newImage("midBreak.png", { width = 110, x = act.xCenter + 70, y = act.yCenter + 10})
					playerGroup:insert( brokenMid )
					playerGroup:insert( player )
				elseif i == 3 and barPos[i].fixed == true then
					brokenBottom = act:newImage("bottomBreak.png", { width = 100, x = act.xCenter - 80, y = act.yCenter + 140})
					playerGroup:insert( brokenBottom )
					playerGroup:insert( player )
				end
				barPos[i].fixed = false
			end
			-- hit animation
			local function removeRect()
				if temp then
					temp:removeSelf( )
					temp = nil
				end
			end
			local temp = display.newRect( act.group, act.xCenter, act.yCenter, act.width + 100, act.height )
			temp:setFillColor( 1, 0, 0, 0.5 )
			transition.to( playerGroup, {time = 100, iterations = 3, transition = easing.continuousLoop, x = 20} )
			transition.fadeOut( temp, {time = 500, onComplete = removeRect} )
		end
	end
end

-- creates the status bar when the player moves
function createStatusBar()
	-- create a new status bar
	if barPos[player.pos].statusBar then
		--if there is a bar do nothing
	else
		barPos[player.pos].statusBar = display.newRect(  act.group, (act.width/2), (barPos[player.pos].y), barPos[player.pos].progress, 10 )
		barPos[player.pos].statusBar:setFillColor( 0, 1, 0 )
		barPos[player.pos].statusBarBorder = act:newImage("statusBar.png", {y = barPos[player.pos].y, x = act.width/2, width = 250, height = 10})
	end
end

-- swipe event for the player
local function swipePlayer( event )	
	local lastPos = player.pos
	if event.phase == "began" then
		playerY = event.y

	elseif event.phase == "ended" then
		--swiped down
		if event.y > playerY + 20 then
			if player.pos == 2 then
				player.pos = 3
				transition.to( player, { y = player.y + 120, time = 500, transition = easing.outQuad} )
				
			elseif player.pos == 1 then
				player.pos = 2
				transition.to( player, { y = player.y + 120, time = 500, transition = easing.outQuad} )
				
			end
		-- swipe up
		elseif event.y < playerY - 20 then
			if player.pos == 3 then
				player.pos = 2
				transition.to( player, { y = player.y - 120, time = 500, transition = easing.outQuad} )
				
			elseif player.pos == 2 then
				player.pos = 1
				transition.to( player, { y = player.y - 120, time = 500, transition = easing.outQuad} )
				
			end
		end
	end
end

-- player taping to repair the panels
local function repairTap( event )
	-- checks to see if the part is still broken
	if barPos[player.pos].fixed == false then
		-- this part makes a bar if the player taps at the initial position and there is no bar
		if barPos[player.pos].statusBar == nil then
			createStatusBar()
		end
		barPos[player.pos].progress = barPos[player.pos].progress + 10
		barPos[player.pos].statusBar.width = barPos[player.pos].progress
	end
end

-- start the game after the How to play screen is taped
local function startGame (evnet)
	HTPBorder:removeSelf( )
	HTPBorder = nil
	HTPText:removeSelf( )
	HTPText = nil
	timer.performWithDelay( 2000, sendMeteor )
	return true
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

	-- put everyting that needs animation in a group
	playerGroup = act:newGroup()
	playerGroup:insert( bg )
	playerGroup:insert( brokenTop )
	playerGroup:insert( brokenMid )
	playerGroup:insert( brokenBottom )
	playerGroup:insert( player )

	-- How to play screen
	HTPBorder = display.newRect( act.group, act.xCenter, act.yCenter, 300, 400 )
	HTPBorder:setFillColor(77/222, 184/255, 1) 
	HTPBorder:addEventListener( "tap", startGame )
	HTPText = act:newImage("HTPText.png", {width = 280})
end

------------------------- End of Activity ----------------------------------------------------
-- Corona needs the scene object returned from the act file
return act.scene
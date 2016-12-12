-----------------------------------------------------------------------------------------
--
-- scottAct.lua
--
-- tap tap challenge bug destroyer
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

-- File local variables
local bug 
local bugCount = 20
local leftButton
local upButton
local rightButton
local downButton
local foodTarget
local upLaser
local leftLaser
local rightLaser
local downLaser
local buttonHeight = 100
local buttonWidth = act.width / 4
local gameState = true
local myHeight = act.yMax - (buttonHeight)
local myWidth = act.width
local myYCenter = act.yCenter - (buttonHeight / 2)
local bugSpeed = 1000
local failCount = 0
local instructionGroup

------------------------------** Laser Control **----------------------------------------
local function createUpLaser()
	upLaser = display.newRect( act.group, act.xCenter, act.yCenter - 70, 40, 5 )
	physics.addBody( upLaser )
	upLaser:setFillColor( 1, 0, 0 )
	upLaser.isLaser = true
	return upLaser
end

local function createLeftLaser()
	leftLaser = display.newRect( act.group, act.xCenter - 20, act.yCenter - 50, 5, 40)
	physics.addBody( leftLaser )
	leftLaser:setFillColor( 1, 0, 0 )
	leftLaser.isLaser = true
	return leftLaser
end

local function createRightLaser()
	rightLaser = display.newRect( act.group, act.xCenter + 20, act.yCenter - 50, 5, 40 )
	physics.addBody( rightLaser )
	rightLaser:setFillColor( 1, 0, 0 )
	rightLaser.isLaser = true
	return rightLaser
end

local function createDownLaser()
	downLaser = display.newRect( act.group, act.xCenter, act.yCenter - 30, 40, 5 )
	physics.addBody( downLaser )
	downLaser:setFillColor( 1, 0, 0 )
	downLaser.isLaser = true
	return downLaser
end

local function activateLeft( event )
	-- leftButton laser
	if event.phase == "began" then
		display.getCurrentStage( ):setFocus( leftButton )
		createLeftLaser()
	elseif event.phase == "ended" then
		display.getCurrentStage( ):setFocus(nil)
		leftLaser:removeSelf( )
	end
end

local function activateUp( event )
	-- Up laser
	if event.phase == "began" then
		display.getCurrentStage( ):setFocus( upButton )
		createUpLaser()
	elseif event.phase == "ended" then
		display.getCurrentStage( ):setFocus( nil )
		upLaser:removeSelf( )
	end
end

local function activateRight( event )
	-- rightButton laser
	if event.phase == "began" then
		display.getCurrentStage( ):setFocus( rightButton )
		createRightLaser()
	elseif event.phase == "ended" then
		display.getCurrentStage( ):setFocus( nil )
		rightLaser:removeSelf( )
	end
end

local function activateDown( event )
	-- downButton laser
	if event.phase == "began" then
		display.getCurrentStage( ):setFocus( downButton )
		createDownLaser()
	elseif event.phase == "ended" then
		downLaser:removeSelf( )
		display.getCurrentStage( ):setFocus( nil )
	end	
end

------------------------------** Set up the background and UI **------------------------------
local function setBackgound()
	-- put in the background and UI
	local bg = act:newImage("bugbg.png", {x = act.xCenter, y = myYCenter, height = myHeight + (buttonHeight/2), width = myWidth})
	
	-- display the UI boxes
	leftButton = act:newImage("leftButton.png", {x = act.xMin, y = act.yMax, width = buttonWidth, height = buttonHeight})
	leftButton.anchorX = 0
	leftButton.anchorY = 1
	leftButton:addEventListener( "touch", activateLeft )

	upButton = act:newImage("upButton.png", {x = act.xMax / 4, y = act.yMax, width = buttonWidth, height = buttonHeight})
	upButton.anchorX = 0
	upButton.anchorY = 1
	upButton:addEventListener( "touch", activateUp )

	rightButton = act:newImage("rightButton.png", {x = act.xMax - (act.xMax / 4), y = act.yMax, width = buttonWidth, height = buttonHeight})
	rightButton.anchorX = 0
	rightButton.anchorY = 1
	rightButton:addEventListener( "touch", activateRight )

	downButton = act:newImage("downButton.png", {x = act.xMax / 2, y = act.yMax, width = buttonWidth, height = buttonHeight})
	downButton.anchorX = 0
	downButton.anchorY = 1
	downButton:addEventListener( "touch", activateDown )
end


local function destroy( obj )
	obj:removeSelf( )
end

local function loseFood()
	local txt = display.newText( act.group, "-1 Food!", act.xCenter, act.yCenter, native.systemFont, 16 )
	transition.to( txt, {time = 1000, alpha = 0, y = act.yCenter + 50, onComplete = destroy} )
	game.addFood(-1)
end

------------------------------** Sprite **------------------------------
-- Image Sheet
local sheetOptions = 
{
	width = 18,
	height = 15,
	numFrames = 4
}

local walkingBug = 
{
	name = walkingBug,
	start = 1,
	count = 4,

}

local imageSheet = graphics.newImageSheet( "media/scottAct/bugSprite.png", sheetOptions )

------------------------------** Stage 2 Movement **------------------------------


local function moveCenter( obj )
	transition.to( obj, {x = act.xCenter, y = myYCenter, time = bugSpeed})
end

local function moveLeftMid( obj )
	transition.to( obj, {x = act.xCenter / 2, y = myYCenter, time = bugSpeed, onComplete = moveCenter} )
end

local function moveRightMid( obj )
	transition.to( obj, {x = myWidth - (myWidth / 4), y = myYCenter, time = bugSpeed, onComplete = moveCenter})
end

local function moveUpMid( obj )
	transition.to( obj, {x = act.xCenter, y = myHeight / 4, time = bugSpeed, onComplete = moveCenter})
end

local function moveDownMid( obj )
	transition.to( obj, {x = act.xCenter, y = myHeight - (myHeight / 3), time = bugSpeed, onComplete = moveCenter})
end	

------------------------------** Object Initiation **------------------------------
-- Create bugs
local function createNorthBug()
	local randNum = math.random( 3 )

	bug = display.newSprite( act.group, imageSheet, walkingBug )
	bug.x = act.xCenter
	bug.y = act.yMin
	bug:play( )

	physics.addBody( bug )
	bug.collision = onBugCollision
	bug:addEventListener( "collision", bug )
	if randNum == 1 then
		transition.to(bug, {x=act.xCenter, y = myYCenter / 3, time = bugSpeed, onComplete = moveLeftMid})
	elseif randNum == 2 then
		transition.to(bug, {x=act.xCenter, y = myYCenter / 3, time = bugSpeed, onComplete = moveRightMid})
	elseif randNum == 3 then
		transition.to(bug, {x=act.xCenter, y = myYCenter / 3, time = bugSpeed, onComplete = moveCenter})
	end

	return bug
end

-- Create bugs from South
local function createSouthBug()
	local randNum = math.random( 3 )

	bug = display.newSprite( act.group, imageSheet, walkingBug )
	bug.x = act.xCenter
	bug.y = myHeight
	bug:play( )

	physics.addBody( bug )
	bug.collision = onBugCollision
	bug:addEventListener( "collision", bug )
	if randNum == 1 then
		transition.to(bug, {x=act.xCenter, y = myYCenter + ( myYCenter / 2 ), time = 1000, onComplete = moveLeftMid})
	elseif randNum == 2 then
		transition.to(bug, {x=act.xCenter, y = myYCenter + ( myYCenter / 2 ), time = 1000, onComplete = moveRightMid})
	elseif randNum == 3 then
		transition.to(bug, {x=act.xCenter, y = myYCenter + ( myYCenter / 2 ), time = 1000, onComplete = moveCenter})
	end

	return bug
end

-- Create bugs from East
local function createEastBug()
	local randNum = math.random( 3 )
	bug = display.newSprite(act.group, imageSheet, walkingBug )
	bug.x = act.xMax
	bug.y = myYCenter
	bug:play( )

	physics.addBody( bug )
	bug.collision = onBugCollision
	bug:addEventListener( "collision", bug )
	if randNum == 1 then
		transition.to(bug, {x = myWidth - (myWidth/4), y = myYCenter, time = bugSpeed, onComplete = moveUpMid})
	elseif randNum == 2 then
		transition.to(bug, {x = myWidth - (myWidth/4), y = myYCenter, time = bugSpeed, onComplete = moveDownMid})
	elseif randNum == 3 then
		transition.to(bug, {x = myWidth - (myWidth/4), y = myYCenter, time = bugSpeed, onComplete = moveCenter})
	end

	return bug
end

-- Create bugs from West
local function createWestBug()
	local randNum = math.random( 3 )
	bug = display.newSprite(act.group, imageSheet, walkingBug )
	bug.x = act.xMin
	bug.y = myYCenter
	bug:play( )

	physics.addBody( bug )
	transition.to(bug, {x=act.xCenter, y = act.yCenter - (buttonHeight/2), time = 3000})
	bug.collision = onBugCollision
	bug:addEventListener( "collision", bug )

	if randNum == 1 then
		transition.to(bug, {x = (myWidth/4), y = myYCenter, time = bugSpeed, onComplete = moveUpMid})
	elseif randNum == 2 then
		transition.to(bug, {x = (myWidth/4), y = myYCenter, time = bugSpeed, onComplete = moveDownMid})
	elseif randNum == 3 then
		transition.to(bug, {x = (myWidth/4), y = myYCenter, time = bugSpeed, onComplete = moveCenter})
	end

	return bug
end

local function createFoodTarget()
	foodTarget = act:newImage("foodTarget.png", {x = act.xCenter, y = myYCenter, width = 34, height = 34})
	physics.addBody( foodTarget, "static" )
	foodTarget:setFillColor( .5, .5, 0 )
	foodTarget.isFoodTarget = true

	return foodTarget
end

local function leaveGame()
	-- leave the act
	game.gotoAct("mainAct", {effect = "zoomOutIn", time = 500})
end

local function endGame()
	local great = display.newText( act.group, "GREAT!", myWidth / 2, myYCenter, native.systemFont, 18)
	transition.to( great, {xScale = 2, yScale = 2, time = 7000, onComplete = leaveGame} )
	local t = display.newText( act.group, "You only lost " .. failCount .. " food!" , myWidth / 2, myHeight - 150, native.systemFont, 16 )
end

-- collision detection
function onBugCollision(bug, event)
	if event.phase == "began" then
		local other = event.other
		if other.isLaser then
			bug:removeSelf( )
			bugCount = bugCount - 1
			if bugCount == 0 then
				endGame()
			end
		elseif other.isFoodTarget then
			loseFood()
			bug:removeSelf( )
			bugCount = bugCount - 1
			failCount = failCount + 1
			if bugCount == 0 then
				endGame()
			end
		end
	end
end

-- Spawn Bug
local function spawnBug()
	local whereFrom = math.random( 4 )

	if whereFrom == 1 then
		createNorthBug()
	elseif whereFrom == 2 then
		createEastBug()
	elseif whereFrom == 3 then
		createSouthBug()
	elseif whereFrom == 4 then
		createWestBug()
	end
end

-------------------------** Instructions **--------------------------------

local function startGame( event )
	instructionGroup:removeSelf( )
	instructionGroup = nil
	timer.performWithDelay( 1000, spawnBug, bugCount )
end

local function instructionBlock()
	instructionGroup = act:newGroup()

	local box = act:newImage( "instructions.png", {parent = instructionGroup, x = myWidth / 2, y = myYCenter, height = myHeight, width = myWidth} )
	local okay = display.newRect( instructionGroup, myWidth / 2, myHeight - 70, 100, 40)
	okay:setFillColor( .5 )
	okay:addEventListener( "tap", startGame )
	local okayText = display.newText( instructionGroup, "Okay!", myWidth / 2, myHeight - 70, native.systemFont, 16 )
	
end


------------------------- Start of Activity --------------------------------

-- Init the act
function act:init()
	-- Remember to put all display objects in act.group
	physics.start()
	physics.setGravity( 0, 0 )
	setBackgound()
	createFoodTarget()
	instructionBlock()

	act:enterFrame()
end

function act:enterFrame()

end	

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
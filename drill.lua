-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )


-- Declare access to game and act variables

game = globalGame
act = game.newAct()

-- Require statements

widget = require( "widget" )

-- Declare constants

local W = act.width
local H = act.height
local XC = act.xCenter
local YC = act.yCenter
local YMIN = act.yMin
YMAX = act.yMax


--Declare file local functions to be used
local initGame
local newFrame
local droppingBar
local risingBar
local timeLimit
local start
local finish
local reset

--Declare file local tables to be used
local bg -- Background image
local drillSpot -- Effectiveness of drill usage
local bar -- The bar being adjusted
local splashTop -- Splash subset for the start timer
local splashMiddle -- Splash subset for primary info bits
local splashBottom -- Splash subset for reset button
local startTimer -- Timer when beginning
local range -- Text for range user finished in
local waterText -- Displays how much water the user has earned
local resetButton -- The button that allows you to restart the game
local difficulty = {} -- Difficulty of drill game
local testText

function act:init()

	-- Setup the background
	bg = display.newRect( act.group, XC, YC, W, H )
	bg.fill = { type = "image", filename = "media/drill/DrillOp.jpg" }

	-- Create the worst range
	drillSpot = display.newRect( act.group, 0, YC, W / 8, H )
	drillSpot.anchorX = 0
	drillSpot.fill = { type = "image", filename = "media/drill/DrillSpot.png" }

	-- Create the bar
	bar = display.newRect( act.group, 0, YMAX, W / 7, H / 4 )
	bar.anchorX = 0
	bar.anchorY = 1
	bar.fill = { 0.36, 0.25, 0.13, 0.5 }
	bar.difference = H / 2 - bar.height

	-- Create the splash screen
	splash = display.newRoundedRect( act.group, XC, YC, 200, 400, 25 )
	splash.fill = { 0, 0, 0, .75 }
	splash.stroke = { 1, 0, 0 }

	-- Start timer function
	startInit = 5
	startTimer = display.newText( act.group, "Beginning in: " .. startInit, XC, YC - 100, native.systemFontBold, 25 )
	startTimer.count = startInit
	startTimer.fill = { 0, 0.42, 1 }
	startTimer.isVisible = false

	-- Create splash screen button

	local options =
	{
		width = 80,
		height = 40,
		numFrames = 2,
		sheetContentWidth = 160,
		sheetContentHeight = 40
	}

	local buttonSheet = graphics.newImageSheet( "media/drillScan/Button.png", options )

	resetButton = widget.newButton{ sheet = buttonSheet, defaultFrame = 1, overFrame = 2, label = "Restart", onPress = reset }

	resetButton.x = XC
	resetButton.y = YC + 140

	act.group:insert( resetButton )

	-- Intro screen
	game.drillPlayed = false

	-- Set difficulty
	if game.drillDiff then
		difficulty.drop = 0.5 + game.drillDiff * .4
		difficulty.rise = 13 + math.log( game.drillDiff )
	else
		difficulty.drop = 3
		difficulty.rise = 15
	end

	-- Intro screen
	game.drillPlayed = false

	if game.currentCost == nil and game.currentLiters == nil then

		game.currentCost = 11
		game.currentLiters = 50

	end

	-- Cost text
	costText = display.newText( act.group, "Cost: " ..  -game.currentCost + math.abs( math.floor( bar.difference / 10 ) ) .. " KWH", XC, YC, native.systemFont, 25 )
	costText.fill = { 0, 0.42, 1 }
	costText.xScale, costText.yScale = 0.01, 0.01
	costText.isVisible = false

	--Water Text
	waterText = display.newText( act.group, "Water: " .. game.currentLiters .. " Liters", XC, YC - 20, native.systemFont, 25 )
	waterText.fill = { 0, 0.42, 1 }
	waterText.xScale, waterText.yScale = 0.01, 0.01
	waterText.isVisible = false

end

function act:prepare()

	resetButton.isVisible = false
	game.playAmbientSound( "Engine.wav" )
	start()

end

function act:stop()

	game.stopAmbientSound()
	game.removeAct( "drill" )

end

function newFrame()
	
	droppingBar()
	bar.difference = H / 2 - bar.height
	costText.text = "Cost: " .. -game.currentCost + math.abs( math.floor( bar.difference / 10 ) ) .. " KWH"

end

function start()

	if startTimer.count > 0 then

		startTimer.isVisible = true
		startTimer.text = "Beginning in: " .. startTimer.count
		startTimer.count = startTimer.count - 1
		timer.performWithDelay( 1000, start )

	elseif startTimer.count == 0 then

		drillSound = act:loadSound( "Drill.wav" )
		game.playSound( drillSound )

		local function hideTimer()

			startTimer.isVisible = false

		end

		transition.to( startTimer, { time = 150, xScale = 0.01, yScale = 0.01, onComplete = hideTimer } )
		costText.isVisible = true
		transition.to( costText, { time = 150, xScale = 1, yScale = 1 } )
		Runtime:addEventListener( "touch", risingBar )
		Runtime:addEventListener( "enterFrame", newFrame )

		-- Time limit
		timer.performWithDelay( 5000, timeLimit )

	end

end

function reset()

	startTimer.count = 5
	Runtime:removeEventListener( "touch", risingBar )
	Runtime:removeEventListener( "enterFrame", newFrame )
	bar.height = H / 4
	costText.isVisible = false
	range.isVisible = false
	waterText.isVisible = false
	game.removeAct( "drillScan" )
	game.gotoAct( "drillScan", { effect = "zoomInOutFade", time = 333 } )

end

function droppingBar()

	if bar.height > 0 then
		bar.height = bar.height - difficulty.drop
	end
end

function risingBar( event )

	if event.phase == "began" then
		bar.height = bar.height + difficulty.rise
	end
end

function timeLimit()

	Runtime:removeEventListener( "enterFrame", newFrame )
	Runtime:removeEventListener( "touch", risingBar )

	local x = math.abs( bar.difference )
	range = display.newText( act.group, "", XC, YC + 20, native.systemFontBold, 25 )
	range.fill = { 0, 0.42, 1 }
	range.xScale, range.yScale = 0.01, 0.01
	transition.to( range, { time = 100, xScale = 1, yScale = 1 } )
	waterText.isVisible = true
	transition.to( waterText, { time = 100, xScale = 1, yScale = 1 } )


	if x <= 15 then
		range.text = "Ideal range"
	elseif x <= 70 then
		range.text = "Good range"
	elseif x <= 140 then
		range.text =  "Mediocre range"
	elseif x <= 183 then
		range.text =  "Bad range"
	elseif x <= 250 then
		range.text = "Horrible range"
	end

	local energyCost = math.floor( -x / 10 )

	local function resetVisible()

		resetButton.isVisible = true

	end

	game.addEnergy( energyCost )
	timer.performWithDelay( 1500, resetVisible )
end

return act.scene
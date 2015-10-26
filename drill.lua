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
local idealRange -- Ideal range for the bar
local goodRange -- Good range for the bar
local mediocreRange -- Mediocre range for the bar
local badRange -- Bad range for the bar
local horribleRange -- Horrible range for the bar
local bar -- The bar being adjusted
local splash -- Splash screen for when the player finishes
local startTimer -- Timer when beginning
local range -- Text for range user finished in
local resetButton -- The button that allows you to restart the game
local difficulty = {} -- Difficulty of drill game
local testText

function act:init()

	-- Setup the background
	bg = display.newRect( act.group, XC, YC, W, H )
	bg.fill = { type = "image", filename = "/media/drill/DrillOp.jpg" }

	-- Create the worst range
	horribleRange = display.newRect( act.group, 0, YC, W / 8, H )
	horribleRange.anchorX = 0
	horribleRange.fill = { type = "image", filename = "/media/drill/DrillSpot.png" }

	-- Create the bar
	bar = display.newRect( act.group, 0, H - 25, W / 7, H / 4 )
	bar.anchorX = 0
	bar.anchorY = 1
	bar.fill = { 0.36, 0.25, 0.13, 0.5 }

	-- Create the splash screen
	splash = display.newRoundedRect( act.group, XC, YC, 200, 400, 25 )
	splash.fill = { 0, 0, 0, .75 }
	splash.stroke = { 1, 0, 0 }

	-- Start timer function
	startInit = 5
	startTimer = display.newText( act.group, "Beginning in: " .. startInit, XC, YC - 100, native.systemFontBold, 25 )
	startTimer.count = startInit
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

	-- Set difficulty
	difficulty.drop = 3
	difficulty.rise = 18

	-- Intro screen
	game.drillPlayed = false

	-- Test text
	testText = display.newText( act.group, string.format( "%3.0f", math.abs( YC + 29 - bar.height ) ), XC, YC, native.systemFont, 25 )

end

function act:prepare()

	resetButton.isVisible = false

end

function act:start()

	start()

end

function newFrame()
	
	droppingBar()
	testText.text = string.format( "%3.0f", math.abs( YC + 29 - bar.height ) )
end

function start()

	if startTimer.count > 0 then

		startTimer.isVisible = true
		startTimer.text = "Beginning in: " .. startTimer.count
		startTimer.count = startTimer.count - 1
		timer.performWithDelay( 1000, start )

	elseif startTimer.count == 0 then

		startTimer.isVisible = false
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
	range.isVisible = false
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

	local x = math.abs( YC + 29 - bar.height )
	range = display.newText( act.group, "", XC, YC + 20, native.systemFontBold, 25 )

	if x <= 15 then
		range.text = "Ideal range"
	elseif x <= 62 then
		range.text = "Good range"
	elseif x <= 121 then
		range.text =  "Mediocre range"
	elseif x <= 183 then
		range.text =  "Bad range"
	elseif x <= 250 then
		range.text = "Horrible range"
	end

	game.addEnergy( -x/10 )
	resetButton.isVisible = true
end

return act.scene
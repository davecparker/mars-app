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
local difficulty = {} -- Difficulty of drill game
local testText

function act:init()

	-- Setup the background
	bg = display.newRect( act.group, XC, YC, W, H )
	bg.fill = { type = "image", filename = "/media/drill/DrillOp.jpg" }

	-- Create the worst range
	horribleRange = display.newRect( act.group, 0, YC, W / 8, H )
	horribleRange.anchorX = 0
	horribleRange.fill = { 0.67, 0, 0 }

	-- Create the second worst range
	badRange = display.newRect( act.group, 0, YC, W / 8,  3 * H / 4 )
	badRange.anchorX = 0
	badRange.fill = { 1, 0.43, 0 }

	-- Create the mediocre range
	mediocreRange = display.newRect( act.group, 0, YC, W / 8, H / 2 )
	mediocreRange.anchorX = 0
	mediocreRange.fill = { 1, 0.96, 0}

	-- Create the good range
	goodRange = display.newRect( act.group, 0, YC, W / 8, H / 4 )
	goodRange.anchorX = 0
	goodRange.fill = { 0, 0.83, 0 }

	-- Create the ideal range
	idealRange = display.newRect( act.group, 0, YC, W / 8, H / 16 )
	idealRange.anchorX = 0
	idealRange.fill = { 0.25, 0.95, 1 }

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

	local resetButton = widget.newButton{ sheet = buttonSheet, defaultFrame = 1, overFrame = 2, label = "Restart", onPress = reset }

	resetButton.x = XC
	resetButton.y = YC + 170

	act.group:insert( resetButton )

	-- Set difficulty
	difficulty.drop = 3
	difficulty.rise = 18

	-- Intro screen
	game.drillPlayed = false

	-- Test text
	testText = display.newText( act.group, string.format( "%3.0f", math.abs( YC + 29 - bar.height ) ), XC, YC, native.systemFont, 25 )

	-- Event listeners
	start()

end

function newFrame()
	
	droppingBar()
	testText.text = string.format( "%3.0f", math.abs( YC + 29 - bar.height ) )
end

function start()

	if startTimer.count > 0 then

		startTimer.text = "Beginning in: " .. startTimer.count
		startTimer.count = startTimer.count - 1
		timer.performWithDelay( 1000, start )

	elseif startTimer.count == 0 then

		startTimer.isVisible = false
		Runtime:addEventListener( "touch", risingBar )
		Runtime:addEventListener( "enterFrame", newFrame )

		-- Time limit
--		timer.performWithDelay( 5000, timeLimit )

	end

end

function reset()

	startTimer.count = 5
	startTimer.isVisible = true
	Runtime:removeEventListener( "touch", risingBar )
	Runtime:removeEventListener( "enterFrame", newFrame )
	bar.height = H / 4
	start()

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
	local text = display.newText( act.group, "", XC, YC + 20, native.systemFontBold, 25 )

	if x <= 15 then
		text.text = "Ideal range"
	elseif x <= 62 then
		text.text = "Good range"
	elseif x <= 121 then
		text.text =  "Mediocre range"
	elseif x <= 183 then
		text.text =  "Bad range"
	elseif x <= 250 then
		text.text = "Horrible range"
	end
end

return act.scene
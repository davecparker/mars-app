-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

-- Require statements

widget = require( "widget" )

-- Constant declaration

local H = display.contentHeight
local W = display.contentWidth
local XC = display.contentCenterX
local YC = display.contentCenterY

-- Declare access to game and act variables

local game = globalGame
local act = game.newAct()

-- Function declaration

local initGame
local scan
local scanActivate
local finishScan
local waterSpotStats
local transitionDrill
local backButton

-- Display group declaration

local textGroup

-- Variable declaration

local scanCircle
local marsSurface
local infoConsole
local scanConsole
local contText
local freezeText
local sizeText
local costText
local contamText
local freezeText
local litersText
local energyText

-- Array declaration

local waterSpot = {}

function act:init()

	marsSurface = act:newImage ( "MarsSurface.jpg", { width = W, height = H } )
	marsSurface.x, marsSurface.y = 3 * W / 4, 4 * H / 5
	marsSurface.anchorX = 1
	marsSurface.anchorY = 1

	for i = 1, 3 do
		waterSpot[i] = display.newCircle( act.group, math.random( 10, 3 * W / 4 - 10 ), math.random( 10, 4 * H / 5 - 10 ), 10 )
		waterSpot[i].fill = { 0, 0, 1, 0.5 }
		waterSpot[i].isVisible = false
		waterSpot[i].contamination = math.random( 0, 100 )
		waterSpot[i].frigidity = 100 - waterSpot[i].contamination
		waterSpot[i].liters = 50 + waterSpot[i].contamination * 2
		waterSpot[i].energyCost = waterSpot[i].contamination / 5 + waterSpot[i].frigidity / 10
	end

	scanCircle = display.newCircle( act.group, XC, YC, 50 )
	scanCircle.fill = { 0, 0.568, 1 }
	scanCircle.alpha = 0.001

	infoConsole = act:newImage( "Steel2.jpg", { width = 1024, height = 768 } )
	infoConsole.x, infoConsole.y = XC, 4 * H / 5
	infoConsole.anchorX = 0.5
	infoConsole.anchorY = 0

	scanConsole = act:newImage( "Steel.jpg", { width = W / 4, height = 1414 } )
	scanConsole.x, scanConsole.y = 3 * W / 4, 4 * H / 5
	scanConsole.anchorX = 0
	scanConsole.anchorY = 1

--	display.newImageRect( [parentGroup,], filename, [baseDir,], width, height )

	textGroup = display.newGroup( )
	textGroup.x = XC
	textGroup.y = YC + 170
	act.group:insert( textGroup )

	contamOrigin = 0
	contamText = display.newText( textGroup, contamOrigin .. "% Contaminated", -150, 0, native.systemFontBold, 17 )
	contamText.fill = { 0 }
	contamText.anchorX = 0

	freezeOrigin = 0
	freezeText = display.newText( textGroup, freezeOrigin .. "% Frozen", -150, 25, native.systemFontBold, 17 )
	freezeText.fill = { 0 }
	freezeText.anchorX = 0

	litersOrigin = 0
	litersText = display.newText( textGroup, litersOrigin .. " Liters", -150, 50, native.systemFontBold, 17 )
	litersText.fill = { 0 }
	litersText.anchorX = 0

	energyOrigin = 0
	energyText = display.newText( textGroup, "Energy Cost:  " .. energyOrigin .. " kWh", -150, 75, native.systemFontBold, 17 )
	energyText.fill = { 0 }
	energyText.anchorX = 0

	local options =
	{
		width = 80,
		height = 40,
		numFrames = 2,
		sheetContentWidth = 160,
		sheetContentHeight = 40
	}

	local buttonSheet = graphics.newImageSheet( "media/drillScan/Button.png", options )

	local scanButton = widget.newButton{ sheet = buttonSheet, defaultFrame = 1, overFrame = 2, label = "Scan", onPress = scanActivate }

	scanButton.anchorX = 1
	scanButton.x = W + 2
	scanButton.y = YC - 170

	local drillButton = widget.newButton{ sheet = buttonSheet, defaultFrame = 1, overFrame = 2, label = "Drill", onPress = transitionDrill }

	drillButton.anchorX = 1
	drillButton.x = W + 2
	drillButton.y = YC + 50

end

function scanActivate()

	marsSurface:addEventListener( "touch", scan )

end

function scan( event )

	if event.phase == "began" then

		scanCircle.x = event.x
		scanCircle.y = event.y
		transition.fadeIn( scanCircle, { time = 500, transition = easing.inOutBounce, onComplete = finishScan } )

	end

	return true

end

function finishScan()

	-- Make the scanner reveal the water spots

	for i = 1, 3 do

		if ( scanCircle.x - waterSpot[i].x ) ^ 2 + ( scanCircle.y - waterSpot[i].y ) ^ 2 <= ( 50 + 10 ) ^ 2 then

			if waterSpot[i].isVisible == false then

				waterSpot[i].isVisible = true
				waterSpot[i]:addEventListener( "touch", waterSpotStats )

			end

		end

	end

	transition.fadeOut( scanCircle, { time = 500, transition = easing.outInBounce, onComplete = marsSurface:removeEventListener( "touch", scan ) } )

end

function waterSpotStats( event )

	if event.phase == "began" then

		local t = event.target

		contamText.text = t.contamination .. "% Contaminated"
		freezeText.text = t.frigidity .. "% Frozen"
		litersText.text = t.liters .. " Liters"
		energyText.text = "Energy Cost: " .. string.format( "%2.0f", math.floor( t.energyCost ) ) .. " kWh"

--		print( t.contamination .. "% Contaminated, " .. t.frigidity .. "% Frozen, " .. t.liters .. " Liters" )

	end

	return true

end

function transitionDrill()

	-- Move game to Water Drilling game automatically. Will need to use Act transition

end

return act.scene
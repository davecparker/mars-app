-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

-- Require statements

widget = require( "widget" )

-- Declare access to game and act variables

local game = globalGame
local act = game.newAct()


-- Constant declaration

local W = act.width
local H = act.height
local XC = act.xCenter
local YC = act.yCenter
local YMIN = act.yMin
local XMIN = act.xMin

-- Function declaration

local initGame
local scan
local scanActivate
local finishScan
local waterSpotStats
local waterSpotStatsHide
local transitionDrill
local backButton
local chooseBg
local returnTrue
local infoGroupDismiss

-- Display group declaration

local textGroup
local infoGroup

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
local drillButton
local currentLiters = 0
local currentCost = 0
local scanDistance = 0
local numSpots = 0
game.drillDiff = 0

-- Array declaration

local waterSpot = {}

function act:init()

	-- Create Martian surface

	marsSurface = chooseBg()
	marsSurface.x, marsSurface.y = W, 4 * H / 5
	marsSurface.anchorX = 1
	marsSurface.anchorY = 1

	if scanDistance < 50 then

		numSpots = 15

	end

	-- Create the water spots

	for i = 1, numSpots do
		
		waterSpot[i] = display.newImage( act.group, "media/drillScan/WaterSpot.png", math.random( XMIN + 10, W - 10 ), math.random( YMIN + 10, ( H - 2 * H / 5 ) - 10 ), true )
		waterSpot[i].isVisible = false
		waterSpot[i].contamination = math.random( 0, 100 )
		waterSpot[i].frigidity = 100 - waterSpot[i].contamination
		waterSpot[i].liters = 50 + waterSpot[i].contamination * 2
		waterSpot[i].energyCost =  -( waterSpot[i].contamination / 5 + waterSpot[i].frigidity / 10 )
		waterSpot[i].group = display.newGroup( )
		waterSpot[i].group.x, waterSpot[i].group.y = waterSpot[i].x, waterSpot[i].y
		waterSpot[i].difficulty = ( ( waterSpot[i].contamination ^ 2 + waterSpot[i].frigidity ) ^ 0.5 ) * 0.1
		act.group:insert( waterSpot[i].group )

	end

	-- Create the water spots' info bubbles

	for i = 1, #waterSpot do

		waterSpot[i].infoBox = display.newRoundedRect( waterSpot[i].group, 0, 0, 70, 40, 10 )
		waterSpot[i].infoBox.fill = { 0, 0, 0, 0.5 }
		waterSpot[i].group.xScale = 0.1
		waterSpot[i].group.yScale = 0.1
		waterSpot[i].group.isVisible = false
		waterSpot[i].diffText = display.newText( waterSpot[i].group, "Level: " .. string.format( "%2.1f", waterSpot[i].difficulty ), 0, 0, native.systemFontBold, 14 )

	end

	for i = 1, #waterSpot do

		act.group:insert( waterSpot[i] )

	end

	for i = 1, #waterSpot do

		act.group:insert( waterSpot[i].group )

	end

	infoConsole = act:newImage( "Steel2.jpg", { width = 1024, height = 768 } )
	infoConsole.x, infoConsole.y = XC, H - 2 * H / 5
	infoConsole.anchorX = 0.5
	infoConsole.anchorY = 0

	textGroup = display.newGroup( )
	textGroup.x = XC
	textGroup.y = H - 1.8 * H / 5

	local contamOrigin = 0
	contamText = display.newText( textGroup, contamOrigin .. "% Contaminated", -150, 0, native.systemFont, 17 )
	contamText.fill = { 0 }
	contamText.anchorX = 0

	local freezeOrigin = 0
	freezeText = display.newText( textGroup, freezeOrigin .. "% Frozen", -150, 17, native.systemFont, 17 )
	freezeText.fill = { 0 }
	freezeText.anchorX = 0

	local litersOrigin = 0
	litersText = display.newText( textGroup, litersOrigin .. " Liters", -150, 34, native.systemFont, 17 )
	litersText.fill = { 0 }
	litersText.anchorX = 0

	local energyOrigin = 0
	energyText = display.newText( textGroup, "Energy Cost:  " .. energyOrigin .. " kWh", -150, 51, native.systemFont, 17 )
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

	drillButton = widget.newButton{ sheet = buttonSheet, defaultFrame = 1, overFrame = 2, label = "Drill", onPress = transitionDrill }

	drillButton.anchorX = 1
	drillButton.x = W - 10
	drillButton.y = H - 1.5 * H / 5
	drillButton.isVisible = false

	infoGroup = display.newGroup()
	infoGroup.x, infoGroup.y = XC, YC

	local infoScreen = display.newRect( infoGroup, 0, 0, W, H )
	infoScreen.fill = { 0, 0, 0, 0.7 }

	local infoText1 = display.newText( infoGroup, "Tap to scan the surface of mars", 0, -60, native.systemFont, 20 )
	local infoText1 = display.newText( infoGroup, "Tap water spots to select them", 0, -30, native.systemFont, 20 )
	local infoText1 = display.newText( infoGroup, "Level indicates difficulty from 1-10", 0, 0, native.systemFont, 20 )
	local infoText1 = display.newText( infoGroup, "Tap drill button to go to Drill activity", 0, 30, native.systemFont, 20 )
	local infoText1 = display.newText( infoGroup, "Tap this screen to dismiss it", 0, 60, native.systemFont, 20 )

	if game.drillDone then

		infoGroup.isVisible = false

	else

		infoGroup.isVisible = true

	end

	act.group:insert( drillButton )
	act.group:insert( textGroup )
	act.group:insert( infoGroup )

end

function act:prepare()

	marsSurface:addEventListener( "touch", scan )
	infoConsole:addEventListener( "touch", returnTrue )
	infoGroup:addEventListener( "touch", infoGroupDismiss )

end

function returnTrue(event)

	if event.phase == "began" then

		return true

	end

end

function infoGroupDismiss( event )

	if event.phase == "began" then

		infoGroup.isVisible = false
		game.drillDone = true

	end

	return true

end

function chooseBg()

	local p
	local rand = math.random( 10 )

	local function marsSurfacePick( file )

		return act:newImage( file, { width = W, height = H } )

	end

	if rand == 1 then

		p = marsSurfacePick( "Mars1.jpg" )

	elseif rand == 2 then

		p = marsSurfacePick( "Mars2.jpg" )

	elseif rand == 3 then

		p = marsSurfacePick( "Mars3.jpg" )

	elseif rand == 4 then

		p = marsSurfacePick( "Mars4.jpg" )

	elseif rand == 5 then

		p = marsSurfacePick( "Mars5.jpg" )

	elseif rand == 6 then

		p = marsSurfacePick( "Mars6.jpg" )

	elseif rand == 7 then

		p = marsSurfacePick( "Mars7.jpeg" )

	elseif rand == 8 then

		p = marsSurfacePick( "Mars8.jpg" )

	elseif rand == 9 then

		p = marsSurfacePick( "Mars9.png" )

	elseif rand == 10 then

		p = marsSurfacePick( "Mars10.jpg" )

	end

	return p

end

function scan( event )

	if event.phase == "began" then

		local scanCircle = display.newCircle( act.group, XC, YC, 50 )
		scanCircle.fill = { 0, 0.568, 1 }
		scanCircle.alpha = 0.001

		scanCircle.x = event.x
		scanCircle.y = event.y
		transition.fadeIn( scanCircle, { time = 500, transition = easing.inOutBounce, onComplete = finishScan } )

	end

	return true

end

function finishScan( obj )

	-- Make the scanner reveal the water spots

	for i = 1, #waterSpot do

		if ( obj.x - waterSpot[i].x ) ^ 2 + ( obj.y - waterSpot[i].y ) ^ 2 <= ( 50 + 10 ) ^ 2 then

			if waterSpot[i].isVisible == false then

				waterSpot[i].isVisible = true
				waterSpot[i]:addEventListener( "touch", waterSpotStats )

			end

		end

	end

	local function killObj( obj )

		obj:removeSelf()
		obj = nil

	end

	transition.fadeOut( obj, { time = 500, transition = easing.outInBounce, onComplete = killObj } )

end

function waterSpotStats( event )

	if event.phase == "began" then

		local t = event.target

		if t.group.isVisible == false then

			for i = 1, #waterSpot do

				if waterSpot[i] ~= t then

					transition.to( waterSpot[i].group, { time = 333, x = waterSpot[i].x, xScale = 0.001, yScale = 0.001, onComplete = hideGroup } )

				end

			end

			t.group.isVisible = true

			if t.x <= W - 90 then

				transition.to( t.group, { time = 333, x = t.x + 45, xScale = 1, yScale = 1 } )

			elseif t.x > W - 90 then

				transition.to( t.group, { time = 333, x = t.x - 45, xScale = 1, yScale = 1 } )

			end

			contamText.text = t.contamination .. "% Contaminated"
			freezeText.text = t.frigidity .. "% Frozen"
			litersText.text = t.liters .. " Liters"
			energyText.text = "Energy Cost: " .. string.format( "%2.0f", math.floor( -t.energyCost ) ) .. " kWh"

			drillButton.isVisible = true

			game.currentLiters = math.floor( t.liters )
			game.currentCost = math.floor( t.energyCost )
			game.drillDiff = t.difficulty

		elseif t.group.isVisible == true then

			transition.to( t.group, { time = 333, x = t.x, xScale = 0.001, yScale = 0.001, onComplete = hideGroup } )

			contamText.text = "0% Contaminated"
			freezeText.text = "0% Frozen"
			litersText.text = "0 Liters"
			energyText.text = "Energy Cost: 0 kWh"

			drillButton.isVisible = false

			game.currentLiters = 0
			game.currentCost = 0
			game.drillDiff = 0

		end

	end

	return true

end

function hideGroup( obj )

	obj.isVisible = false

end

function transitionDrill()

	-- 

	-- Move game to Water Drilling game automatically. Will need to use Act transition

	game.addWater( game.currentLiters )
	game.addEnergy( game.currentCost )

	game.gotoAct( "drill", { effect = "zoomInOutFade", time = 333 } )

end

return act.scene
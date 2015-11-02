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
local drillButton
local currentLiters = 0
local currentCost = 0

-- Array declaration

local waterSpot = {}

function act:init()

--	marsSurface = act:newImage ( "MarsSurface.jpg", { width = W, height = H } )
	marsSurface = chooseBg()
	marsSurface.x, marsSurface.y = W, 4 * H / 5
	marsSurface.anchorX = 1
	marsSurface.anchorY = 1

	-- Create the water spots

	for i = 1, 3 do
		
		waterSpot[i] = display.newImage( act.group, "media/drillScan/WaterSpot.png", math.random( 10, W - 10 ), math.random( 10, 4 * H / 5 - 10 ), true )
		waterSpot[i].isVisible = false
		waterSpot[i].contamination = math.random( 0, 100 )
		waterSpot[i].frigidity = 100 - waterSpot[i].contamination
		waterSpot[i].liters = 50 + waterSpot[i].contamination * 2
		waterSpot[i].energyCost =  -( waterSpot[i].contamination / 5 + waterSpot[i].frigidity / 10 )
		waterSpot[i].group = display.newGroup( )
		waterSpot[i].group.x, waterSpot[i].group.y = waterSpot[i].x, waterSpot[i].y
		act.group:insert( waterSpot[i].group )

	end

	-- Create the water spots' info bubbles

	for i = 1, 3 do

		waterSpot[i].infoBox = display.newRoundedRect( waterSpot[i].group, 0, 0, 60, 40, 10 )
		waterSpot[i].infoBox.fill = { 0, 0, 0, 0.5 }
		waterSpot[i].group.xScale = 0.1
		waterSpot[i].group.yScale = 0.1
		waterSpot[i].group.isVisible = false
	end

	scanCircle = display.newCircle( act.group, XC, YC, 50 )
	scanCircle.fill = { 0, 0.568, 1 }
	scanCircle.alpha = 0.001

	infoConsole = act:newImage( "Steel2.jpg", { width = 1024, height = 768 } )
	infoConsole.x, infoConsole.y = XC, H - 115
	infoConsole.anchorX = 0.5
	infoConsole.anchorY = 0

--[[	scanConsole = act:newImage( "Steel.jpg", { width = W / 4, height = 1414 } )
	scanConsole.x, scanConsole.y = 3 * W / 4, 4 * H / 5
	scanConsole.anchorX = 0
	scanConsole.anchorY = 1
]]
	textGroup = display.newGroup( )
	textGroup.x = XC
	textGroup.y = YC + 185

	contamOrigin = 0
	contamText = display.newText( textGroup, contamOrigin .. "% Contaminated", -150, 0, native.systemFont, 17 )
	contamText.fill = { 0 }
	contamText.anchorX = 0

	freezeOrigin = 0
	freezeText = display.newText( textGroup, freezeOrigin .. "% Frozen", -150, 17, native.systemFont, 17 )
	freezeText.fill = { 0 }
	freezeText.anchorX = 0

	litersOrigin = 0
	litersText = display.newText( textGroup, litersOrigin .. " Liters", -150, 34, native.systemFont, 17 )
	litersText.fill = { 0 }
	litersText.anchorX = 0

	energyOrigin = 0
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
	drillButton.x = W + 2
	drillButton.y = H - 50
--	drillButton.isVisible = false

	act.group:insert( drillButton )
	act.group:insert( textGroup )

end

function act:prepare()

	marsSurface:addEventListener( "touch", scan )

end

function act:stop()

	for i = 1, 3 do

		waterSpot[i]:removeSelf()

	end

--	act.group:insert( drillButton )

	marsSurface:removeEventListener( "touch", scan )

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

	transition.fadeOut( scanCircle, { time = 500, transition = easing.outInBounce } )

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

			transition.to( t.group, { time = 333, x = t.x + 40, xScale = 1, yScale = 1 } )

			contamText.text = t.contamination .. "% Contaminated"
			freezeText.text = t.frigidity .. "% Frozen"
			litersText.text = t.liters .. " Liters"
			energyText.text = "Energy Cost: " .. string.format( "%2.0f", math.floor( -t.energyCost ) ) .. " kWh"

			drillButton.isVisible = true

			currentLiters = t.liters
			currentCost = t.energyCost

		elseif t.group.isVisible == true then

			transition.to( t.group, { time = 333, x = t.x, xScale = 0.001, yScale = 0.001, onComplete = hideGroup } )

			contamText.text = "0% Contaminated"
			freezeText.text = "0% Frozen"
			litersText.text = "0 Liters"
			energyText.text = "Energy Cost: 0 kWh"

			drillButton.isVisible = false

			currentLiters = 0
			currentCost = 0

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

	game.addWater( currentLiters )
	game.addEnergy( currentCost )

	game.gotoAct( "drill", { effect = "zoomInOutFade", time = 333 } )

end

return act.scene
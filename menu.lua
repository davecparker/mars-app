-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-- The menu view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()

-- Shortcut access to game's saved state
local ss = game.saveState

-- File local variables
local soundSwitch
local volumeControls   -- display group with volume controls
local fxSlider
local bgSlider

------------------------- Start of Activity --------------------------------

-- Set the sound option on or off
local function enableSound( on )
	ss.soundOn = on
	volumeControls.isVisible = on
	if on then
		game.playAmbientSound()
	else
		game.stopAmbientSound()
	end
end

-- FX volume slider listener
local function fxSliderListener( event )
    ss.fxVolume = event.value / 100
end

-- FX volume slider listener
local function bgSliderListener( event )
    ss.ambientVolume = event.value / 100
	game.playAmbientSound()  -- adjust volume of sound already playing
end

-- Make a new text label
local function newLabel( group, text, x, y )
	local label = display.newText( group, text, x, y, native.systemFont, 18 )
	label.anchorX = 0
	label:setFillColor( 0 )
	return label
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:whiteBackground()
	act:makeTitleBar( "Settings" )

	-- Sound on/off switch and label
	local ySwitch = act.yMin + act.dyTitleBar * 2
	newLabel( act.group, "Sound", act.xMin + 60, ySwitch )
	soundSwitch = widget.newSwitch{
		x = act.xMin + 30,
		y = ySwitch,
		style = "checkbox",
		onRelease = 
			function ( event )
				enableSound( event.target.isOn )
			end
	}
	act.group:insert( soundSwitch )

	-- Sound effect slider
	volumeControls = act:newGroup()
	local xSlider = act.xCenter + act.width / 4
	local dxSlider = act.width * 0.4
	fxSlider = widget.newSlider{ 
		x = xSlider,
		y = act.yMin + act.dyTitleBar * 3,
		width = dxSlider,
		listener = fxSliderListener, 
	}
	volumeControls:insert( fxSlider )
	newLabel( volumeControls, "Effects", act.xMin + 30, fxSlider.y ) 
	
	-- Background volume slider
	bgSlider = widget.newSlider{ 
		x = xSlider,
		y = act.yMin + act.dyTitleBar * 4,
		width = dxSlider, 
		listener = bgSliderListener, 
	}
	volumeControls:insert( bgSlider )
	newLabel( volumeControls, "Background", act.xMin + 30, bgSlider.y )

	-- Debug menu button
	local button = widget.newButton{
		x = act.xCenter,
		y = act.yMax - 100,
		label = "Debug Menu",
		onRelease = 
			function ()
				game.gotoScene( "debugMenu" )
			end
	}
	act.group:insert( button )
end

-- Prepare the act
function act:prepare()
	soundSwitch:setState( { isOn = ss.soundOn } )
	enableSound( ss.soundOn )
	fxSlider:setValue( ss.fxVolume * 100 )
	bgSlider:setValue( ss.ambientVolume * 100 )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

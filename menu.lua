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

------------------------- Start of Activity --------------------------------

-- Set the sound option on or off
local function setSound( on )
	ss.soundOn = on
	if on then
		game.playAmbientSound( "Ship Ambience.mp3" )
	else
		game.playAmbientSound( nil )
	end
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:whiteBackground()
	act:makeTitleBar( "Settings" )

	-- Sound on/off switch and label
	local ySwitch = act.yMin + act.dyTitleBar * 2
	local label = display.newText( act.group, "Sound", act.xMin + 60, ySwitch, 
						native.systemFont, 18 )
	label.anchorX = 0
	label:setFillColor( 0 )
	soundSwitch = widget.newSwitch{
		x = act.xMin + 30,
		y = ySwitch,
		style = "checkbox",
		onRelease = 
			function ( event )
				setSound( event.target.isOn )
			end
	}
	act.group:insert( soundSwitch )

	-- Debug menu button
	local button = widget.newButton{
		x = act.xCenter,
		y = act.yMax - 30,
		label = "Debug Menu",
		onRelease = 
			function ()
				game.gotoAct( "debugMenu" )
			end
	}
	act.group:insert( button )
end

-- Prepare the act
function act:prepare()
	soundSwitch:setState( { isOn = ss.soundOn } )
	setSound( ss.soundOn )
end

-- Stop the act
function act:stop()
	game.playAmbientSound( nil )
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

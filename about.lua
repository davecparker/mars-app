-----------------------------------------------------------------------------------------
--
-- about.lua
--
-- The About (credits) screen for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()

-- File local variables
local box      -- container for text credits
local text     -- the multi-line text credits

-- The credits text (multi-line)
local creditsText = 
[[Mars App is a student project from
the Computer Science department at
Sierra College in Rocklin, California

Programming:
Ryan Bains-Jordan
Joe Cracchiolo
Mike Friebel
Cord Lamphere
Dave Parker
Matt Tourone

Art:
Joe Cracchiolo
Dani Joy Grimes

Sound:
Erik Danielson

Writing:
Cody Spjut
Jennifer Trovato]]


-- Handle press of the back button
local function onBackButton()
	game.gotoScene( "menu", { effect = "slideRight", time = 200 } )
end


-- Init the act
function act:init()
	-- Background and title bar for the view
	act:grayBackground( 0.2 )
	act:makeTitleBar( "About", onBackButton )

	-- Container for text to scroll if necessary
	box = display.newContainer( act.group, act.width, act.height - act.dyTitleBar - 2 )
	box.x = act.xCenter
	box.y = act.yCenter + act.dyTitleBar / 2

	-- Credits text
	text = display.newText{
		parent = box,
		x = 0,
		y = 0,
		width = act.width * 0.8,
		height = 0,   -- auto size
		fontSize = 14,
		align = "center",
		text = creditsText,
	}
	text.anchorY = 0  -- top center starts at act center
end

-- Prepare the act
function act:prepare()
	text.y = 0   -- start the beginning of text in the center of the act
end

-- Scroll the text slowly upwards each frame
function act:enterFrame()
	text.y = text.y - 1
	if text.y < -(box.height / 2 + text.height) then
		text.y = box.height / 2  -- wrap just off the bottom when it goes just off the top
	end
end

-- Corona needs the scene object returned from the act file
return act.scene

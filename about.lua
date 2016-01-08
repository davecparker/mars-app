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
local clipBox       -- clipping container for the credits
local creditsGroup  -- display group containing scrolling credits
local creditsText   -- multi-line text object for credits

-- The credits string (multi-line)
local creditsString = 
[[Mars Explorer is a student project from
the Computer Science department at
Sierra College in Rocklin, California

Programming:
Ryan Bains-Jordan
Joe Cracchiolo
Mike Friebel
Cord Lamphere
Dave Parker
Matt Taurone

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

	-- Clipping container for credits to scroll inside
	clipBox = display.newContainer( act.group, act.width, act.height - act.dyTitleBar - 2 )
	clipBox.x = act.xCenter
	clipBox.y = act.yCenter + act.dyTitleBar / 2

	-- Credits display group inside the box container
	creditsGroup = act:newGroup( clipBox )

	-- Game title
	local title = display.newText{
		parent = creditsGroup,
		x = 0,
		y = 0,
		font = native.systemFontBold,
		fontSize = 32,
		align = "center",
		text = "Mars Explorer",
	}
	title.anchorY = 0

		-- Credits text
	creditsText = display.newText{
		parent = creditsGroup,
		x = 0,
		y = 60,
		width = act.width * 0.8,
		height = 0,   -- auto size
		fontSize = 14,
		align = "center",
		text = creditsString,
	}
	creditsText.anchorY = 0  -- top center starts at act center
end

-- Prepare the act
function act:prepare()
	creditsGroup.y = 0   -- start the beginning of text in the center of the act
end

-- Scroll the text slowly upwards each frame
function act:enterFrame()
	-- Scroll credits upward
	creditsGroup.y = creditsGroup.y - 1

	-- Wrap just off the bottom when it goes just off the top
	local yBottom = creditsText.y + creditsText.height
	if creditsGroup.y < -(clipBox.height / 2 + yBottom) then
		creditsGroup.y = clipBox.height / 2
	end
end

-- Corona needs the scene object returned from the act file
return act.scene

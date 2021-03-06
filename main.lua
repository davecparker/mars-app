-----------------------------------------------------------------------------------------
--
-- main.lua
--
-- This is the main (starting) source file for the Mars App game project.
-- (c) Copyright 2015 by Sierra College
-----------------------------------------------------------------------------------------

--[[------------------------- Programmer Documentation ----------------------------------

-- Utility functions in game.lua:
game.pinValue( value, min, max )      -- Constrain a value to a range
game.xyInRect( x, y, rect )           -- test if point is in rect
game.xyHitTest( x1, y1, x2, y2, dxy ) -- x, y hit test
game.eatTouch()                       -- return true to eat touch or tap event
game.removeObj( obj )                 -- remove a display object
game.emptyFunction()                  -- do nothing

-- Resource functions in game.lua:
game.water()                          -- return current water amount
game.energy()                         -- return current energy amount
game.food()                           -- return current food amount
game.addWater( liters )               -- Add or subtract water
game.addEnergy( kWh )                 -- Add or subtract energy
game.addFood( kg )                    -- Add or subtract food

-- Game control functions in gameState.lua:
game.updateState()                    -- update game state (periodic or forced)

-- User-Interface functions in game.lua:
game.showHint( text, title, onExit )  -- display help text in popup
game.floatMessage( text, x, y )       -- Display floating fade-away message
game.messageBox( text, options )      -- Display message box
game.endMessageBox()                  -- Dismiss active message box if any

-- Sound functions in game.lua:
game.playSound( sound, options )      -- Play sound effect, returns channel
game.stopSound( channel )             -- Stop sound effect 
game.disposeSound( sound )            -- Dispose of loaded sound
game.playAmbientSound( filename )     -- Play background sound/music
game.stopAmbientSound()               -- Stop background sound/music

-- User-Interface functions in tabBar.lua:
game.createBadge( x, y )              -- Create a new item indicator badge
game.showBadge( badge )               -- show an indicator badge
game.hideBadge( badge )               -- hide an indicator badge
game.showMessagePreview( text )       -- Show preview of message text
game.hideMessagePreview()             -- Hide message preview if showing
game.gotoTab( name, press )           -- Go to game tab name

-- Game functions in mainAct.lua:
game.roomName()                       -- Name of room user is in or nil if none
game.roomEntered( roomName )          -- true if the user has entered the room name
game.landShip()                       -- Update ship state for after landing on Mars

-- Game functions in messages.lua:
game.sendMessage( id )                -- Add message to messages view
game.sendMessages( id1, id2, ... )    -- Add multiple messages to messages view

-- Game functions in documents.lua:
game.foundDocument( baseName, ext )   -- Add document to user's list of found docs

-- Activity functions in Act.lua
game.gotoScene( scene, options )      -- Go directly to a scene (see composer.gotoScene)
game.gotoAct( name, options )         -- Run a given activity
game.removeAct( name )                -- Remove an activity from memory
game.newAct()                         -- Create a new activity
game.currentActName()                 -- Name of current act 

-- Variables in the act table you can use:
act.width    -- width of the activiy area 
act.height   -- height of the activity area 
act.xMin     -- left edge of the activity area
act.xMax     -- right edge of the activity area
act.yMin     -- top edge of the activity area
act.yMax     -- bottom edge of the activity area
act.xCenter  -- x center of the activity area 
act.yCenter  -- y center of the activity area
act.group    -- display group for the act (parent of all display objects)
act.scene    -- composer scene associated with the act
act.name     -- act module name

-- Methods in the act table you can use (see Act.lua for details):
act:newImage( filename, options )        -- make a new imageRect display object
act:newText( text, x, y, fontSize )      -- make a new text display object
act:newGroup( parent )                   -- make a new display (sub-)group
act:whiteBackground()                    -- make a solid white background
act:grayBackground( gray )               -- make a solid grayscale background
act:makeTitleBar( title, backListener )  -- make standard title bar with optional back
act:loadSound( filename, folder )        -- load sound file (folder defaults to act media)

-----------------------------------------------------------------------------------------
How to define an activity:
   * Create a Lua file named with the name of your activity in the main project folder.
   * Start with the code in blank.act as an initial template.
   * Add your activity name to the debugActs array in debugMenu.lua.
   * Create your display objects in act:init() and put them all in act.group.
   * If you define act:prepare() it will be called before the transition into the act.
   * If you define act:start() it will be called when the activity starts/resumes.
   * If you define act:stop() it will be called when the activity suspends/ends.
   * If you define act:destroy() it will be called when the activity is destroyed.
   * If you define act:enterFrame() it will be called before every animation frame.
   * Store your graphics and other media in media/yourActName (See act:newImage())

-----------------------------------------------------------------------------------------
Some activity rules and hints:
   * Do not add Runtime enterFrame listeners. Define act:enterFrame() instead. 
   * Do not use Runtime tap/touch listeners. Attach them to display objects (background?).
   * Do not use global variables. Use (file) local myVar, game.myVar, or act.myVar.
-----------------------------------------------------------------------------------------

--]]-------------------------------------------------------------------------------------


-- Create the global game object. This should be the only global variable in the app.
globalGame = require( "game" )
local game = globalGame

-- load required Corona modules
local json = require( "json" )

-- Load required game modules
require( "Act" )
require( "tabBar" )
require( "documents" )
require( "messages" )
require( "gameState" )


-- Return the path name for the user data file where the game state is saved
local function dataFilePath()
	return system.pathForFile( "gameState.txt", system.DocumentsDirectory )
end

-- Save the game state to a file
local function saveGameState()
	local file = io.open( dataFilePath(), "w" )
	if file then
		local str = json.encode( game.saveState )
		if str then
			--print(str)
			file:write( str )
		end
		io.close( file )
	end
end

-- Load the game state from its file
local function loadGameState()
	local file = io.open( dataFilePath(), "r" )
	if file then
		local str = file:read( "*a" )	-- Read entire file as a string (JSON encoded)
		if str then
			local saveState = json.decode( str )
			if saveState then
				game.saveState = saveState
			end
		end
		io.close( file )
	end
end

-- Handle system events for the app
local function onSystemEvent( event )
	if event.type == "applicationSuspend" or event.type == "applicationExit" then
		saveGameState()
	end
end

-- Init the game
local function initGame()
	-- Listen for system events
	Runtime:addEventListener( "system", onSystemEvent )

	-- Load the saved game state, if any
	--loadGameState()   -- TODO: Enable at some point

    -- Start the repeating game state update timer
	game.stateStartTime = system.getTimer()
    timer.performWithDelay( 1000, game.updateState, 0 )  -- repeat every second

	-- Start in the main view
	game.gotoAct( "mainAct" )
end

-- Start the game
initGame()


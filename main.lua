-----------------------------------------------------------------------------------------
--
-- main.lua
--
-- This is the main (starting) source file for the Mars App game project.
-- (c) Copyright 2015 by Sierra College
-----------------------------------------------------------------------------------------

--[[------------------------- Programmer Documentation ----------------------------------

-- Game functions defined in game.lua:
game.pinValue( value, min, max )      -- Constrain a value to a range

-- Game functions defined in Act.lua
game.gotoAct( name, options )         -- Run a given activity/view
game.removeAct( name )                -- Remove an activity from memory
game.newAct()                         -- Create a new activity

-- Game functions defined in tabBar.lua:
game.selectGameTab( index, press )    -- Select one of the tab bar tabs
game.createBadge( x, y )              -- Create a new item indicator badge
game.showBadge( badge )               -- show an indicator badge
game.hideBadge( badge )               -- hide an indicator badge

-- Game functions defined in messages.lua:
game.sendMessage( id )                -- Add message to messages view
game.sendMessages( id1, id2, ... )    -- Add multiple messages to messages view

-- Game functions defined in documents.lua:
game.foundDocument( filename )        -- Add document to user's list of found docs

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
act:newImage( filename, options )    -- make a new imageRect display object
act:newGroup( parent )               -- make a new display (sub-)group
act:makeTitleBar( title )            -- make standard view background and title bar

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
function initGame()
	-- Listen for system events
	Runtime:addEventListener( "system", onSystemEvent )

	-- Load the saved game state, if any
	--loadGameState()   -- TODO: Enable at some point
	
	-- Start with some messages (TODO: temporary)
	game.sendMessage( "wake1" )
	game.sendMessage( "wake2" )
	game.sendMessages( "spin1", "spin2" )
end

-- Start the game
initGame()

-- Start in the debug menu view for now
game.gotoAct( "debugMenu" )

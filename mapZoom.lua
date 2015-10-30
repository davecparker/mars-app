-----------------------------------------------------------------------------------------
--
-- mapZoom.lua
--
-- The zoomed map view (e.g. single room) for the Mars App
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Load Corona modules needed
local json = require( "json" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- File local variables
local titleBar    -- title bar for the view
local mapImage    -- background map image
local icons       -- display group for map icons


-- Handle taps on a map icon
local function tappedIcon( icon, event )
	-- What kind of icon is this?
	print( icon.name )
	if icon.t == "act" then
		-- Run the named activity (TODO: parameters?)
		game.gotoAct( icon.name )
	elseif icon.t == "doc" then
		-- Add the document to the inventory
		game.foundDocument( icon.name )
	end
	return true
end

-- Create and return a new icon with the given data table
local function newIcon( data )
	local icon = act:newMapIcon( icons, data )
	if icon then
		-- Add the touch listener
		icon.tap = tappedIcon
		icon:addEventListener( "tap", icon )
	end
	return icon
end

-- Return the path to the data file for the current map name
local function mapDataPath()
	return system.pathForFile( "media/mapZoom/" .. game.mapZoomName .. ".txt", 
			system.ResourceDirectory )
end

-- Load the map data file for the current map, 
-- or use empty data if file not found.
local function loadMapData()
	-- Load the data file if found
	local mapData = {}  -- use empty if data file not found
	local path = mapDataPath()
	if path then
		local file = io.open( path, "r" )
		if file then
			local str = file:read( "*a" )	-- Read entire file as a string (JSON encoded)
			if str then
				local data = json.decode( str )
				if data then
					mapData = data
				end
			end
			io.close( file )
		end
	end

	-- Create the icons from the data records
	for i = 1, #mapData do
		newIcon( mapData[i] )
	end
end

-- Init the act
function act:init()
	-- Everything is created in act:prepare() because it can change each view
end

-- Handle tap on the back button
local function backTapped()
	-- Go back to overall map view
	game.mapZoomName = nil
	game.gotoAct( "mainAct", { effect = "crossFade", time = 250 } )
	return true
end

-- Prepare the act by loading the current map view
function act:prepare()
	-- We should be called with the map name already set
	assert( type( game.mapZoomName ) == "string" )

	-- Create background map image
	local imageOptions = 
	{ 
		width = act.width,
		x = act.xCenter,
		y =  act.yCenter + act.dyTitleBar / 2
	}
	if mapImage then
		mapImage:removeSelf()   -- remove previous image if any
	end
	mapImage = act:newImage( game.mapZoomName .. ".png", imageOptions )
	if not mapImage then
		mapImage = act:newImage( game.mapZoomName .. ".jpg", imageOptions )
	end

	-- Create display group for map icons centered on the map image
	if icons then
		icons:removeSelf()   -- remove previous icons group if any
	end
	icons = act:newGroup()
	icons.x = mapImage.x
	icons.y = mapImage.y

	-- Load the data file for this map
	if mapImage then
		loadMapData()
	end

	-- Title bar with the map name on top
	if titleBar then
		titleBar:removeSelf()   -- remove previous title bar if any
	end
	titleBar = act:makeTitleBar( game.mapZoomName, backTapped )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

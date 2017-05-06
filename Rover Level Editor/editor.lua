-----------------------------------------------------------------------------------------
--
-- editor.lua
--
-----------------------------------------------------------------------------------------

-- include the Corona "composer" module
local composer = require "composer"
local scene = composer.newScene()
local json = require( "json" )

--------------------------------------------

-- Get the screen metrics
local WIDTH = display.actualContentWidth 
local HEIGHT = display.actualContentHeight 
local xMin = display.screenOriginX 
local yMin = display.screenOriginY 
local xMax = xMin + WIDTH 
local yMax = yMin + HEIGHT 
local xCenter = (xMin + xMax) / 2 
local yCenter = (yMin + yMax) / 2

-- local declarations
local level = display.newGroup()
local toolbar = display.newGroup()
local currentTool

local toolList = {} -- contains each tool's icon and action
local objList = {} -- contains each objects location in relation to the level

-- add necessary information to use the new tool
local function newTool( file, func )
	toolList[#toolList + 1] = {icon = file, action = func}
end

-- switches to the new tool
local function changeTool( tool )
	currentTool = tool
end

------------------------ TOOL LISTENERS --------------------------------

-- draws a circle whereever the mouse clicks
local function drawCircle(event)
	if event.y < 320 then
		local c = display.newCircle( level, event.x - level.x, event.y, 20 )
		c.shape = "circle"
		c:setFillColor( 0 )
	end
end

-- draws the app icon but the fill color is set to 0 so it looks like a black square
local function drawIcon(event)
	if event.y < 320 then
		local c = display.newImageRect( level, "Icon.png", 60, 60 )
		c.x, c.y = event.x - level.x, event.y
		c.shape = "square"
		c:setFillColor( 0 )
	end
end

-- writes the level to outfile.txt
local function outputLevel( event )
	-- empty the previous obj list otherwise the list will have duplicate items
	objList = {}

	-- store the object locations relative to the level in objList
	for i = 1, level.numChildren do
		local child = level[i]
		objList[#objList+1] = {x = child.x, y = child.y, shape = child.shape}
	end
	print( json.prettify( objList ) )
	
	local path = system.pathForFile( "outfile.txt", system.DocumentsDirectory )
	local file = io.open( path, "w" )

	if file then
		file:write( json.prettify( objList ) )
		io.close( file )
	end

	print( "file saved in: " .. path )
end

-- loads the file from infile.txt
local function inputLevel( event )
	-- empty the previous obj list otherwise the list will have duplicate items
	objList = {}

	local path = system.pathForFile( "infile.txt", system.DocumentsDirectory )
	local file = io.open( path, "r" )

	if file then
		local str = file:read( "*a" )	-- Read entile file as a string (JSON encoded)
		if str then
			objList = json.decode( str )
			for i = 1, objList.numChildren do
				local child = objList[i] 
				if child.shape == "circle" then
					drawCircle(child) 
				elseif child.shape == "square" then
					drawIcon(child)
				end
			end
		end
		io.close( file )
	end

	print( "file loaded from: " .. path )
end

-- populates toolbar with all the tools
local function drawToolbar( )
	local x = 0
	for i = 1, #toolList do
		local o = display.newImageRect(toolbar, toolList[i].icon, 60, 60 )
		o.x, o.y = 35+x, 30
		x = x + 60
		o:addEventListener( "tap", function() changeTool(toolList[i]);end )
	end
end

-- moves the level display whenever the user clicks and drags.
function levelTouch( event )
	level.xStart = event.phase == "began" and level.x or level.xStart
	level.x = event.phase == "moved" and level.xStart + event.x - event.xStart or level.x
end

-- uses action of the current tool
local function useTool( event )
	if currentTool == nil then
		return -1;
	end
	currentTool.action(event)
end

function scene:create( event )
	-- sets background to some awful color
	display.setDefault( "background", 1, 0.85, 0.6 )

	-- defines level attributes
	level.length = 480 * 3
	level.height = 320 * 2
	level.objects = {}
	level.floor = 70

	-- draws the toolbar
	toolbar.anchorX = 0
	toolbar.anchorY = 0
	toolbar.x = xMin
	toolbar.y = yMax - 60
	toolbar.bg = display.newRect( toolbar, WIDTH / 2, 30, WIDTH, 60 )


	--  █████╗ ██████╗ ██████╗     ███╗   ██╗███████╗██╗    ██╗                       
	-- ██╔══██╗██╔══██╗██╔══██╗    ████╗  ██║██╔════╝██║    ██║                       
	-- ███████║██║  ██║██║  ██║    ██╔██╗ ██║█████╗  ██║ █╗ ██║                       
	-- ██╔══██║██║  ██║██║  ██║    ██║╚██╗██║██╔══╝  ██║███╗██║                       
	-- ██║  ██║██████╔╝██████╔╝    ██║ ╚████║███████╗╚███╔███╔╝                       
	-- ╚═╝  ╚═╝╚═════╝ ╚═════╝     ╚═╝  ╚═══╝╚══════╝ ╚══╝╚══╝                        
	                                                                               
	-- ████████╗ ██████╗  ██████╗ ██╗     ███████╗    ██╗  ██╗███████╗██████╗ ███████╗
	-- ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝    ██║  ██║██╔════╝██╔══██╗██╔════╝
	--    ██║   ██║   ██║██║   ██║██║     ███████╗    ███████║█████╗  ██████╔╝█████╗  
	--    ██║   ██║   ██║██║   ██║██║     ╚════██║    ██╔══██║██╔══╝  ██╔══██╗██╔══╝  
	--    ██║   ╚██████╔╝╚██████╔╝███████╗███████║    ██║  ██║███████╗██║  ██║███████╗
	--    ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝
	-- add tools in the format of toolbar.toolName = newTool("icon for the tool", function that will be called when the screen is touched)
	toolbar.circleTool = newTool("circle.png", drawCircle)
	toolbar.iconTool = newTool("Icon.png", drawIcon)
	toolbar.saveTool = newTool("save.png", outputLevel)
	-- toolbar.loadTool = newTool("load.png", inputLevel) dont use cuz it's broken

	-- adds tools to a tool bar
	drawToolbar()

	-- Listener setup
	Runtime:addEventListener( "tap", useTool )
	Runtime:addEventListener("touch", levelTouch)
end

-- needed to make composer work but not really needed
function scene:show( event )
end
function scene:hide( event )
end
function scene:destroy( event )
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene
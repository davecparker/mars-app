-----------------------------------------------------------------------------------------
--
-- debugMenu.lua
--
-- The debug menu view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


-- List of activities that can be run directly from the debug menu
local debugActs = {
	"mainAct",
	"thrustNav",
	"doorLock",
	"circuit",
	"wireCut",
	"greenhouse",
	"drillScan",
	"drill",
	"rover",
	"shipLanding",
	"blankAct",
	"layoutTool",
	"sampleAct",
}

-- File local variables
local res = game.saveState.resources
local waterEdit
local foodEdit
local energyEdit
local xLabel = act.xCenter
local xEdit = act.xMax - 60
local dyLine = act.dyTitleBar
local yEditFirst = act.yMin + dyLine * 4.5


-- Draw a row in the tableView
local function onRowRender( event )
    -- Get row info
    local row = event.row
    local dxRow = row.contentWidth
    local dyRow = row.contentHeight

    -- Display the text
    local rowTitle = display.newText( row, debugActs[row.index], 0, 0, native.systemFontBold, 18 )
    rowTitle:setFillColor( 0 )     -- black text
    rowTitle.anchorX = 0           -- left aligned
    rowTitle.x = 15
    rowTitle.y = dyRow * 0.5       -- vertically centered
end

-- Handle touch on a row
function onRowTouch( event )
	if event.phase == "tap" or event.phase == "release" then
		-- Run the selected activity module on the main tab
		game.gotoTab( "mainAct" )
		game.gotoAct( debugActs[event.target.index] )  
	end
end

-- Handle press of the back button
local function onBackButton()
	game.gotoScene( "menu", { effect = "slideRight", time = 200 } )
end

-- Create a UI label in the act
local function newLabel( text, x, y )
	local label = display.newText( act.group, text, x, y, native.systemFont, 18 )
	label.anchorX = 0
	label:setFillColor( 0 )
	return label
end

-- Create a new textEdit in the act
local function newNumberEdit( x, y, value, listener )
	local edit = native.newTextField( x, y, 70, 30 )
	edit.inputType = "number"
	edit.text = tostring( value )
	edit:addEventListener( "userInput", listener )
	act.group:insert( edit )
	return edit
end

-- Create a new on/off switch in the act
local function newSwitch( x, y, listener )
	local switch = widget.newSwitch{ x = x, y = y, onRelease = listener }
	act.group:insert( switch )
	return switch
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:grayBackground()
	act:makeTitleBar( "Debug Menu", onBackButton )

	-- Position for controls and labels
	local y = act.yMin + act.dyTitleBar * 1.5

	-- Cheat mode switch and label
	newLabel( "Cheat", xLabel , y )
	newSwitch( act.xMax - 45, y,
		function ( event )
			game.cheatMode = event.target.isOn
		end )

	-- All Gems mode switch and label
	y = y + dyLine
	newLabel( "All Gems", xLabel , y )
	newSwitch( act.xMax - 45, y,
		function ( event )
			game.allGems = event.target.isOn
		end )

	-- Resource edit labels
	y = yEditFirst
	newLabel( "Water", xLabel, y )
	y = y + dyLine
	newLabel( "Food", xLabel, y )
	y = y + dyLine
	newLabel( "Energy", xLabel, y )

	-- Create the tableView widget to list the debug activities
	local tableView = widget.newTableView
	{
	    left = act.xMin,
	    top = act.yMin + act.dyTitleBar,
	    height = act.height - act.dyTitleBar,
	    width = act.width * 0.45,
	    onRowRender = onRowRender,
	    onRowTouch = onRowTouch,
	}
	act.group:insert( tableView )

	-- Insert the rows
	for i = 1, #debugActs do
	    tableView:insertRow{}
	end
end

-- Prepare the act
function act:prepare()
	-- Create the resource text edits
	local y = yEditFirst
	waterEdit = newNumberEdit( xEdit, y, res.h2o,
		function ( event )
			res.h2o = tonumber( event.target.text ) or 0
		end )
	y = y + dyLine
	foodEdit = newNumberEdit( xEdit, y, res.food,
		function ( event )
			res.food = tonumber( event.target.text ) or 0
		end )
	y = y + dyLine
	energyEdit = newNumberEdit( xEdit, y, res.kWh,
		function ( event )
			res.kWh = tonumber( event.target.text ) or 0
		end )
end

-- Stop the act
function act:stop()
	-- Destroy the resource text edits
	if waterEdit then
		waterEdit:removeSelf()
		waterEdit = nil
	end
	if foodEdit then
		foodEdit:removeSelf()
		foodEdit = nil
	end
	if energyEdit then
		energyEdit:removeSelf()
		energyEdit = nil
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

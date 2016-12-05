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
	"scottAct",
	"startScreen",
	"mainAct",
	"thrustNav",
	"doorLock",
	"cipher",
	"hack",
	"circuit",
	"wireCut",
	"greenhouse",
	"drillScan",
	"drill",
	"rover",
	"shipLanding",
	"stasis",
	"spaceWalk",
	"blankAct",
	"sampleAct",
	"layoutTool",
	"about",
}

-- File local variables
local ss = game.saveState
local res = ss.resources
local waterEdit
local foodEdit
local energyEdit
local stateEdit
local xLabel = act.xCenter
local xEdit = act.xMax - 60
local dyLine = act.dyTitleBar
local yEditFirst = act.yMin + dyLine * 1.5


-- Hide the keyboard
local function hideKeyboard()
	native.setKeyboardFocus( nil )
end

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
	hideKeyboard()
	if event.phase == "tap" or event.phase == "release" then
		-- Run the selected activity module on the main tab
		game.gotoTab( "mainAct", false )
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
	local bg = act:grayBackground()
	bg:addEventListener( "touch", hideKeyboard )
	local tb = act:makeTitleBar( "Debug Menu", onBackButton )
	tb:addEventListener( "touch", hideKeyboard )

	-- Position for controls and labels
	local y = act.yMin + act.dyTitleBar * 1.5

	-- Resource edit labels
	y = yEditFirst
	newLabel( "Water", xLabel, y )
	y = y + dyLine
	newLabel( "Food", xLabel, y )
	y = y + dyLine
	newLabel( "Energy", xLabel, y )

	-- Ship state edit label
	y = y + dyLine * 1.5
	newLabel( "State", xLabel, y )

	-- Land button
	y = y + dyLine
	local btn = widget.newButton{
	    x = act.xMin + act.width * 0.6,
	    y = y,
	    width = 50,
	    height = 30,
	    shape = "rect",
		fillColor = { default = { 1, 1, 1 }, over = { 1, 0, 0 } },
	    label = "Land",
	    --labelAlign = "left",
	    onRelease = 
	    	function ()
	    		game.landShip()
	    	end
	}
	act.group:insert( btn )

	-- Cheat mode switch and label
	y = y + dyLine * 1.5
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
	y = y + dyLine * 1.5
	stateEdit = newNumberEdit( xEdit, y, ss.shipState,
		function ( event )
			if event.phase == "ended" or event.phase == "submitted" then
				game.setShipState( tonumber( event.target.text ) or ss.shipState )
			end
		end )
end

-- Stop the act
function act:stop()
	-- Destroy the resource text edits
	hideKeyboard()
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
	if stateEdit then
		stateEdit:removeSelf()
		stateEdit = nil
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

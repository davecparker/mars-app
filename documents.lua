-----------------------------------------------------------------------------------------
--
-- documents.lua
--
-- The documents view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Act variables
local tableView     -- TableView widget to display list of documents
local badge         -- tab bar badge for new document indicator


-- Draw a row in the tableView
local function onRowRender( event )
    -- Get row info
    local row = event.row
    local dxRow = row.contentWidth
    local dyRow = row.contentHeight

    -- Display the text
	local docs = game.saveState.docs
    local rowTitle = display.newText( row, docs[row.index], 0, 0, native.systemFont, 18 )
    rowTitle:setFillColor( 0 )     -- black text
    rowTitle.anchorX = 0           -- left aligned
    rowTitle.x = 15
    rowTitle.y = dyRow * 0.5       -- vertically centered
end

-- Handle touch on a row
local function onRowTouch( event )
	if event.phase == "tap" or event.phase == "release" then
		-- Set name of doc to open and switch to document view
		game.openDoc = game.saveState.docs[event.row.index]
		game.gotoAct( "document", { effect = "slideLeft", time = 300 } )
	end
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:whiteBackground()
	act:makeTitleBar( "Documents" )

	-- Make the TableView to list the documents
	tableView = widget.newTableView
	{
	    left = act.xMin,
	    top = act.yMin + act.dyTitleBar,
	    height = act.height - act.dyTitleBar,
	    width = act.width,
	    onRowRender = onRowRender,
	    onRowTouch = onRowTouch,
	}
	act.group:insert(tableView)
end

-- Prepare the view before it shows
function act:prepare()
	-- Make sure that there are enough rows for the list of found docs
	-- (Note that documents never get deleted so the list never shrinks)
	local docs = game.saveState.docs
	while tableView:getNumRows() < #docs do
	    tableView:insertRow{}
	end
end

-- Start the act
function act:start()
	-- Hide the new document badge if showing
	game.hideBadge( badge )
end

-- Add the document with the given filename to the user's found documents
function game.foundDocument( filename )
    -- Do nothing if the user already has this document
    local docs = game.saveState.docs
    for i = 1, #docs do
        if docs[i] == filename then
            return
        end
    end

    -- Add the new document to the end of the list
    docs[#docs + 1] = filename

    -- Create new document badge if necessary, and show it
	if not badge then
		badge = game.createBadge( act.xMin + act.width * 0.55, act.yMax + 15 )
	end
	game.showBadge( badge )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

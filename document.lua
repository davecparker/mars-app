-----------------------------------------------------------------------------------------
--
-- document.lua
--
-- The view for an open document (within the Documents view) for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Act variables
local dxyMargin = 10    -- margin around text area
local text    			-- display object for the document text


-- Handle tap on the back button
local function backTapped()
	-- "Close" the document being viewed, and go back to the documents list view
	game.openDoc = nil
	game.gotoAct( "documents", { effect = "slideRight", time = 300 } )
end

-- Init the act
function act:init()
	-- Title bar for the view
	act:makeTitleBar()

	-- Back button
	local bb = act:newImage( "back.png", { height = act.dyTitleBar * 0.6 } )
	bb.x = act.xMin + 15
	bb.y = act.yMin + act.dyTitleBar / 2
	bb:addEventListener( "tap", backTapped )

	-- Text area
	-- TODO: Make this a native web view for HTML support?
	text = display.newText{
		parent = act.group,
		text = "",   -- set in act:prepare()
		x = act.xMin + dxyMargin,
		y = act.yMin + act.dyTitleBar + dxyMargin,
		width = act.width - dxyMargin * 2,
		height = act.height - dxyMargin * 2,
		font = native.systemFont,
		fontSize = 14,
		align = "left",
	}
	text:setFillColor( 0 )  -- black text
	text.anchorX = 0
	text.anchorY = 0	
end

-- Prepare the act before the show transition
function act:prepare()
	-- Set title bar text to name of document
	act.title.text = game.openDoc

	-- Open the document and load the text into the view
	text.text = ""   -- show empty contents if we fail
	local path = system.pathForFile( "docs/" .. game.openDoc .. ".txt", system.ResourceDirectory )
	if path then
		local file = io.open( path, "r" )
		if file then
			local str = file:read( "*a" )	-- read entire file as a string
			if str then
				text.text = str
			end
			io.close( file )
		end	
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

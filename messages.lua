-----------------------------------------------------------------------------------------
--
-- messages.lua
--
-- The act for the Messages tab in the Mars App game
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Game modules needed
local msgText = require( "msgText" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Data for the act
local dxyMargin = 10     -- margin around messages list
local dxyMarginText = 5  -- margin between boxes and text
local msgs = {}  	     -- array of message ids that have been displayed (in send order)
local newMsgs = {}       -- array of message ids sent but not yet displayed
local scrollView         -- scrollView widget for the list
local yNextMsg           -- y position for next text message in the scrollView
local newMsgTimer        -- timer for checking for new messages
local badge              -- tab bar badge for new message indicator
local newMarksGroup      -- display group for individual new message indicators

-- Load the new text sound
local textSound = audio.loadSound( "media/game/TextTone.wav" )


-- Send the message with the given id
function game.sendMessage( id )
	newMsgs[#newMsgs + 1] = id  -- append to newMsgs list

	-- Create new message badge if necessary, and show it
	if not badge then
		badge = game.createBadge( act.xMin + act.width * 0.75, act.yMax + 15 )
	end
	game.showBadge( badge )
	game.playSound( textSound )

	-- Show message preview window if not in the messages view
	if game.currentActName() ~= "messages" then
		game.showMessagePreview( msgText[id] )
	end
end

-- Send all the messages ids given by variable parameter list
function game.sendMessages( ... )
	for i, v in ipairs{ ... } do
		game.sendMessage( v )
	end
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:whiteBackground()
	act:makeTitleBar( "Messages" )

	-- Make a scroll view that covers the rest of the act area
	yNextMsg = dxyMargin   -- position for the first message
	scrollView = widget.newScrollView{
		left = act.xMin,
		top = act.yMin + act.dyTitleBar,
		width = act.width,
		height = act.height - act.dyTitleBar,
		scrollWidth = act.width,
		scrollHeight = yNextMsg,
		horizontalScrollDisabled = true,
		backgroundColor = { 1, 1, 1 },  -- white
		hideScrollBar = false,
	}
	act.group:insert( scrollView )
end

-- Display the next new message if there is one waiting
local function checkNewMsg()
	-- Is there a message waiting?
	if #newMsgs > 0 then 
		-- Move the next new message id to the end of the displayed messages list
		local id = table.remove( newMsgs, 1 )
		msgs[#msgs + 1] = id
		local str = msgText[id]

		-- Calculate x metrics for the messages (wrt the scrollView)
		local x = dxyMargin
		local textWidth = act.width - dxyMargin * 2 - dxyMarginText * 2

		-- Create a multi-line wrapped text object for the message string
		local text = display.newText{
			text = str,
			x = x + dxyMarginText,
			y = yNextMsg + dxyMarginText,
			width = textWidth,
			height = 0,  -- auto-size the height
			font = native.systemFont,
			fontSize = 14,
			align = "left",
		}
		text:setFillColor( 1 )  -- white
		text.anchorX = 0
		text.anchorY = 0

		-- Make a rounded rect for the message box with height sized for the text
		local rr = display.newRoundedRect( scrollView, x, yNextMsg, 
						textWidth + dxyMarginText * 2, 
						text.height + dxyMarginText * 2, 5 )
		rr.anchorX = 0
		rr.anchorY = 0
		rr:setFillColor( 0.3 )   -- dark gray

		-- Make the new message indicator in the upper right of the rounded rect
		local c = display.newCircle( newMarksGroup, rr.x + rr.width - 3, rr.y + 3, 6 )
	    c:setFillColor( 1, 1, 0 ) -- yellow fill
	    c:setStrokeColor( 0 )     -- black frame
	    c.strokeWidth = 1

		-- Put the items into the scrollView in the right stacking order
		scrollView:insert( rr )
		scrollView:insert( text )
		scrollView:insert( newMarksGroup )  -- keep indicators on top
		
		-- Calculate position for the next message and scroll to make sure that
		-- the last message is fully visible.
		yNextMsg = yNextMsg + rr.height + dxyMargin
		scrollView:setScrollHeight( yNextMsg )
		local yScroll = scrollView.height - yNextMsg
		if yScroll > 0 then 
			yScroll = 0 
		end
		scrollView:scrollToPosition( { y = yScroll, time = 200 } )

		-- Hide the badge if this was the last message waiting
		if #newMsgs <= 0 then
			game.hideBadge( badge )
		end
	end
end

-- Prepare the act
function act:prepare()
	game.hideMessagePreview()
	newMarksGroup = act:newGroup( scrollView )
end

-- Prepare the act to show
function act:start()
	-- Start a repeating timer to check for messages after a brief interval each
	newMsgTimer = timer.performWithDelay( 250, checkNewMsg, 0 )  
end

-- Stop the act
function act:stop()
	-- Cancel the new message check timer
	if newMsgTimer then
		timer.cancel( newMsgTimer )
		newMsgTimer = nil
	end

	-- Remove the individual new message indicators
	if newMarksGroup then
		newMarksGroup:removeSelf()
		newMarksGroup = nil
	end
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

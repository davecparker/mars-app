-----------------------------------------------------------------------------------------
--
-- tabBar.lua
--
-- Create and handle the tab bar widget on the bottom of the screen
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- The tab bar widget and info
local tabBar          -- the tab bar widget
local msgPreview      -- text message preview window

-- The tab bar buttons
local buttons = {
    { id = "mainAct",    defaultFile = "media/game/mapTab.png", selected = true },
--    { id = "resources",  defaultFile = "media/game/resourseTab.png"  },
    { id = "documents",  defaultFile = "media/game/filesTab.png" },
    { id = "messages",   defaultFile = "media/game/messagesTab.png" },
    { id = "menu",       defaultFile = "media/game/settingsTab.png" },
}


-- Automatically pause or unpause the game as appropriate for going to the given tab name
local function autoPauseGame( tabName )
    local pause = (tabName == "menu")
    if pause ~= game.paused then
        game.paused = pause
        print( "game.paused = ", game.paused )
    end
end

-- Handle tab bar button events
local function handleTabBarEvent( event )
    local scene = event.target._id   -- tab id is the scene name
    autoPauseGame( scene )
    local effect = "slideLeft"
    if scene == "mainAct" then
    	-- Restore current act playing on the main tab
    	scene = game.currentMainAct
    	effect = "slideRight"
    elseif scene == "documents" then
    	-- Open current document in documents view if any (else documents list)
    	if game.openDoc then
    		scene = "document"
    	end
	end
	game.gotoScene( scene, { effect = effect, time = 300 } )
end

-- Handle touch on message preview 
local function touchMessagePreview( event )
    if event.phase == "began" then
		game.gotoTab( "messages" )
	end
    return true
end

-- Initialize the app tab bar and message preview on the bottom of the screen
function initTabBar()
    -- Assign properties common to all buttons
    local dxyIcon = game.dyTabBar - 5
    for i = 1, #buttons do
        local b = buttons[i]
        b.onPress = handleTabBarEvent
        b.overFile = b.defaultFile
        b.width = dxyIcon
        b.height = dxyIcon
    end

    -- Make the message preview window (under the tab bar)
    msgPreview = display.newGroup()
    msgPreview.x = game.xCenter
    msgPreview.yHide = game.yMax - game.dyTabBar * 0.5 + 2    -- under tab bar
    msgPreview.yShow = game.yMax - game.dyTabBar * 1.5 + 2    -- just above tab bar
    msgPreview.y = msgPreview.yHide
    local r = display.newRect( msgPreview, 0, 0, game.width, game.dyTabBar )
    r:setFillColor( 0.3 ) -- dark gray background
    r:setStrokeColor( 0 )  -- black frame
    r.strokeWidth = 1
    r:addEventListener( "touch", touchMessagePreview )
    local text = display.newText( msgPreview, "", 10 - msgPreview.width / 2, 0, native.systemFont, 14 )
    text.anchorX = 0
    text:setFillColor( 1 )  -- white text
    msgPreview.text = text

    -- Create the tab bar widget
    tabBar = widget.newTabBar
    {
    	left = game.xMin,
        top = game.yMax - game.dyTabBar + 1,
        width = game.width,
        height = game.dyTabBar,
        backgroundFile = "media/game/darkRed.png",
        tabSelectedLeftFile = "media/game/redHighlight.png",
        tabSelectedRightFile = "media/game/redHighlight.png",
        tabSelectedMiddleFile = "media/game/redHighlight.png",
        tabSelectedFrameWidth = 10,
        tabSelectedFrameHeight = game.dyTabBar - 10,
        buttons = buttons,
    }

    -- Put the side bars on top, if any
    if game.sideBars then
        game.sideBars:toFront()
    end
end

-- Go to the given game tab name, simulate a press if press is true (or omitted)
function game.gotoTab( name, press )
	-- Find the tab with the given name
    autoPauseGame( name )
	for i = 1, #buttons do
		if buttons[i].id == name then
            if press ~= false then
                press = true
            end
			tabBar:setSelected( i, press )
			return
		end
	end
	error( "Invalid tab name", 2 )
end

-- Show message preview box with the given text
function game.showMessagePreview( text )
    msgPreview.text.text = string.gsub( text, "\n", " ")  -- replace newlines with spaces
    transition.cancel( msgPreview )
    transition.to( msgPreview, { y = msgPreview.yShow, time = 500 } )
    transition.to( msgPreview, { y = msgPreview.yHide, delay = 3500, time = 500 } )
end

-- Hide the message preview box if showing
function game.hideMessagePreview()
    transition.cancel( msgPreview )
    transition.to( msgPreview, { y = msgPreview.yHide, time = 200 } )
end

-- Create and return a new item indicator badge at the given screen position, initially hidden
function game.createBadge( x, y )
    local badge = display.newCircle( x, y, 5)
    badge:setFillColor( 1, 1, 0 ) -- yellow fill
    badge:setStrokeColor( 0 )     -- black frame
    badge.strokeWidth = 1
    badge.alpha = 0
    badge.showing = false
    return badge
end

-- Show the given badge if it is not already showing
function game.showBadge( badge )
    assert( badge )
    if not badge.showing then
        -- Fade in hidden badge
        transition.fadeIn( badge, { time = 200 } )
        badge.showing = true
    elseif badge.alpha == 1 then
        -- Blink already showing badge
        transition.fadeOut( badge, { time = 200 } )
        transition.fadeIn( badge, { delay = 250, time = 200 } )
    end
end

-- Hide the given badge if it exists and is showing
function game.hideBadge( badge )
    if badge and badge.showing then
        transition.fadeOut( badge, { time = 200 } )
        badge.showing = false
    end
end


-- Init and return the tab bar
initTabBar()
return tabBar

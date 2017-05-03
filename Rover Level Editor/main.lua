-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- include the Corona "composer" module
local composer = require "composer"

local platform = system.getInfo( "platform" )
local environment = system.getInfo( "environment" )

print(platform)
print(environment)

if (platform ~= "win32" or platform ~= "macos") and (environment == "simulator") then
	display.setStatusBar( display.HiddenStatusBar )
	local t = display.newText
	{
		text = "This is a desktop level editor. Please build for Windows or Mac 'Ctrl + Shift + B' in Corona Simulator. You can use 'Level Editor' shortcut in the 'Rover Level Editor' folder",
		width = 480,
		height = 320,
		x = display.contentCenterX,
		y = display.contentCenterY,
		font = native.systemFont,
		fontSize = 25,
		align = "center",
	}
else
	-- load editor
	composer.gotoScene( "editor" )
end
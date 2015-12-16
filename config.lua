application =
{

	content =
	{
		-- Make sure our usable coordinate space is at least 320 x 480 (iPhone 4 size)
		width = 320,
		height = 480,
		scale = "letterBox",
		fps = 30,
		audioPlayFrequency = 22050,
		
		--[[
		imageSuffix =
		{
			    ["@2x"] = 2,
		},
		--]]
	},

	--[[
	-- Push notifications
	notification =
	{
		iphone =
		{
			types =
			{
				"badge", "sound", "alert", "newsstand"
			}
		}
	},
	--]]    
}

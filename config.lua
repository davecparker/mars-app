application =
{

	content =
	{
		-- Make sure our width is always 320 (for compatibility with coord constants),
		-- and we will use the actual device height.
		width = 320,
		height = 320,
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

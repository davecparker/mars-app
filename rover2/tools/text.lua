--A general use text object (adds zBuffer support and simplifies the call)



local textScript = {}



function textScript.create(x, y, zBuffer, z, size, font)
	local text

	local function init()
		local options = {text = "", x = x, y = y, font = native.systemFont}

		if zBuffer and z then
			text.zBuffer = zBuffer
			zBuffer.add(text, -1)
			text.objType = "Text"
		end

		if size then
			options.fontSize = size
		end

		if font then
			options.font = font
		end

		text = display.newText(options)
	end
	init()



	function text.destroy()
		text.zBuffer.remove(text)
		text:removeSelf()
	end

	return text
end

return textScript

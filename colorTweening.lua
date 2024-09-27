type rgb = {r: number, g: number, b: number}

local colorRanges: { [number]: rgb } = {
	[50000] = {r = 0,   g = 0,   b = 255}, -- blue
	[10000] = {r = 200, g = 145, b = 255}, -- white-purple
	[7500]  = {r = 255, g = 255, b = 255}, -- white
	[6000]  = {r = 255, g = 243, b = 145}, -- yellow-white
	[5000]  = {r = 255, g = 255, b = 0  }, -- yellow
	[4000]  = {r = 255, g = 150, b = 0  }, -- orange
	[3000]  = {r = 255, g = 0,   b = 0  }  -- red
}

-- This function will fire each time the temperature changes and pass the right color for that temperature.
-- This is where you'll define what bricks you want to update. NOTE: Use Color3.fromRGB, not Color.new or any other function.
function updateColors(color)
	game.Workspace["learnedtims playground"].Part.Color = Color3.fromRGB(color.r, color.g, color.b) -- example
end

---------------- Internal ---------------------------------------------------------------
-- NOTE: This function only takes integers like 80 for 80%, not 0.8 for 80%.
function getColorByPercentage (startColor: rgb, endColor: rgb, percentage: number): rgb
	print(startColor, endColor, percentage)
	percentage = percentage * 0.01
	
	local red   = startColor.r + (endColor.r - startColor.r) * percentage
	local green = startColor.g + (endColor.g - startColor.g) * percentage
	local blue  = startColor.b + (endColor.b - startColor.b) * percentage

	local export_: rgb = {r = red, g = green, b = blue}
	return export_
end

function tweenColors(startColor: rgb, endColor: rgb)
	
end

function updateTemp(temp: number, colorRanges, debounceTemp, debounceDiff, ignoreDebounce: boolean)
	--print('passed')
	if (temp > debounceTemp.Value - debounceDiff and temp < debounceTemp.Value + debounceDiff) then 
		if ignoreDebounce == false then return end
	end
	--print('passed 1')
	
	-- init color change
	local closestLower = nil
	local closestHigher = nil
	for key, color in pairs(colorRanges) do
		if key < temp then
			if closestLower == nil or (temp - key) < (temp - closestLower) then
				closestLower = key -- temp
			end
		elseif key > temp then
			if closestHigher == nil or (key - temp) < (closestHigher - temp) then
				closestHigher = key -- temp
			end
		elseif key == temp then
			closestHigher = key
			closestLower = key
		end
	end
	
	if closestLower == nil then closestLower = closestHigher end
	if closestHigher == nil then closestHigher = closestLower end
	
	--print('temp', temp)
	--print('higher range', closestHigher.temp)
	--print('lower range', closestLower.temp)
	
	local closestLowerColor = colorRanges[closestLower]
	local closestHigherColor = colorRanges[closestHigher]
	
	-- get percentage
	local tempRange = closestHigher - closestLower
	local position = temp - closestLower
	local percentage = (position / tempRange) * 100
	
	local color = getColorByPercentage(closestLowerColor, closestHigherColor, percentage)
	print(color.r, '-', color.g, '-', color.b, '|', closestHigher, '-', closestLower)
	
	-- fallback when both colors are the same (percentage will return NaN)
	if closestLower == closestHigher then color = closestHigherColor end
	
	
	updateColors(color)
	
	-- why is this a physical object?: this function is encapsulated, and the input args clone their input value, they do not reference it. therefore its impossible to change a value outside of this function and event listener (the Connect statement)
	debounceTemp.Value = temp
end

local debounceTemp = script.Parent.Parent.Values.OldTemperature -- IntValue
local debounceDiff = 10 --the margin for debounceTemp in kelvin. ifthe new temp is less than this, updateTemp will not fire to save on resources
local tempValObject = script.Parent.Parent.Values.Temperature -- IntValue

-- on server startup, theres no temp diff. therefore the event listener wont fire: we need to manually call updateTemp once.
updateTemp(tempValObject.Value, colorRanges, debounceTemp, debounceDiff, true)

-- runtime event listener
tempValObject:GetPropertyChangedSignal("Value"):Connect(function()
	updateTemp(tempValObject.Value, colorRanges, debounceTemp, debounceDiff, false)
end)

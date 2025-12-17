
local text_service = game:GetService("TextService")
local tween_service = game:GetService("TweenService")
local user_input = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

local janitor = require("@self/Janitor")

local basicColor = Color3.new(1, 0.329412, 0.329412)
local f = math.floor
local info = TweenInfo.new(.2, Enum.EasingStyle.Linear)

local janitors_group: {typeof(janitor.new())} = {}
local actual_running = {}

local function set_gradient(label: TextLabel)
	local gradient = Instance.new("UIGradient", label)

	gradient.Offset = Vector2.new(-1,0)
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,0),
		NumberSequenceKeypoint.new(.75,1),
		NumberSequenceKeypoint.new(1,1)
	})

	local reff = {}

	function reff:play()
		tween_service:Create(gradient, info, {
			Offset = Vector2.new(1,0)
		}):Play()
	end

	function reff:clear()
		table.clear(self)
	end

	reff.gradient = gradient
	return reff
end

local function set_gradient_color(label: TextLabel, color)
	if label:FindFirstChildOfClass("UIGradient") then
		label:FindFirstChildOfClass("UIGradient"):Destroy()
	end

	local gradient = Instance.new("UIGradient", label)
	gradient.Color = color

	local ui_stroke = Instance.new("UIStroke", label)
	ui_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	ui_stroke.Thickness = 1.4
	ui_stroke.Color = Color3.new()

	if user_input.KeyboardEnabled then
		task.spawn(function()
			while task.wait() and label:IsDescendantOf(player) do
				gradient.Rotation += .15
			end
		end)
	end

	return gradient
end

local function create_text(data: TextControllData, yields: boolean)
	local actual_objects = janitors_group[data.frame_owner]
	
	if actual_objects then
		janitors_group[data.frame_owner]:Cleanup()
	else
		janitors_group[data.frame_owner] = janitor.new()
	end
	
	actual_objects = janitors_group[data.frame_owner]
	
	local frame_owner_list = data.frame_owner:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	assert(frame_owner_list, `List owner expected inside frame owner {data.frame_owner.Name}`)
	
	local text = data.text
	local factor = data.factor
	
	local words = {}
	local sleep_duration = .05
	
	frame_owner_list.Padding = UDim.new(-.005,0)
	data.frame_owner.ClipsDescendants = true
	data.highlights = data.highlights or {}
	
	actual_objects:Add(data.frame_owner.InputBegan:Connect(function(input: InputObject) 
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then

			sleep_duration = 0
		end	
	end))
	
	if actual_running[data.frame_owner] then
		task.cancel(actual_running[data.frame_owner])
		actual_running[data.frame_owner] = nil
	end
	
	actual_running[data.frame_owner] = task.spawn(function()
		for i = 1, #text do
			local frame = Instance.new("Frame", data.frame_owner)
			actual_objects:Add(frame)
			
			local value_font = Font.fromEnum(data.font)
			value_font.Bold = true
			value_font.Weight = Enum.FontWeight.Heavy

			local calculate = text_service:GetTextSize(text:sub(i,i), 10, data.font, data.frame_owner.AbsoluteSize)
			
			calculate /= data.frame_owner.AbsoluteSize
			local value = Instance.new("TextLabel", frame)
			
			local gradient = set_gradient(value)
			actual_objects:Add(gradient, "clear")

			frame.Size = UDim2.fromScale(calculate.Y*factor, calculate.Y*factor)
			frame.BackgroundTransparency = 1
			frame.LayoutOrder = i

			value.Text = text:sub(i,i)
			value.TextScaled = true
			value.LayoutOrder = i
			value.Size = UDim2.fromScale(1,1)
			value.FontFace = value_font
			value.BackgroundTransparency = 1
			value.TextColor3 = Color3.new(1,1,1)
			value.AnchorPoint = Vector2.new(.5,.5)
			value.Position = UDim2.fromScale(.5,.5)
			
			--print(text:sub(i,i), gradient, frame)

			Instance.new("UIAspectRatioConstraint", frame)		

			if sleep_duration > 0 then
				gradient:play()
				task.wait(sleep_duration)

				local padding = Instance.new("UIPadding", frame)
				padding.PaddingBottom = UDim.new(.2, 0)

				local t = tween_service:Create(padding, info, {
					PaddingBottom = UDim.new(0,0)
				})

				actual_objects:Add(t)
				t:Play()
			else
				gradient.gradient.Offset = Vector2.new(1,1)
			end
		end
		
		if not data.highlightColor then
			return
		end
		
		if typeof(data.highlightColor)== "table" then
			for i, word:string in data.highlightColor do
				data.highlightColor[i:lower()] = word
			end
		end
		
		for _, word: string in pairs(data.highlights) do
			local reff = data.text:lower()
			word = word:lower()

			local init, target = reff:find(word)
			
			if init then
				for _, lettersFrames: Frame in data.frame_owner:GetChildren() do
					if not lettersFrames:IsA("Frame")  then
						continue
					end
					
					if lettersFrames.LayoutOrder >= init and lettersFrames.LayoutOrder <= target and lettersFrames:FindFirstChildOfClass("TextLabel") then
						if user_input.MouseEnabled then
							local glow = script.Glow:Clone()
							glow.Parent = lettersFrames
							glow.ZIndex = 0
							
							local hover, unHover = tween_service:Create(lettersFrames:FindFirstChildOfClass("TextLabel"), info, {
								Position = UDim2.fromScale(.5,.3)
							}),tween_service:Create(lettersFrames:FindFirstChildOfClass("TextLabel"), info, {
								Position = UDim2.fromScale(.5,.5)
							})
							
							local glowHover, glowUnhover = tween_service:Create(glow, info, {
								ImageTransparency = 0
							}),tween_service:Create(glow, info, {
								ImageTransparency = 1
							})
							
							actual_objects:Add(hover)
							actual_objects:Add(unHover)
							actual_objects:Add(glowHover)
							actual_objects:Add(glowUnhover)
							actual_objects:Add(glow)
							
							actual_objects:Add(lettersFrames.MouseEnter:Connect(function()
								hover:Play()
								glowHover:Play()
							end))
							
							actual_objects:Add(lettersFrames.MouseLeave:Connect(function()
								unHover:Play()
								glowUnhover:Play()
							end))
						end
						
						if typeof(data.highlightColor) == "Color3" then
							lettersFrames:FindFirstChildOfClass("TextLabel").TextColor3 = data.highlightColor
						elseif typeof(data.highlightColor) == "ColorSequence" then
							set_gradient_color(lettersFrames:FindFirstChildOfClass("TextLabel"), data.highlightColor)
						elseif typeof(data.highlightColor) == "table" then							
							local referenceColor = data.highlightColor[word] :: {
								color: Color3,
								information: string?
							}
							
							if referenceColor then
								local color = referenceColor.color
								lettersFrames:FindFirstChildOfClass("TextLabel").TextColor3 = color
								actual_objects:Add(lettersFrames.InputBegan:Connect(function(input: InputObject) 
									if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
										if not referenceColor.ignoreColor then
											result.ContentValue.Text = `<b><font color="rgb({f(color.R * 255)}, {f(color.G*255)}, {f(color.B*255)})">{referenceColor.information}</font></b>`
										else
											result.ContentValue.Text = referenceColor.information or "Not provided a information for that..."
										end
									end	
								end))
							else
								lettersFrames:FindFirstChildOfClass("TextLabel").TextColor3 = basicColor
							end
							
						end
					end
				end
			end
		end 
	end)
	
	return actual_running, actual_objects
end

export type TextControllData = {
	text: string,
	highlights: {string}, -- string objects to highlight
	highlightColor: Color3 | ColorSequence,
	factor: number, -- size increaser
	frame_owner: Frame,
	font: Enum.Font
}

--text: string, factor: number, frame_owner: Frame, highlight: {}, 
--highlightColor: Color3 | ColorSequence

local valueExample = "esse vai ter highlight <aqui ó>"

return {
	create = create_text,
	collect_highlights = function(text: string): {string}
		local highlights = {}

		for match in string.gmatch(text, "<(.-)>") do
			table.insert(highlights, match)
		end

		return highlights
	end,
	
	setResultParent = function(parent: ScreenGui)
		script.Result.Parent = parent	
	end,
}

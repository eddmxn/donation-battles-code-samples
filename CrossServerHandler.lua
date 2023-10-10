local CrossServerHandler = setmetatable({}, {__index = shared.ServerHandler})

local HTTPService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteMod = CrossServerHandler.Get("RemoteMod")

local connections = {}

coroutine.wrap(function()
	local attemptAmnts = 0
	while true do
		local subscribeSuccess, subscribeConnection = pcall(function()
			return MessagingService:SubscribeAsync("CrossServer_Event", function(message)
				
				local data = HTTPService:JSONDecode(message.Data)
				local cmd = data.Cmd
				
				if connections[cmd] then
					connections[cmd](table.unpack(data.Data))
				end
			end)
		end)
		if not subscribeSuccess then
			warn("Failed to subscribe CrossServer_Event! Attempt #" .. attemptAmnts .. "; Reason: " .. subscribeConnection)
			attemptAmnts += 1
			task.wait(10)
		else
			print("MessagingService CrossServer_Event Topic successfully connected!")
			return
		end
	end
end)()

function CrossServerHandler.Publish(cmd, ...)
	local success, result = pcall(MessagingService.PublishAsync, MessagingService, "CrossServer_Event", HTTPService:JSONEncode({Cmd = cmd, Data = {...}}))
	if not success then
		warn("CrossServer_Event post request fail! Reason: " .. result)
		return false
	end
	return true
end

function CrossServerHandler.Subscribe(cmd, func)
	connections[cmd] = func
end


function CrossServerHandler:init()
	CrossServerHandler.Subscribe("GlobalChatMessage", function(message, color, font)
		RemoteMod.SendAllClients("SystemMessage", {
			Text = message,
			Color = color and Color3.fromRGB(color[1], color[2], color[3]) or Color3.fromRGB(255, 255, 255),
			Font = font and Enum.Font[font] or nil
		})
	end)
end

return CrossServerHandler

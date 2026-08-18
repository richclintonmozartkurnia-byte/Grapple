local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GrappleConfig = require(Shared:WaitForChild("GrappleConfig"))

-- Ensure Remotes Folder exists in ReplicatedStorage for clean networking
local RemotesFolder = ReplicatedStorage:FindFirstChild("GrappleRemotes")
if not RemotesFolder then
	local folder = Instance.new("Folder")
	folder.Name = "GrappleRemotes"
	folder.Parent = ReplicatedStorage
	RemotesFolder = folder
end

-- Create RemoteEvents for client-server communication
local function getOrCreateRemote(name)
	local remote = RemotesFolder:FindFirstChild(name)
	if not remote or not remote:IsA("RemoteEvent") then
		local newRemote = Instance.new("RemoteEvent")
		newRemote.Name = name
		newRemote.Parent = RemotesFolder
		return newRemote
	end
	return remote
end

local GrappleStartRemote = getOrCreateRemote("GrappleStart")
local GrappleEndRemote = getOrCreateRemote("GrappleEnd")

-- Table to track active grapple states on the server to prevent spam / exploit
local activeGrapples = {}

-- When a player hooks onto a point
GrappleStartRemote.OnServerEvent:Connect(function(player, hookPosition)
	-- Input Validation: Ensure hookPosition is a valid Vector3
	if typeof(hookPosition) ~= "Vector3" then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Server-Side Distance Verification (Anti-Cheat check)
	local distance = (hookPosition - rootPart.Position).Magnitude
	if distance > (GrappleConfig.MaxDistance + 20) then -- Allow 20 studs margin for network latency
		warn(string.format("[GrappleService] %s tried to grapple beyond max distance (%d studs)", player.Name, distance))
		return
	end

	-- Record active state
	activeGrapples[player] = {
		HookPosition = hookPosition,
		StartTime = os.clock(),
	}

	-- Replicate grapple visual to all other players in the server
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			GrappleStartRemote:FireClient(otherPlayer, player, hookPosition)
		end
	end
end)

-- When a player releases their grapple
GrappleEndRemote.OnServerEvent:Connect(function(player)
	if activeGrapples[player] then
		activeGrapples[player] = nil
	end

	-- Notify other players to remove the visual rope for this player
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			GrappleEndRemote:FireClient(otherPlayer, player)
		end
	end
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activeGrapples[player] then
		activeGrapples[player] = nil
		for _, otherPlayer in Players:GetPlayers() do
			GrappleEndRemote:FireClient(otherPlayer, player)
		end
	end
end)

print("[GrappleService] Server initialized successfully.")

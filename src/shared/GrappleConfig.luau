--!strict
local GrappleConfig = {
	-- Input Settings
	Keybinds = {
		Primary = Enum.UserInputType.MouseButton1, -- Left Click to Web-Swing
		Secondary = Enum.KeyCode.E, -- Keyboard alternative
		MobileButton = true,
		JumpToRelease = true,
	},

	-- Web Reach & Distance
	MaxDistance = 350, -- Reach of web line (studs)
	MinDistance = 15, -- Minimum attach distance
	Cooldown = 0.05, -- Fast chaining between webs

	-- Spider-Man Web Physics (Spring & Swoop)
	Web = {
		Stiffness = 2400, -- Spring stiffness (catches falling speed and swoops upward)
		Damping = 140, -- Smooth damping to prevent jitter
		SwoopBoost = 3800, -- Forward tangential push during the swoop
		ReelInSpeed = 40, -- Reel-in speed when holding W
		MinLength = 12, -- Minimum web length
	},

	-- Launch / Release Fling
	Launch = {
		ForwardBoost = 50, -- High-speed forward launch fling
		UpwardBoost = 28, -- Upward swoop lift
		VelocityPreservation = 1.25, -- Momentum multiplier on release
		MaxVelocity = 200, -- Maximum speed cap
		MinimumFlingSpeed = 45, -- Guaranteed minimum launch speed
	},

	-- Soft-Lock & Targeting
	Targeting = {
		SoftLockRadius = 22, -- Soft-lock radius around cursor to catch ledges easily
		RaycastLayers = RaycastParams.new(),
		ValidTag = "Grappleable",
		AllowAllSurfaces = true,
	},

	-- Visual & Sound Effects
	Visuals = {
		RopeColor = Color3.fromRGB(0, 220, 255),
		RopeWidth = 0.2,
		RopeTexture = "rbxassetid://6034177579",
		RopeTextureLength = 4,
		RopeTransparency = 0.05,
	},
}

return GrappleConfig

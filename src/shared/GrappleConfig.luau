--!strict
local GrappleConfig = {
	-- Input Settings
	Keybinds = {
		Primary = Enum.UserInputType.MouseButton1, -- Left Click to Grapple / Hold to Swing
		Secondary = Enum.KeyCode.E, -- Keyboard alternative
		MobileButton = true, -- Auto-generate on-screen button for mobile/touch
		JumpToRelease = true, -- Pressing Space while swinging releases with extra boost
	},

	-- Grapple Hook Parameters
	MaxDistance = 300, -- Maximum reach of the grappling hook (studs)
	MinDistance = 8, -- Minimum distance to attach
	GrappleSpeed = 160, -- Reel-in / Pull speed if pulling directly (studs/sec)
	Cooldown = 0.1, -- Delay between swings (kept very low for continuous chaining)

	-- Swing Physics (Spider-Man & Stickman Hook style)
	Swing = {
		TangentialForce = 3500, -- Acceleration applied in the direction of swing to "pump" momentum
		ReelInSpeed = 35, -- How fast the rope shortens if holding W or Space while swinging
		MinRopeLength = 12, -- Minimum rope length when reeling in
		GravityMultiplier = 1.25, -- Gravity factor while swinging to give snappy pendulum feel
		AirResistance = 0.998, -- Velocity retention factor in air
	},

	-- Launch / Release Boost (Stickman Hook style fling)
	Launch = {
		ForwardBoost = 45, -- Extra forward velocity added on release
		UpwardBoost = 25, -- Extra upward lift added on release
		VelocityPreservation = 1.15, -- Momentum multiplier when letting go at peak angular velocity
		MaxVelocity = 180, -- Maximum speed cap to avoid physics glitching out
	},

	-- Soft-Lock & Targeting (Assists player in catching ledges/anchors)
	Targeting = {
		SoftLockRadius = 18, -- Cone radius around cursor to snap to valid grapple surfaces/points
		RaycastLayers = RaycastParams.new(),
		ValidTag = "Grappleable", -- Optional CollectionService tag (if empty, allows all solid surfaces)
		AllowAllSurfaces = true, -- If true, can grapple to any solid anchored part (like Spider-Man)
	},

	-- Visual & Sound Effects
	Visuals = {
		RopeColor = Color3.fromRGB(0, 210, 255), -- Electric cyan / web color
		RopeColorActive = Color3.fromRGB(255, 170, 0), -- Tension highlight color
		RopeWidth = 0.18, -- Width of the beam visual
		RopeTexture = "rbxassetid://6034177579", -- Glowing rope texture (fallback will render bright beam)
		RopeTextureLength = 4,
		RopeTransparency = 0.1,
		ShowHookPointMarker = true, -- Displays a glowing target ring at the grapple point
		ReticleColorValid = Color3.fromRGB(0, 255, 180),
		ReticleColorInvalid = Color3.fromRGB(255, 80, 80),
		ReticleColorInRange = Color3.fromRGB(0, 200, 255),
	},
}

return GrappleConfig

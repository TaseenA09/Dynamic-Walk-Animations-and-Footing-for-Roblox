-- THIS IS SUPPOSED TO BE UNDER 'StarterCharacterScripts'

local RunService = game:GetService("RunService") -- The Run service

local CFnew, CFfromOrientation, CFlookAt = CFrame.new , CFrame.fromOrientation, CFrame.lookAt -- Commonly used functions
local sqrt, abs, max, clamp, sin , cos, pi, min = math.sqrt, math.abs, math.max, math.clamp, math.sin, math.cos, math.pi, math.min -- Commonly used functions
local V3new = Vector3.new -- Commonly used function

local Character:Model = script.Parent -- The players character
local Torso:BasePart = Character:WaitForChild("Torso") -- The torso of the character
local HumanoidRootPart:BasePart = Character:WaitForChild("HumanoidRootPart") -- The HumanoidRootPart of the character
local Humanoid:Humanoid = Character:WaitForChild("Humanoid") -- The humanoid of the character

local legMovementDisableAnimationValue = Instance.new("Animation") -- Temporary animation instance


legMovementDisableAnimationValue.AnimationId = "rbxassetid://14781257579" -- Sets custom animation value [CHANGE THIS FOR YOUR OWN ANIMATION]. It disables the player's normal leg animation


local legMovementDisableAnimation = Humanoid:WaitForChild("Animator"):LoadAnimation(legMovementDisableAnimationValue) -- Loads the animation
legMovementDisableAnimationValue:Destroy()

local IgnoreCharacterParams = RaycastParams.new() -- This rayacast param determines the things the leg will ignore while stepping
IgnoreCharacterParams.FilterType = Enum.RaycastFilterType.Exclude
IgnoreCharacterParams.FilterDescendantsInstances = {Character}

local legTick = false -- true = right, false = left

function castRayIgnoringCharacter(_Origin,_End) -- Casts a ray while ignoring the character. Here there is a special bool "IgnoreLegs" value that a part can have which will determine if it will be ignored or not
	local ray = game.workspace:Raycast(_Origin,_End,IgnoreCharacterParams)

	if ray then	
		if ray.Instance and ray.Instance:IsA("BasePart") then
			if ray.Instance:FindFirstChild("IgnoreLegs") and ray.Instance:FindFirstChild("IgnoreLegs"):IsA("BoolValue") then
				if ray.Instance:FindFirstChild("IgnoreLegs").Value == true then
					if ray.Instance.CanCollide == false then
						return ray.Position, ray
					end
				else
					if ray.Instance.CanCollide == true then
						return ray.Position, ray
					end
				end
			else
				if ray.Instance.CanCollide == true then
					return ray.Position, ray
				end
			end

			local otherParam = IgnoreCharacterParams.FilterDescendantsInstances

			repeat
				table.insert(otherParam,ray.Instance)

				IgnoreCharacterParams.FilterDescendantsInstances = otherParam
				ray = game.workspace:Raycast(_Origin,_End,IgnoreCharacterParams)

				if not ray then
					return _Origin+_End
				else
					if ray.Instance:FindFirstChild("IgnoreLegs") and ray.Instance:FindFirstChild("IgnoreLegs"):IsA("BoolValue") then
						if ray.Instance:FindFirstChild("IgnoreLegs").Value == true then
							if ray.Instance.CanCollide == false then
								return ray.Position, ray
							end
						else
							if ray.Instance.CanCollide == true then
								return ray.Position, ray
							end
						end
					else
						if ray.Instance.CanCollide == true then
							return ray.Position, ray
						end
					end
				end
			until ray.Instance.CanCollide == true or table.find(otherParam,ray.Instance)


			IgnoreCharacterParams.FilterDescendantsInstances = {Character}
			return ray.Position, ray
		end
		return ray.Position, ray
	end
	
	return _Origin+_End
end

local function createLocalVersionOfMotor6D(motor6D) -- Creates a local version of a Motor6D
	if motor6D and motor6D:IsA("Motor6D") then
		local local6D = Instance.new("Motor6D")
		local6D.Name = motor6D.Name .. " Local"
		local6D.Parent = motor6D.Parent
		local6D.C0 = motor6D.C0
		local6D.C1 = motor6D.C1
		local6D.Part1 = motor6D.Part1
		local6D.Part0 = motor6D.Part0
		motor6D.Enabled = false
		return local6D
	else
		error("Expected Motor6D")
	end
end

local legMotor6DsOriginal = {
	right = Character:WaitForChild("Torso"):WaitForChild("Right Hip"),
	left = Character:WaitForChild("Torso"):WaitForChild("Left Hip")
} -- The original leg Motor6Ds

local legMotor6Ds = {
	right = createLocalVersionOfMotor6D(legMotor6DsOriginal.right),
	left = createLocalVersionOfMotor6D(legMotor6DsOriginal.left)
} -- The local leg Motor6Ds

local HumanoidCommonSizes = {
	Ydiv2 = (Torso.Size.Y/2),
	Xdiv4 = (Torso.Size.X/4)
} -- Values commonly used [Might be removed]

local legOrigins = {
	right = (Torso.CFrame*CFnew(V3new(-HumanoidCommonSizes.Xdiv4,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position,
	left = (Torso.CFrame*CFnew(V3new(HumanoidCommonSizes.Xdiv4,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position
} -- Start of legs

local legTargets ={
	right = legOrigins.right,
	left = legOrigins.left,
	rightBack = legOrigins.right,
	leftBack = legOrigins.left
} -- Target of legs

local legPositions = {
	right = legTargets.right,
	left = legTargets.left
} -- The actual leg positions

local legDisplayPosition = {
	right = legTargets.right,
	left = legTargets.left,
	rightAngle = CFnew(),
	leftAngle = CFnew()
} -- The displayed leg position

local function createTestBlock(name,Color) -- creates a test block [FOR DEBUG WILL BE REMOVED IN THE FINAL RELEASE]
	local block = Instance.new("Part")
	block.Shape = Enum.PartType.Ball
	block.CanCollide = false
	block.Anchored = true
	block.Size = V3new(1,1,1)
	block.Color = Color
	block.Name = name
	block.Transparency = 0.5
	block.Parent = game.Workspace
	return block
end

local function updateLegOrigins() -- Updates the origin positions
	legOrigins = {
		right = (Torso.CFrame*CFnew(V3new(-HumanoidCommonSizes.Xdiv4,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position,
		left = (Torso.CFrame*CFnew(V3new(HumanoidCommonSizes.Xdiv4,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position
	}
end

local Falling = false --Checks if the player is "falling"

local _ty = 0 -- the y velocity of the humanoidrootpart negative when falling, normal when on ground
local _DownCf = CFnew(0,0,-sqrt(sqrt(Torso.AssemblyLinearVelocity.Magnitude))) -- The amount that the target moves forward before raycasting
local _vMul = 1 -- velocity is multiplied by v mul

local function updateLegTargets() -- Updates the targets
	if 
		Humanoid:GetState() == Enum.HumanoidStateType.Climbing 
		or Humanoid:GetState() == Enum.HumanoidStateType.Swimming 
		or Humanoid:GetState() == Enum.HumanoidStateType.Dead 
		or Humanoid:GetState() == Enum.HumanoidStateType.Seated 
		or Humanoid:GetState() == Enum.HumanoidStateType.Ragdoll 
		or Humanoid:GetState() == Enum.HumanoidStateType.FallingDown 
		or Humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding 
		or Humanoid.FloorMaterial == Enum.Material.Air
		or Humanoid:GetState() == Enum.HumanoidStateType.Flying
		or Humanoid:GetState() == Enum.HumanoidStateType.Freefall
		or Humanoid:GetState() == Enum.HumanoidStateType.Landed
	then
		Falling = true
		_vMul = 0
		_ty = -abs(Torso.AssemblyLinearVelocity.Unit.Y)
	else
		Falling = false
		_vMul = 1
		_ty = Torso.AssemblyLinearVelocity.Unit.Y
	end
	
	_DownCf = CFnew(0,0,-sqrt(sqrt(Torso.AssemblyLinearVelocity.Magnitude)))
	
	-- Right Side
	
	legTargets.right = (CFlookAt(V3new(0,0,0),V3new(Torso.AssemblyLinearVelocity.Unit.X*_vMul,_ty,Torso.AssemblyLinearVelocity.Unit.Z*_vMul),Torso.CFrame.UpVector) * _DownCf).Position
	legTargets.right = legTargets.right - V3new(0,2,0)
	
	legTargets.right = castRayIgnoringCharacter(legOrigins.right,legTargets.right.Unit*max(Torso.Size.Y,legTargets.right.Magnitude*1.1))
	
	legTargets.rightBack = (CFlookAt(V3new(0,0,0),V3new(-Torso.AssemblyLinearVelocity.Unit.X*_vMul,-_ty,-Torso.AssemblyLinearVelocity.Unit.Z*_vMul),Torso.CFrame.UpVector) * _DownCf).Position 
	legTargets.rightBack = legTargets.rightBack - V3new(0,2,0)
	
	legTargets.rightBack = castRayIgnoringCharacter(legOrigins.right,legTargets.rightBack.Unit*max(Torso.Size.Y,legTargets.rightBack.Magnitude*1.1))
	
	-- Left Side
	
	legTargets.left = (CFlookAt(V3new(0,0,0),V3new(Torso.AssemblyLinearVelocity.Unit.X * _vMul,_ty,Torso.AssemblyLinearVelocity.Unit.Z * _vMul),Torso.CFrame.UpVector) * _DownCf).Position
	legTargets.left = legTargets.left - V3new(0,2,0)

	legTargets.left = castRayIgnoringCharacter(legOrigins.left,legTargets.left.Unit*max(Torso.Size.Y,legTargets.left.Magnitude*1.1))

	legTargets.leftBack = (CFlookAt(V3new(0,0,0),V3new(-Torso.AssemblyLinearVelocity.Unit.X * _vMul,-_ty,-Torso.AssemblyLinearVelocity.Unit.Z * _vMul),Torso.CFrame.UpVector) * _DownCf).Position 
	legTargets.leftBack = legTargets.leftBack - V3new(0,2,0)

	legTargets.leftBack = castRayIgnoringCharacter(legOrigins.left,legTargets.leftBack.Unit*max(Torso.Size.Y,legTargets.leftBack.Magnitude*1.1))
end

local function getDistanceV3(v1:Vector3,v2:Vector3) -- Gets distance between two Motor6Ds
	return (v1-v2).Magnitude
end

local _LegBaseDistance = 0 -- Distance between end and target
local _LegDistanceDelta = 0 -- Distance between the leg position and the target
local _LegDelta = 1 -- Tween Time
local _LedDeltaAdd = 0 -- This value is incremented every frame by the frame time and added to _LedDelta

local _LegLerpTargets = {} -- value for fuction to get target
local _LegLerpPositions = {} -- value for function to get position
local _CurrentLegTick = false -- Stores legTick for use

local function lerpLeg(delta) -- Sends back position for the leg being lerped
	if legTick == false then
		_LegLerpTargets.Lerping = legTargets.left
		_LegLerpTargets.Input = legTargets.right
		_LegLerpTargets.InputBack = legTargets.rightBack
		_LegLerpPositions.Input = legPositions.right
		_LegLerpTargets.LerpingBack = legTargets.leftBack
	else
		_LegLerpTargets.Lerping = legTargets.right
		_LegLerpTargets.Input = legTargets.left
		_LegLerpTargets.InputBack = legTargets.leftBack
		_LegLerpPositions.Input = legPositions.left
		_LegLerpTargets.LerpingBack = legTargets.rightBack
	end
	
	_CurrentLegTick = legTick
	
	_LegBaseDistance = getDistanceV3(_LegLerpTargets.Input,_LegLerpTargets.InputBack)
	_LegDistanceDelta = getDistanceV3(_LegLerpPositions.Input,_LegLerpTargets.Input)

	if _LegDistanceDelta > _LegBaseDistance then
		legTick = not _CurrentLegTick
	end
	
	if delta < Torso.AssemblyLinearVelocity.Magnitude/2 then
		_LedDeltaAdd = delta
	end
	_LegDelta = clamp((_LegDistanceDelta/_LegBaseDistance)+_LedDeltaAdd,0,1)
	
	if _LegDelta >= 1 then
		legTick = not _CurrentLegTick
	end
	
	if legTick ~= _CurrentLegTick then
		_LedDeltaAdd = 0
	end
	
	return _LegLerpTargets.LerpingBack:Lerp(_LegLerpTargets.Lerping,max(1-cos(_LegDelta*pi/2),0))
end

local _LegDisplayDelta = 1 -- Lerp time used of display positions
local _justFell = 0 -- Checks if the character just fell

local function setLegDisplay(delta) -- Sets display positions
	if Falling == true or _justFell > 0 then
		_justFell = max(_justFell-(delta*60),0)
		if Falling == true then
			_justFell = delta*120
		end
		_LegDisplayDelta = 1
		_LegDelta = math.clamp(_LegDelta-(delta*10),0,1)
	else
		_LegDisplayDelta = math.clamp(min(delta*30*((Torso.AssemblyLinearVelocity.Magnitude/10)+0.3),1),0.05,1)
	end
	if legTick == false then
		legDisplayPosition.rightAngle = legDisplayPosition.rightAngle:Lerp(CFlookAt(legOrigins.right,legPositions.right,Torso.CFrame.RightVector),_LegDisplayDelta)
		legDisplayPosition.rightLerp = castRayIgnoringCharacter(legOrigins.right,(legDisplayPosition.rightAngle*CFrame.new(0,0,-Torso.Size.Y*1.1)).Position-legOrigins.right)
		legDisplayPosition.leftAngle = legDisplayPosition.leftAngle:Lerp(CFlookAt(legOrigins.left,legPositions.left,Torso.CFrame.RightVector),_LegDisplayDelta)
		legDisplayPosition.leftLerp = castRayIgnoringCharacter(legOrigins.left,(legDisplayPosition.leftAngle*CFrame.new(0,0,(-Torso.Size.Y*1.1)+sin(_LegDelta*pi))).Position-legOrigins.left)
	else
		legDisplayPosition.rightAngle = legDisplayPosition.rightAngle:Lerp(CFlookAt(legOrigins.right,legPositions.right,Torso.CFrame.RightVector),_LegDisplayDelta)
		legDisplayPosition.rightLerp = castRayIgnoringCharacter(legOrigins.right,(legDisplayPosition.rightAngle*CFrame.new(0,0,(-Torso.Size.Y*1.1)+sin(_LegDelta*pi))).Position-legOrigins.right)
		legDisplayPosition.leftAngle = legDisplayPosition.leftAngle:Lerp(CFlookAt(legOrigins.left,legPositions.left,Torso.CFrame.RightVector),_LegDisplayDelta)
		legDisplayPosition.leftLerp = castRayIgnoringCharacter(legOrigins.left,(legDisplayPosition.leftAngle*CFrame.new(0,0,-Torso.Size.Y*1.1)).Position-legOrigins.left)
	end
	
	legDisplayPosition.left = legDisplayPosition.left:Lerp(legDisplayPosition.leftLerp,math.clamp(delta*60,0.05,1))
	legDisplayPosition.right = legDisplayPosition.right:Lerp(legDisplayPosition.rightLerp,math.clamp(delta*60,0.05,1))
end

local function UpdateLegPosition(delta) -- updates the leg positions
	if Torso.AssemblyLinearVelocity.Magnitude <= 0.05 then
		legPositions.right = legTargets.right
		legPositions.left = legTargets.left
		_LegDelta = 1
	elseif Falling == true then
		legPositions.right = legTargets.right + Vector3.new(0,-_ty*2,0)
		legPositions.left = legTargets.left + Vector3.new(0,-_ty*2,0)
	else
		if legTick == false then
			legPositions.left = lerpLeg(delta)
		else
			legPositions.right = lerpLeg(delta)
		end
	end
	
	setLegDisplay(delta)
end

local function UpdateLegs(delta) -- Performs all leg functions
	updateLegOrigins()
	updateLegTargets()
	UpdateLegPosition(delta)
end

local Motor6Dlookat
local Motor6Ddist

legMotor6Ds.right.C1 = CFfromOrientation(0,math.rad(180),math.rad(180))-- Sets local right leg Motor6Ds C1 value
legMotor6Ds.left.C1 = CFfromOrientation(0,math.rad(180),math.rad(180)) -- Sets local left leg Motor6Ds C1 value

local function AnimateLegs() -- Sets the C0 for local leg Motor6Ds
	legMovementDisableAnimation:Play(0)
	
	Motor6Dlookat = CFrame.lookAt(legOrigins.right,legOrigins.right+((legDisplayPosition.right-legOrigins.right).Unit*10),Torso.CFrame.LookVector)
	Motor6Ddist = (legOrigins.right-legDisplayPosition.right).Magnitude
	legMotor6Ds.right.C0 = Torso.CFrame:ToObjectSpace(
		CFnew(legOrigins.right)*(Motor6Dlookat-Motor6Dlookat.Position)*CFfromOrientation(-math.rad(90),0,0)
	)*CFnew(0,Motor6Ddist-(legMotor6Ds.right.Part1.Size.Y/(2)),0)*CFfromOrientation(math.atan(Torso.Size.Z/(Motor6Ddist-(legMotor6Ds.right.Part1.Size.Y)))*2*(1-math.min(1,Motor6Ddist/legMotor6Ds.right.Part1.Size.Y)),0,0)
	
	Motor6Ddist = (legOrigins.left-legDisplayPosition.left).Magnitude
	Motor6Dlookat = CFrame.lookAt(legOrigins.left,legOrigins.left+((legDisplayPosition.left-legOrigins.left).Unit*10),Torso.CFrame.LookVector)
	legMotor6Ds.left.C0 = Torso.CFrame:ToObjectSpace(
		CFnew(legOrigins.left)*(Motor6Dlookat-Motor6Dlookat.Position)*CFfromOrientation(-math.rad(90),0,0)
	)*CFnew(0,Motor6Ddist-(legMotor6Ds.left.Part1.Size.Y/2),0)*CFfromOrientation(math.atan(Torso.Size.Z/(Motor6Ddist-(legMotor6Ds.left.Part1.Size.Y)))*2*(1-math.min(1,Motor6Ddist/legMotor6Ds.left.Part1.Size.Y)),0,0)
end

RunService.RenderStepped:Connect(function(delta)
	UpdateLegs(delta)
	AnimateLegs()
end)
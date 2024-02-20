--!strict

local RunService = game:GetService("RunService") -- The Run service

-- Commonly used functions [MIGHT CHANGE, SOME UNUSED]

local CFnew, CFfromOrientation, CFlookAt = CFrame.new , CFrame.fromOrientation, CFrame.lookAt 
local sqrt, abs, max, clamp, sin , cos, pi, min, rad = math.sqrt, math.abs, math.max, math.clamp, math.sin, math.cos, math.pi, math.min, math.rad
local V3new = Vector3.new

local Character:Model = script.Parent -- The player's character
local Torso:BasePart  = Character:WaitForChild("Torso")::BasePart -- The torso of the character
local HumanoidRootPart:BasePart = Character:WaitForChild("HumanoidRootPart")::BasePart -- The HumanoidRootPart of the character
local Humanoid:Humanoid = Character:WaitForChild("Humanoid")::Humanoid -- The humanoid of the character

local castRayIgnoringCharacter = require(script.RayCaster).init(Character)
local LimbPointer = require(script.LimbPointer)

local legTick:string = "Left"

local function createLocalVersionOfMotor6D(motor6D:Motor6D):Motor6D -- Creates a local version of a Motor6D [MIGHT MOVE TO ANOTHER MODULE]
	if motor6D and motor6D:IsA("Motor6D") then
		local local6D = Instance.new("Motor6D")
		local6D.Name = motor6D.Name .. "Local"
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
	right = Character:WaitForChild("Torso"):WaitForChild("Right Hip")::Motor6D,
	left = Character:WaitForChild("Torso"):WaitForChild("Left Hip")::Motor6D
} -- The original leg Motor6Ds

local legMotor6Ds = {
	right = createLocalVersionOfMotor6D(legMotor6DsOriginal.right),
	left = createLocalVersionOfMotor6D(legMotor6DsOriginal.left)
} -- The local leg Motor6Ds

local HumanoidCommonSizes = {
	Ydiv2 = (Torso.Size.Y/2),
	Xdiv4 = (Torso.Size.X/4),
	Xdiv2 = (Torso.Size.X/2)
} -- Values commonly used [Might be removed]

local legOrigins = {
	right = (Torso.CFrame*CFnew(V3new(-HumanoidCommonSizes.Xdiv4,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position,
	left = (Torso.CFrame*CFnew(V3new(HumanoidCommonSizes.Xdiv4,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position
} -- Start of legs

function updateOrigins()
	legOrigins = {
		right = (Torso.CFrame*CFnew(V3new(-HumanoidCommonSizes.Xdiv2,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position,
		left = (Torso.CFrame*CFnew(V3new(HumanoidCommonSizes.Xdiv2,HumanoidCommonSizes.Ydiv2,0)):Inverse()).Position
	}
end

local legResetOffset = HumanoidRootPart.Size.Y
local legTargets:{right:Vector3, left:Vector3, rightBack:Vector3, leftBack:Vector3} = {
	right = legOrigins.right-V3new(0,legResetOffset,0),
	left = legOrigins.left-V3new(0,legResetOffset,0),
	rightBack = legOrigins.right-V3new(0,legResetOffset,0),
	leftBack = legOrigins.left-V3new(0,legResetOffset,0)	
} -- Target of legs

local function resetLegTargets() -- Resets leg targets
	legTargets ={
		right = legOrigins.right-V3new(0,legResetOffset,0),
		left = legOrigins.left-V3new(0,legResetOffset,0),
		rightBack = legOrigins.right-V3new(0,legResetOffset,0),
		leftBack = legOrigins.left-V3new(0,legResetOffset,0)
	}
end

resetLegTargets()

local legPositions:{
	right:Vector3,
	left:Vector3
} -- The actual leg positions

function resetLegPositions()
	legPositions = {
		right = legTargets.right,
		left = legTargets.leftBack
	}
	
	legTick = "Right"
end

resetLegPositions()

local legDisplayPosition = {
	right = legTargets.right,
	left = legTargets.left,
	rightAngle = CFnew(),
	leftAngle = CFnew()
} -- The displayed leg position

local function createTestBlock(name,Color):Part -- creates a test block [FOR DEBUG PURPOSES WILL BE REMOVED IN THE FINAL RELEASE]
	local block = Instance.new("Part")
	block.Shape = Enum.PartType.Ball
	block.CanCollide = false
	block.Anchored = true
	block.Size = V3new(0.25,0.25,0.25)
	block.Color = Color
	block.Name = name
	block.Transparency = 0.5
	block.Parent = game.Workspace
	return block
end

-- DEBUG ITEMS [Will be removed but use to debug things]
----[[
local tst1 = createTestBlock("tst1",Color3.new(0.666667, 0, 0))
local tst2 = createTestBlock("tst2",Color3.new(0.666667, 0.666667, 0.498039))
local tst3 = createTestBlock("tst3",Color3.new(0, 0.333333, 0.498039))
local tst4 = createTestBlock("tst4",Color3.new(0, 0.333333, 0))
local tst5 = createTestBlock("tst5",Color3.new(0.666667, 0, 1))
local tst6 = createTestBlock("tst6",Color3.new(0.666667, 1, 1))
local tst7 = createTestBlock("tst7",Color3.new(0.666667, 0, 1))
local tst8 = createTestBlock("tst8",Color3.new(0.666667, 1, 1))


local debugIgnoreList = {tst1,tst2,tst3,tst4,tst5,tst6,tst7,tst8}
--]]
----------------------------------------------------------------

local PlayerFloating = false
local function updateFloating()
	if 
		Humanoid:GetState() == Enum.HumanoidStateType.Running and Humanoid.FloorMaterial ~= Enum.Material.Air 
	then
		PlayerFloating = false
		return
	end
	
	PlayerFloating = true
end

local movementValueTweenTime = 4

local PlayerMoveDirection:Vector3 = V3new() -- MoveDirection Of the player

local MinLerpForMoveAndSpeed = 0.1
local minMoveDirection = 0.025
local _currentVelocityUnit = V3new()
local _rootPartOrientation:Vector3 = HumanoidRootPart.Orientation

local function updateMoveDirection(delta:number) --Updates Move Direction
	if (V3new(HumanoidRootPart.AssemblyLinearVelocity.X,0,HumanoidRootPart.AssemblyLinearVelocity.Z).Magnitude <= minMoveDirection) then
		_currentVelocityUnit = HumanoidRootPart.CFrame.LookVector
	else
		_currentVelocityUnit = HumanoidRootPart.AssemblyLinearVelocity.Unit
	end
	
	PlayerMoveDirection = PlayerMoveDirection:Lerp(_currentVelocityUnit,clamp((abs(sqrt((_currentVelocityUnit-PlayerMoveDirection).Magnitude)-0.3)+0.3)*delta*(movementValueTweenTime^3)*max(HumanoidRootPart.AssemblyAngularVelocity.Magnitude,1),0.05,1))
end

local _characterSpeed:number -- the character's speed [* used in one function]
local _t:number -- Value to hold time for lerping [* used in one function]
local minPlayerSpeed = 0.025
local _LerpedPlayerSpeed:number = 0
local PlayerSpeed:number = 0
local _justfloated = 0 -- Might become a permanent value
local _rayDistanceMultiplier = HumanoidRootPart.Size.Y*1.25

local function updateSpeed(delta:number) -- Updates Speed
	--_characterSpeed = (HumanoidRootPart.AssemblyLinearVelocity.Magnitude/HumanoidRootPart.AssemblyMass)-(V3new(0,HumanoidRootPart.AssemblyLinearVelocity.Y,0).Magnitude/HumanoidRootPart.AssemblyMass) [Removes the Y value from the speed]

	if PlayerFloating == true then
		_justfloated = (HumanoidRootPart.AssemblyLinearVelocity.Magnitude/(HumanoidRootPart.AssemblyMass*2))
	else
		_characterSpeed = min((HumanoidRootPart.AssemblyLinearVelocity.Magnitude/(HumanoidRootPart.AssemblyMass))*2,HumanoidRootPart.Size.Y*0.75)
	end
	
	if _justfloated > 0 then
		_characterSpeed = 0
		PlayerSpeed = 0
		_justfloated -= 1
	end
	
	
	_t = clamp((abs(_LerpedPlayerSpeed-_characterSpeed-MinLerpForMoveAndSpeed)*delta*movementValueTweenTime)+MinLerpForMoveAndSpeed,minPlayerSpeed,1)
	_LerpedPlayerSpeed = (_LerpedPlayerSpeed*(1-_t))+(_characterSpeed*_t)
	
	if abs(_LerpedPlayerSpeed-_characterSpeed) < minPlayerSpeed then
		_LerpedPlayerSpeed = _characterSpeed
	end
	
	PlayerSpeed = _LerpedPlayerSpeed

	_rayDistanceMultiplier = (HumanoidRootPart.Size.Y * 1.25)+PlayerSpeed
end

local _rayNormal:Vector3 = V3new(0,0,0)

local function castMovementRays(Origin:Vector3,MoveDirection:Vector3):(Vector3,Vector3)
	--MoveDirection = V3new(MoveDirection.X,-abs(MoveDirection.Y),MoveDirection.Z) [This makes sure the Y value is always negative]
	
	MoveDirection = MoveDirection*PlayerSpeed
	
	local frontOrigin = Origin+V3new(MoveDirection.X,-abs(MoveDirection.Y),MoveDirection.Z)
	local backOrigin = Origin-V3new(MoveDirection.X,abs(MoveDirection.Y),MoveDirection.Z)
	
	local originRayPosition, originRay = castRayIgnoringCharacter(Origin,-V3new(0,HumanoidRootPart.Size.Y*_rayDistanceMultiplier,0),debugIgnoreList,false)
	local frontRayPosition, frontRay = castRayIgnoringCharacter(frontOrigin,-V3new(0,HumanoidRootPart.Size.Y*_rayDistanceMultiplier,0),debugIgnoreList,false)
	local backRayPosition, backRay = castRayIgnoringCharacter(backOrigin,-V3new(0,HumanoidRootPart.Size.Y*_rayDistanceMultiplier,0),debugIgnoreList,false)
	
	if PlayerFloating == true then
		return V3new(0,1,0), originRayPosition
	end
	
	local originNormal
	if not originRay then
		originNormal = V3new(0,1,0)
	else
		originNormal = originRay.Normal
	end
	
	local backNormal
	if not backRay then
		backNormal = V3new(0,1,0)
	else
		backNormal = backRay.Normal
	end
	
	local frontNormal
	if not frontRay then
		frontNormal = V3new(0,1,0)
	else
		frontNormal = frontRay.Normal
	end
	
	local _finalNormal = (frontNormal+backNormal+originNormal)/3
	
	return _finalNormal
		, originRayPosition

end

local _fallbackUpVector:Vector3 = V3new(0,1,0)
local _normal, _originHit
local _frontPos, _frontRay
local _backPos, _backRay

local function getTargets(Origin:Vector3):(Vector3,Vector3)
	_fallbackUpVector = (PlayerMoveDirection.Magnitude <= 0 and V3new(0, 1, 0)) or PlayerMoveDirection
	_normal, _originHit = castMovementRays(Origin,PlayerMoveDirection)
	
	_frontPos, _frontRay = castRayIgnoringCharacter(Origin,((CFlookAt(_originHit , _originHit + _normal,_fallbackUpVector)*CFnew(0,PlayerSpeed,0)).Position-Origin).Unit*_rayDistanceMultiplier,debugIgnoreList)  -- Front
	if not _frontRay then
		_frontPos = Origin+(((CFlookAt(_originHit , _originHit + _normal,_fallbackUpVector)*CFnew(0,PlayerSpeed,0)).Position-Origin).Unit*HumanoidRootPart.Size.Y)
	end
	
	_backPos, _backRay = castRayIgnoringCharacter(Origin,((CFlookAt(_originHit , _originHit + _normal,_fallbackUpVector)*CFnew(0,-PlayerSpeed,0)).Position-Origin).Unit*_rayDistanceMultiplier,debugIgnoreList)  -- Back
	if not _frontRay then
		_backPos = Origin+(((CFlookAt(_originHit , _originHit + _normal,_fallbackUpVector)*CFnew(0,-PlayerSpeed,0)).Position-Origin).Unit*HumanoidRootPart.Size.Y)
	end
	
	return 
		_frontPos,
		 _backPos
end	

local function UpdateTargets(delta:number)
	updateFloating()
	updateOrigins()
	updateMoveDirection(delta)
	updateSpeed(delta)
	
	legTargets.right , legTargets.rightBack = getTargets(legOrigins.right)
	legTargets.left , legTargets.leftBack = getTargets(legOrigins.left)
end

local function getLegOpposite(leg)
	if leg == "Left" then
		return "Right"
	else
		return "Left"
	end
end

local _legTickLower

local function changeLegState()
	legTick = getLegOpposite(legTick)
	_legTickLower = string.lower(legTick)
	legPositions[_legTickLower] = legTargets[_legTickLower]
end
local _currentLegDistance = 0
local _legChangeTick = 0
local _legLerp = 0
local _legLerping = ""
local _legStatic = ""
local _legOldPosition:{[string]:Vector3} = {}
local _legChangeTickLerp:number = 0
local _t = 0

local function UpdateLegsPositions(delta:number)
	_legChangeTickLerp = min((_legChangeTick+(delta))*min(PlayerSpeed,1),1)
	_t = delta*5
	_legChangeTick = (_legChangeTick*(1-_t))+(_legChangeTickLerp*_t)
	
	_legStatic = string.lower(legTick)
	
	_currentLegDistance = (legPositions[_legStatic] - legTargets[_legStatic]).Magnitude
	_legLerp = min((_currentLegDistance)/(PlayerSpeed*2)+_legChangeTick,1)
	
	_legLerping = string.lower(getLegOpposite(legTick))

	if not _legOldPosition[_legLerping] then
		_legOldPosition[_legLerping] = legTargets[_legLerping.."Back"]
	end
	
	legPositions[_legLerping] = _legOldPosition[_legLerping]:Lerp(legTargets[_legLerping], _legLerp)
	legPositions[_legLerping] = legPositions[_legLerping] + V3new(0,sin(_legLerp*pi),0)

	_legOldPosition[_legLerping] = _legOldPosition[_legLerping]:Lerp(legTargets[_legLerping.."Back"], delta*3)

	if _legLerp >= 1 then
		if _currentLegDistance > PlayerSpeed*15 then
			resetLegPositions()
		end
		
		_legOldPosition[_legStatic] = legPositions[_legStatic]
		
		changeLegState()

		_legChangeTick = 0
		_legLerp = 0
	end
end

local function UpdateLegs()
	--	disableAnimations()

	if PlayerFloating == true then
		return
	end
	
	LimbPointer.PointTowards(legMotor6Ds.right,legPositions.right,{Travel = 1})
	LimbPointer.PointTowards(legMotor6Ds.left,legPositions.left,{Travel = 1})
end

function Update(delta)
	UpdateTargets(delta)
	UpdateLegsPositions(delta)
	UpdateLegs()
end

-- RunService Connections

RunService.PreSimulation:Connect(Update)

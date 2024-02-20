--!strict

local module = {}

module.PointTowards = function(targetMotor6D:Motor6D,targetPosition:Vector3,properties:{Offset: CFrame?, Travel: number}?):CFrame
	--[[
		PointTowards // Points a Motor6D limb of a standard R6 character to a target point
		├[*] targetMotor6D // Motor6D to set.
		│
		├[*] target // Target CFrame.
		│
		└properties // Extra properties.
		 ├ Travel // How much towards the target it goes.
		 └ Offset // How much the CFrame is offset by.
	]]
	
	properties = properties
	if not properties then
		properties = {Travel = 0 , Offset = CFrame.new(0,0,0)}
	end
	
	if properties then
		if not properties.Travel then
			properties.Travel = 0
		end

		if not properties.Offset then
			properties.Offset = CFrame.new(0,0,0)
		end
	end
	
	if not targetMotor6D then
		error("No targetMotor6D")
	elseif not targetPosition then
		error("No target Given")
	end
	
	if targetMotor6D.Part0 and targetMotor6D.Part1 and properties then
		local targetOrigin = targetMotor6D.Part0.CFrame*targetMotor6D.C0
		local pointOffset = (targetMotor6D.C0-targetMotor6D.C0.Position):Inverse()*(targetMotor6D.C1-targetMotor6D.C1.Position):Inverse()*(CFrame.fromOrientation(-math.rad(90),0,0)*CFrame.fromOrientation(0,-math.rad(90)*(targetMotor6D.C0.RightVector.Z),0))
		
		local upVector = targetMotor6D.Part0.CFrame.RightVector:Cross(targetMotor6D.C0.UpVector)
		
		targetMotor6D.Transform = targetOrigin:ToObjectSpace(
			CFrame.lookAt(targetOrigin.Position,targetPosition,
				(upVector == Vector3.new(0,0,0) and Vector3.new(1,0,0)) or upVector
			)
		)*pointOffset
		
		targetMotor6D.Transform = targetMotor6D.Transform*CFrame.new(0,(-((targetMotor6D.Part0.CFrame*targetMotor6D.C0*targetMotor6D.Transform).Position-targetPosition).Magnitude+(targetMotor6D.Part1.Size.Y/2)+(math.abs(targetMotor6D.C0.Y)))*properties.Travel,0)
		
		return targetMotor6D.Transform
	end
	
	error("Target Motor6D has no Part0 and/or Part1")
end	

return module


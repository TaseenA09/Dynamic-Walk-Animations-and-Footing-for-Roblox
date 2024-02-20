local module = {}

module.init = function(Character:Model):(_Origin:Vector3, _End:Vector3, IgnoreList:{any}?, DoIgnoreCheck:boolean?) -> (Vector3,RaycastResult)
	local IgnoreCharacterParams = RaycastParams.new() -- This rayacast param determines the things the leg will ignore while stepping
	IgnoreCharacterParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local fullFilterList = {Character}
	IgnoreCharacterParams.FilterDescendantsInstances = fullFilterList

	return function(_Origin, _End,IgnoreList:{any}?,DoIgnoreCheck:boolean?) -- Casts a ray while ignoring the character. Here there is a special bool "IgnoreLegs" value that a part can have which will determine if it will be ignored or not
		if IgnoreList then
			table.insert(IgnoreList,Character)
			fullFilterList = IgnoreList
			IgnoreCharacterParams.FilterDescendantsInstances = fullFilterList
		end
		
		if (DoIgnoreCheck == nil) then
			DoIgnoreCheck = true
		end
		
		local ray = game.workspace:Raycast(_Origin, _End, IgnoreCharacterParams)

		if DoIgnoreCheck == true then
			while ray and ray.Instance and ray.Instance:IsA("BasePart") and ray.Position do
				local ignoreLegsValue = ray.Instance:FindFirstChild("IgnoreLegs")

				if not ignoreLegsValue then
					return ray.Position, ray
				elseif ignoreLegsValue:IsA("BoolValue") then
					if ignoreLegsValue.Value ~= ray.Instance.CanCollide then
						return ray.Position, ray
					end
				end

				local otherParam = IgnoreCharacterParams.FilterDescendantsInstances
				table.insert(otherParam, ray.Instance)
				IgnoreCharacterParams.FilterDescendantsInstances = otherParam
				ray = game.workspace:Raycast(_Origin, _End, IgnoreCharacterParams)
			end
		end

		IgnoreCharacterParams.FilterDescendantsInstances = {Character}

		if ray then
			return ray.Position, ray
		else
			return _Origin + _End
		end
	end
end

return module
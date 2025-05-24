function makeFourRopesSlider(ent1, ent2, bone1, bone2, pos1, dirVectors, length, width, material, color) -- Returns a table of 4 rope constraints
		
		local slider = {}
		local xvec, yvec = dirVectors[1], dirVectors[2]
		local offsetDirections = { xvec, -xvec, yvec, -yvec }
		
		for _, direction in pairs( offsetDirections ) do
			
			local pos2 = pos1 + direction * length
			
			local localPos1 = ent1:WorldToLocal(pos1)
			local localPos2 = ent2:WorldToLocal(pos2)
			
			local constr = constraint.Rope(ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color)
			table.insert( slider, constr )
		
		end
		
		return slider
		
end


function makeTwoRopesSlider(ent1, ent2, bone1, bone2, pos1, dirVectors, offsetX, offsetY, width, material, color) -- Returns a table of 2 rope constraints
		
		local slider = {}
		local xvec, yvec = dirVectors[1], dirVectors[2]
		local offsetYDirections = { yvec, -yvec }
		
		for _, yDirection in pairs( offsetYDirections ) do
			
			local pos2 = pos1 - ( xvec * offsetX ) + ( yDirection * offsetY )
			local length = ( pos2 - pos1 ):Length()
			
			local localPos1 = ent1:WorldToLocal(pos1)
			local localPos2 = ent2:WorldToLocal(pos2)
			
			local constr = constraint.Rope(ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color)
			table.insert( slider, constr )
		
		end
		
		return slider
		
end



function makeLimitRope(ent1, ent2, bone1, bone2, pos, dirVectors, lowerDistance, upperDistance, width, material, color) -- Returns a rope constraint
	
	local xvec, zvec = dirVectors[1], dirVectors[3]
	local pos1		= pos + xvec * 5 -- This rope causes problems such as suspension locking, offsetting the rope along xvec helps fix this issue.
	
	local posDiff	= zvec * ( upperDistance - lowerDistance ) / 2
	local pos2 		= pos1 + posDiff
	
	local length	= math.abs( upperDistance + lowerDistance ) / 2
	
	local localPos1	= ent1:WorldToLocal( pos1 )
	local localPos2	= ent2:WorldToLocal( pos2 )
	
	return constraint.Rope(ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, false, color)
	
end


-- rotationAxis is the spin axis of the wheel.
function makeElastic(ent1, ent2, bone1, bone2, pos, rotationAxis, offsetX, constant, damping, rdamping, width, material, color) -- Returns an elastic constraint whose local positions are the same world positions
	
	local elastic_pos	= pos + offsetX * rotationAxis -- The limit rope causes problems such as suspension locking, offsetting the elastic along xvec helps fix this issue.
	
	local localPos1		= ent1:WorldToLocal( elastic_pos )
	local localPos2		= ent2:WorldToLocal( elastic_pos )
	
	return constraint.Elastic(ent1, ent2, bone1, bone2, localPos1, localPos2, constant, damping, rdamping, material, width, false, color)
	
end


function makeRotationLimitingAdvBallsocket(ent1, ent2, bone1, bone2, rotationAxis, friction, nocollide)
	
	-- ent1 will only be able to turn along rotationAxis relative to ent2.
	local rotAxisAngle	= rotationAxis:Angle()
	
	-- The only way I found to rotate the entities the same amount was to use this function, Euler Angles addition didn't work for this.
	local newAngle1		= ent1:AlignAngles(rotAxisAngle, angle_zero)
	local newAngle2		= ent2:AlignAngles(rotAxisAngle, angle_zero)
	
	-- Save the entities initial angles to restore later
	local startAngle1 = ent1:GetAngles()
	local startAngle2 = ent2:GetAngles()
	
	-- Rotate both entities
	ent1:SetAngles(newAngle1)
	ent2:SetAngles(newAngle2)
	
	-- The positions values are not very important since onlyrotation = true, but here we use the coordinates center
	local localPos1 = ent1:WorldToLocal(ent1:GetPos())
	local localPos2 = ent2:WorldToLocal(ent2:GetPos())

	-- Create the advanced ballsocket that will limit the axis of rotation (of ent1 relative to ent2) to rotationAxis
	local constr = constraint.AdvBallsocket(ent1, ent2, bone1, bone2, localPos1, localPos2, 0, 0, -180, -0.01, -0.01, 180, 0.01, 0.01, friction, 0, 0, 1, nocollide)

	-- Restore the entities angles
	ent1:SetAngles(startAngle1)
	ent2:SetAngles(startAngle2)

	-- Return the created constraint in case it is needed
	return constr
end


-- Returns true if no constraints are valid in a table of constraints.
function noValidConstraintInTable(constraints)
	
	for _, constr in pairs( constraints ) do
	
		if IsValid(constr) then return false end
	
	end
	
	return true
end


-- Returns an arbitrary vector perpendicular to vec
function getPerpendicularVector( vec )

	if not isvector( vec ) then return end
	local v = vec:Cross( vector_up )
	if not v:IsZero() then return v end
	return vec:Cross( Vector( 1, 0, 0 ))

end

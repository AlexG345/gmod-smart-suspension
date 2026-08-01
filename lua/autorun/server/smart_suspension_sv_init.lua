if not istable( SmartSuspension ) then
	SmartSuspension = {}
end


-- Returns an arbitrary vector perpendicular to vec
function SmartSuspension.GetPerpendicularVector( vec )

	if not isvector( vec ) then return end
	local v = vec:Cross( vector_up )
	if not v:IsZero() then return v end
	return vec:Cross( Vector( 1, 0, 0 ) )

end




function SmartSuspension.MakeConstrSafe( ply, type, factory, ... )

	type = type or "ropeconstraints"

	if not ply:CheckLimit( type ) then

		return false

	else

		local constr, rope, controller, slider = factory( ... )

		if IsValid( constr ) then ply:AddCount( type, constr ) end

		return constr, rope, controller, slider

	end
end

function SmartSuspension.MakeGoodRope( ply, ent1, ent2, bone1, bone2, localPos1, localPos2, length, ... )

	local canMove = not ( ent1:IsWorld() or ent2:IsWorld() )
	length = length or ( ent1:LocalToWorld( localPos1) - ent2:LocalToWorld( localPos2 ) ):Length()

	local ent1Pos, ent2Pos = ent1:GetPos(), ent2:GetPos()
	if canMove then
		ent1:SetPos( vector_origin )
		ent2:SetPos( ent2Pos - ent1Pos )
	end

	local constr, rope = SmartSuspension.MakeConstrSafe( ply, nil, constraint.Rope, ent1, ent2, bone1, bone2, localPos1, localPos2, length, ... )

	if canMove then
		ent1:SetPos( ent1Pos )
		ent2:SetPos( ent2Pos )
	end

	if not ( constr and IsValid( constr ) ) then return nil end

	return constr, rope

end


function SmartSuspension.MakeRopeSlider( ent1, ent2, bone1, bone2, localPos1, dirVectors, length, width, material, color, count, ply )

	count = count and math.floor( count ) or 4
	local slider = {}
	local xVec, _, zVec = unpack( dirVectors, 1, 3 )
	local angStep = 360 / count
	local pos1 = ent1:LocalToWorld( localPos1 )

	for i = 0, count - 1 do
		local ang = xVec:Angle()
		ang:RotateAroundAxis( zVec, i * angStep )
		local direction = ang:Forward()
		local pos2 = pos1 + direction * length
		local localPos2 = ent2:WorldToLocal( pos2 )

		local constr = SmartSuspension.MakeGoodRope( ply, ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color )
		if constr == false then return slider end
		table.insert( slider, constr )

	end

	return slider

end


function SmartSuspension.MakeRopeCurver( ent1, ent2, bone1, bone2, localPos1, dirVectors, offsetX, offsetY, width, material, color, ply ) -- Returns a table of 2 rope constraints

	local slider = {}
	local xVec, yVec = dirVectors[1], dirVectors[2]
	local offsetYDirections = { yVec, -yVec }
	local pos1 = ent1:LocalToWorld( localPos1 )

	for i, yDirection in ipairs( offsetYDirections ) do

		local pos2 = pos1 - ( xVec * offsetX ) + ( yDirection * offsetY )
		local length = ( pos2 - pos1 ):Length()

		local localPos2 = ent2:WorldToLocal(pos2)

		local constr = SmartSuspension.MakeGoodRope( ply, ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color )
		if not constr then return slider end
		slider[i] = constr

	end

	return slider

end



function SmartSuspension.MakeLimitRope( ent1, ent2, bone1, bone2, localPos, dirVectors, lowerDistance, upperDistance, width, material, color, ply ) -- Returns a rope constraint

	local xVec, zVec = dirVectors[1], dirVectors[3]
	-- local offset	= xVec * 5  -- This rope causes problems such as suspension locking, offsetting the rope along xVec helps fix this issue.
	local pos1		= ent1:LocalToWorld( localPos ) -- + offset

	local posDiff	= zVec * ( upperDistance - lowerDistance ) / 2
	local pos2 		= pos1 + posDiff

	local length	= math.abs( upperDistance + lowerDistance ) / 2

	local localPos1	= ent1:WorldToLocal( pos1 )
	local localPos2	= ent2:WorldToLocal( pos2 )

	return SmartSuspension.MakeConstrSafe( ply, nil, constraint.Rope, ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, false, color )

end


-- rotationAxis is the spin axis of the wheel.
function SmartSuspension.MakeElastic( ent1, ent2, bone1, bone2, localPos, rotationAxis, offsetX, constant, damping, rdamping, width, material, color, ply ) -- Returns an elastic constraint whose local positions are the same world positions

	local elastic_pos	= ent1:LocalToWorld( localPos ) + offsetX * rotationAxis

	local localPos1		= ent1:WorldToLocal( elastic_pos )
	local localPos2		= ent2:WorldToLocal( elastic_pos )

	return SmartSuspension.MakeConstrSafe( ply, nil, constraint.Elastic, ent1, ent2, bone1, bone2, localPos1, localPos2, constant, damping, rdamping, material, width, false, color )

end

-- Creates a rotation-only advanced ballsocket that uses coordSpace axises instead of world axises.
function SmartSuspension.MakeAlignedAdvBallsocket( ent1, ent2, bone1, bone2, coordSpace, xmin, ymin, zmin, xmax, ymax, zmax, xfric, yfric, zfric, nocollide, ply )

	local cacheAng1	= ent1:GetAngles()
	local cacheAng2	= ent2:GetAngles()

	local curXAngle		= coordSpace[1]:Angle()
	--local localZAngle	= ent1:WorldToLocalAngles( coordSpace[3]:Angle() )

	local localZPos1	= ent1:WorldToLocal( ent1:GetPos() + coordSpace[3] * 100 )

	-- This rotates both entities the same 'way'/'amount'
	ent1:SetAngles( ent1:AlignAngles( curXAngle, angle_zero ) )
	ent2:SetAngles( ent2:AlignAngles( curXAngle, angle_zero ) )

	-- Not sure about this whole part
	local zVec		= ent1:LocalToWorld( localZPos1 ) - ent1:GetPos()
	local curZAngle	= zVec:Angle()
	local angle_up	= vector_up:Angle()
	angle_up.yaw	= -curZAngle.yaw

	ent1:SetAngles( ent1:AlignAngles( curZAngle, angle_up ) )
	ent2:SetAngles( ent2:AlignAngles( curZAngle, angle_up ) )

	-- The positions values are not very important since onlyrotation = true, but here we use the coordinates center
	local localPos1 = vector_origin
	local localPos2 = vector_origin

	-- Create the advanced ballsocket that will limit the axis of rotation (of ent1 relative to ent2) to rotationAxis
	local constr = SmartSuspension.MakeConstrSafe( ply, "constraints", constraint.AdvBallsocket, ent1, ent2, bone1, bone2, localPos1, localPos2, 0, 0, xmin, ymin, zmin, xmax, ymax, zmax, xfric, yfric, zfric, 1, nocollide)

	-- Restore the entities angles
	ent1:SetAngles( cacheAng1 )
	ent2:SetAngles( cacheAng2 )

	return constr
end
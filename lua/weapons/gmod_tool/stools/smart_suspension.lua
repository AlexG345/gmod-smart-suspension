local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file)

TOOL.Category = "Constraints"
TOOL.Name = "#Tool." .. mode .. ".listname"
TOOL.ConfigName = ""

-- Defining conVars and their default values
--[[
TOOL.ClientConVar = {

	[ "pos_type" ]				= "1",
	[ "snap_type" ]				= "3",

	[ "tr_type" ]				= "linear_rope",
	[ "tr_linear_rope_count" ]	= "3",
	[ "tr_linear_rope_length" ]	= "16000",
	[ "tr_curved_offx" ]		= "500",
	[ "tr_curved_offy" ]		= "500",
	[ "tr_width" ]				= "0",
	[ "tr_mat" ]				= "cable/rope",
	[ "tr_col" ]				= "#FFFFFF",

	[ "limitrope_enabled" ]		= "1",
	[ "limitrope_upper_dist" ]	= "24",
	[ "limitrope_lower_dist" ]	= "24",
	[ "limitrope_width" ]		= "0",
	[ "limitrope_mat" ]			= "cable/rope",
	[ "limitrope_col" ]			= "#FFFFFF",

	[ "elastic_type" ]		= "3",
	[ "elastic_constant" ]	= "12000",
	[ "elastic_damping" ]	= "300",
	[ "elastic_rdamping" ]	= "100",
	[ "elastic_width" ]		= "0",
	[ "elastic_mat" ]		= "cable/cable",
	[ "elastic_col" ]		= "#FFFFFF",

	[ "abs_enabled" ]	= "1",
	[ "abs_friction" ]	= "0",
	[ "abs_nocollide" ]	= "1",

	[ "sound" ]	= "1"
}
]]

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "left_1", stage = 1 },
	{ name = "left_2", stage = 2 },
	{ name = "left_3", stage = 3 },
	{ name = "reload" }
}


if CLIENT then
	local t = "tool." .. mode .. "."
	language.Add( t .. "listname",	"Smart Suspension" )
	language.Add( t .. "name",		"Smart Suspension" )
	language.Add( t .. "desc",		"Allows you to create Suspensions (or any of its components) between wheels and a vehicle base." )
	language.Add( t .. "left",		"Select the vehicle base object" )
	language.Add( t .. "left_1",	"Click on a surface paralell to the TOP of your vehicle" )
	language.Add( t .. "left_2",	"Select a wheel (not the vehicle base) to start a Suspension" )
	language.Add( t .. "left_3",	"Click on a surface perpendicular to your wheel axis of rotation to finish this Suspension" )
	language.Add( t .. "right_3",	"Reposition or choose another wheel." )
	language.Add( t .. "reload",	"Unselect everything")
	t = nil

	TOOL.ClientConVar = {
		pos_type				= { "1", 1, 4 },
		snap_type				= { "1", 0, 3 },
		tr_type					= { "linear_rope" },

		tr_linear_rope_count	= { "3", 3 },
		tr_linear_rope_length	= { "16000", 0.1, 16000 },
		tr_curved_offx			= { "500" },
		tr_curved_offy			= { "500" },
		tr_width				= { "0", 0, 100 },
		tr_mat					= { "cable/cable2" },
		tr_col					= { "#FFFFFF" },

		limitrope_enabled		= { "1", 0, 1 },
		limitrope_upper_dist	= { "24", 0 },
		limitrope_lower_dist	= { "24", 0 },
		limitrope_width			= { "0", 0, 100 },
		limitrope_mat			= { "cable/rope" },
		limitrope_col			= { "#FFFFFF" },

		elastic_type		= { "1", 0, 3 },
		elastic_constant	= { "12000", 0 },
		elastic_damping		= { "300", 0 },
		elastic_rdamping	= { "100", 0 },
		elastic_width		= { "0", 0, 100 },
		elastic_mat			= { "cable/cable" },
		elastic_col			= { "#FFFFFF" },

		abs_enabled		= { "1", 0, 1 },
		abs_nocollide	= { "1", 0, 1 },

		sound	= { "1", 0, 1 }
	}
	for i, axis in ipairs( { "x", "y", "z" } ) do
		TOOL.ClientConVar[ "abs_" .. axis .. "max" ]	= { "0.01", -180, 180 }
		TOOL.ClientConVar[ "abs_" .. axis .. "min" ]	= { "-0.01", -180, 180 }
		TOOL.ClientConVar[ "abs_" .. axis .. "fric" ]	= { "0", 0 }
	end

	function TOOL:CreateConVars()
		--local mode = self:GetMode()

		self.AllowedCVar	= CreateConVar( "toolmode_allow_" .. mode, "1", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set to 0 to disallow players being able to use the \"" .. mode .. "\" tool." )
		self.ClientConVars	= {}
		self.ServerConVars	= {}

		for cVar, data in pairs( TOOL.ClientConVar ) do
			TOOL.ClientConVars[ cVar ]	= CreateClientConVar( mode .. "_" .. cVar, data[1], true, true, "Tool specific client setting (" .. mode .. ")" ) -- , data[2], data[3] )
			TOOL.ClientConVar[ cVar ]	= data[ 1 ]
		end
	end

end



if SERVER then

	TOOL.SuccessSounds = {
		[1] = {name = "buttons/button9.wav",	level = 75,	pitchPercent = 90	},
		[2] = {name = "buttons/button9.wav",	level = 75,	pitchPercent = 110	},
		[3] = {name = "buttons/button15.wav",	level = 75,	pitchPercent = 100	},
		[4] = {name = "buttons/button14.wav",	level = 75,	pitchPercent = 100	}
	}


	local function makeConstrSafe( ply, type, factory, ... )

		type = type or "ropeconstraints"

		if not ply:CheckLimit( type ) then

			return false

		else

			local constr, rope, controller, slider = factory( ... )

			if IsValid( constr ) then ply:AddCount( type, constr ) end

			return constr, rope, controller, slider

		end
	end

	local function makeGoodRope( ply, ent1, ent2, ... )

		local canMove = not ( ent1:IsWorld() or ent2:IsWorld() )

		local ent1Pos, ent2Pos = ent1:GetPos(), ent2:GetPos()
		if canMove then
			ent1:SetPos( vector_origin )
			ent2:SetPos( ent2Pos - ent1Pos )
		end

		local constr, rope = makeConstrSafe( ply, nil, constraint.Rope, ent1, ent2, ... )

		if canMove then
			ent1:SetPos( ent1Pos )
			ent2:SetPos( ent2Pos )
		end

		return constr, rope

	end


	function makeRopeSlider( ent1, ent2, bone1, bone2, localPos1, dirVectors, length, width, material, color, count, ply )

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

			local constr = makeGoodRope( ply, ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color )
			if constr == false then return slider end
			table.insert( slider, constr )

		end

		return slider

	end


	function makeFourRopesSlider( ent1, ent2, bone1, bone2, localPos1, dirVectors, length, width, material, color, ply ) -- Returns a table of 4 rope constraints

			local slider = {}
			local xVec, yVec = dirVectors[1], dirVectors[2]
			local offsetDirections = { xVec, -xVec, yVec, -yVec }
			local pos1 = ent1:LocalToWorld( localPos1 )

			for _, direction in pairs( offsetDirections ) do

				local pos2 = pos1 + direction * length

				local localPos2 = ent2:WorldToLocal( pos2 )

				local constr = makeGoodRope( ply, ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color )
				if constr == false then return slider end
				table.insert( slider, constr )

			end

			return slider

	end


	function makeTwoRopesCurver( ent1, ent2, bone1, bone2, localPos1, dirVectors, offsetX, offsetY, width, material, color, ply ) -- Returns a table of 2 rope constraints

		local slider = {}
		local xVec, yVec = dirVectors[1], dirVectors[2]
		local offsetYDirections = { yVec, -yVec }
		local pos1 = ent1:LocalToWorld( localPos1 )

		for _, yDirection in pairs( offsetYDirections ) do

			local pos2 = pos1 - ( xVec * offsetX ) + ( yDirection * offsetY )
			local length = ( pos2 - pos1 ):Length()

			local localPos2 = ent2:WorldToLocal(pos2)

			local constr = makeGoodRope( ply, ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color )
			if constr == false then return slider end
			table.insert( slider, constr )

		end

		return slider

	end



	function makeLimitRope( ent1, ent2, bone1, bone2, localPos, dirVectors, lowerDistance, upperDistance, width, material, color, ply ) -- Returns a rope constraint

		local xVec, zVec = dirVectors[1], dirVectors[3]
		local pos1		= ent1:LocalToWorld( localPos ) + xVec * 5 -- This rope causes problems such as suspension locking, offsetting the rope along xVec helps fix this issue.

		local posDiff	= zVec * ( upperDistance - lowerDistance ) / 2
		local pos2 		= pos1 + posDiff

		local length	= math.abs( upperDistance + lowerDistance ) / 2

		local localPos1	= ent1:WorldToLocal( pos1 )
		local localPos2	= ent2:WorldToLocal( pos2 )

		return makeConstrSafe( ply, nil, constraint.Rope, ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, false, color )

	end


	-- rotationAxis is the spin axis of the wheel.
	function makeElastic( ent1, ent2, bone1, bone2, localPos, rotationAxis, offsetX, constant, damping, rdamping, width, material, color, ply ) -- Returns an elastic constraint whose local positions are the same world positions

		local elastic_pos	= ent1:LocalToWorld( localPos ) + offsetX * rotationAxis -- The limit rope causes problems such as suspension locking, offsetting the elastic along xVec helps fix this issue.

		local localPos1		= ent1:WorldToLocal( elastic_pos )
		local localPos2		= ent2:WorldToLocal( elastic_pos )

		return makeConstrSafe( ply, nil, constraint.Elastic, ent1, ent2, bone1, bone2, localPos1, localPos2, constant, damping, rdamping, material, width, false, color )

	end

	function makeAlignedAdvBallsocket( ent1, ent2, bone1, bone2, coordSpace, xmin, ymin, zmin, xmax, ymax, zmax, xfric, yfric, zfric, nocollide, ply )

		-- Save the entities initial angles to restore later
		local startAngle1 = ent1:GetAngles()
		local startAngle2 = ent2:GetAngles()

		local rotAxisAngle	= coordSpace[ 1 ]:Angle()
		local susAxisAngle	= coordSpace[ 3 ]:Angle()

		-- The only way I found to rotate the entities the same amount was to use this function, Euler Angles addition didn't work for this.
		ent1:SetAngles( ent1:AlignAngles( rotAxisAngle, angle_zero ) )
		ent2:SetAngles( ent2:AlignAngles( rotAxisAngle, angle_zero ) )
		local angle_up		= vector_up:Angle()
		ply:ChatPrint( tostring( susAxisAngle ) )
		ent1:SetAngles( ent1:AlignAngles( susAxisAngle, Angle( 270, 0, 0 ) ) )
		ent2:SetAngles( ent2:AlignAngles( susAxisAngle, Angle( 270, 0, 0 ) ) )

		-- Rotate both entities
		--ent1:SetAngles( newAngle1 )
		--ent2:SetAngles( newAngle2 )

		-- The positions values are not very important since onlyrotation = true, but here we use the coordinates center
		local localPos1 = vector_origin
		local localPos2 = vector_origin

		-- Create the advanced ballsocket that will limit the axis of rotation (of ent1 relative to ent2) to rotationAxis
		local constr = makeConstrSafe( ply, "constraints", constraint.AdvBallsocket, ent1, ent2, bone1, bone2, localPos1, localPos2, 0, 0, xmin, ymin, zmin, xmax, ymax, zmax, xfric, yfric, zfric, 1, nocollide)

		-- Restore the entities angles
		--ent1:SetAngles(startAngle1)
		--ent2:SetAngles(startAngle2)

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
		return vec:Cross( Vector( 1, 0, 0 ) )

	end


	function TOOL:makeSuspension() -- Returns a table of ropeconstraints (ropes and/or elastics), but can also return an empty table.

		local travelType	= self:GetClientInfo( "tr_type" )
		local elasticType	= self:GetClientNumber( "elastic_type" )

		local dirVectors 			= self.dirVectors
		local wheelAxisVec 			= self.wheelAxisVec
		local baseEnt, wheelEnt		= self:GetEnt( 1 ), self:GetEnt( 2 )
		local baseBone, wheelBone	= self:GetBone( 1 ), self:GetBone( 2 )
		local localSusPos			= self.localSusPos

		local suspension = {}
		local ply = self:GetOwner()

		local function getClientColor( cvar )
			local _, col = xpcall( function() return HexToColor( self:GetClientInfo( cvar ) ) end, function () return color_white end )
			return col
		end

		 if travelType ~= "any" then

			local width	= self:GetClientNumber( "tr_width" )
			local mat	= self:GetClientInfo( "tr_mat" )
			local col	= getClientColor( "tr_col")
			local constrs

			if travelType == "linear_rope" then
				local length	= self:GetClientNumber( "tr_linear_rope_length" )
				local count		= self:GetClientNumber( "tr_linear_rope_count")
				constrs = makeRopeSlider( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, dirVectors, length, width, mat, col, count, ply )
				--makeFourRopesSlider( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, dirVectors, length, width, mat, col ) )

			elseif travelType == "curved_rope" then
				local offsetX	= self:GetClientNumber( "tr_curved_offx" )
				local offsetY	= self:GetClientNumber( "tr_curved_offy" )
				constrs = makeTwoRopesCurver( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, dirVectors, offsetX, offsetY, width, mat, col, ply )
			end

			if constrs then table.Add( suspension, constrs ) end

		end

		if self:GetClientBool( "limitrope_enabled" ) then

			local width	= self:GetClientNumber( "limitrope_width" )
			local mat	= self:GetClientInfo( "limitrope_mat" )
			local col	= getClientColor( "limitrope_col")

			local upperDistance	= self:GetClientNumber("limitrope_upper_dist")
			local lowerDistance	= self:GetClientNumber("limitrope_lower_dist")
			local constr = makeLimitRope( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, dirVectors, lowerDistance, upperDistance, width, mat, col, ply )
			if constr then table.insert( suspension, constr ) end

		end

		if elasticType > 0 then

			local width	= self:GetClientNumber( "elastic_width" )
			local mat	= self:GetClientInfo( "elastic_mat" )
			local col	= getClientColor( "elastic_col")

			local constant	= self:GetClientNumber("elastic_constant")
			local damping	= self:GetClientNumber("elastic_damping")
			local rdamping	= self:GetClientNumber("elastic_rdamping")

			if elasticType ~= 2 then
				local constr = makeElastic( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, wheelAxisVec, 0, constant, damping, rdamping, width, mat, col, ply )
				if constr then table.insert( suspension, constr ) end
			end

			if elasticType > 1 then
				for _, offsetX in ipairs({-20, 20}) do
					local constr = makeElastic( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, wheelAxisVec, offsetX, constant, damping, rdamping, width, mat, col, ply )
					if constr then table.insert( suspension, constr ) end
				end
			end

		end


		if self:GetClientBool( "abs_enabled" ) then

			local nocollide	= self:GetClientNumber("abs_nocollide")

			local axises = { "x", "y", "z" }
			local params = { "min", "max", "fric" }
			local function f( axisIndex, paramIndex )
				return self:GetClientNumber( "abs_" .. axises[axisIndex] .. params[ paramIndex ] )
			end

			local coordSpace = { wheelAxisVec, dirVectors[ 2 ], dirVectors[ 3 ] }
			local constr	= makeAlignedAdvBallsocket( baseEnt, wheelEnt, baseBone, wheelBone, coordSpace, f(1,1), f(2,1), f(3,1), f(1,2), f(2,2), f(3,2), f(1,3), f(2,3), f(3,3), nocollide, ply )
			if constr then table.insert( suspension, constr ) end

		end

		return suspension

	end


	function TOOL:getClickPosition( trace )

		local ent = trace.Entity
		local phys = ent:GetPhysicsObjectNum( trace.PhysicsBone )
		local pos_type = self:GetClientNumber( "pos_type" )
		local snap_type = self:GetClientNumber( "snap_type" )
		local corner_snap = bit.band( snap_type, 1 ) ~= 0
		local center_snap = bit.band( snap_type, 2 ) ~= 0

		if pos_type == 1 then
			return ent:OBBCenter()

		elseif pos_type == 2 then
			return ent:WorldToLocal( ent:GetPos() )

		elseif pos_type == 3 then
			return phys:GetMassCenter()

		elseif pos_type == 4 then

			local LHitPos		= ent:WorldToLocal( trace.HitPos )
			if snap_type == 0 then return LHitPos end
			local mins, maxs	= phys:GetAABB()
			local p				= Vector()
			local point			= Vector()

			local function findBoxClosestCorner( boxCorner1, boxCorner2, excludeCorner1 )

				local closestCorner = Vector()
				local minDistSqr = math.huge
				for i = excludeCorner1 and 1 or 0, 7 do

					for c = 1, 3 do
						p[c] = ( bit.band( i, bit.lshift( 1, c - 1 ) ) ~= 0 and boxCorner2 or boxCorner1 )[c]
					end

					local distSqr = p:DistToSqr( LHitPos )
					if distSqr < minDistSqr then
						closestCorner:Set( p )
						minDistSqr = distSqr
					end

				end

				point:Set( closestCorner )

			end

			findBoxClosestCorner( mins, maxs )

			if center_snap then
				findBoxClosestCorner( point, ( mins + maxs ) / 2, not corner_snap )
			end


			return point

		end

	end


	function TOOL:playSuccessSound( ply )
		if not self:GetClientBool( "sound" ) then return false end
		local soundId = 1 + self:GetStage()
		if soundId > 4 then return false end

		local rf = RecipientFilter()
		rf:AddPlayer( ply )
		local sound = self.SuccessSounds[soundId]
		self:GetOwner():EmitSound( sound["name"], sound["level"], sound["pitchPercent"], 1, CHAN_AUTO, 0, 0, rf )

		return true
	end


	function TOOL:Fail( ply, msg )

		if msg then
			ply:ChatPrint( msg )
		end
		if self:GetClientBool("sound") then
			local rf = RecipientFilter()
			rf:AddPlayer( ply )
			ply:StopSound( self.SuccessSounds[4].name ) -- dirty hack
			ply:EmitSound("buttons/combine_button7.wav", 100, 100, 1, CHAN_AUTO, 0, 0, rf )
		end

		return false
	end


end




function TOOL:LeftClick(trace)

	if not trace.Hit then return false end

	local stage = self:GetStage()
	local ply = self:GetOwner()

	local ent = trace.Entity
	local phys = ent:GetPhysicsObjectNum( trace.PhysicsBone )

	-- Save the hit object.
	if stage == 0 or stage == 2 then

		if not ( stage == 0 and ent:IsWorld() ) then
			if not IsValid( ent ) or ent:IsPlayer() then return false end
			if stage == 2 and ( ent:IsWorld() or ent == self:GetEnt(1) ) then return false end -- The wheel can't be the vehicle base or the world
			if SERVER and not IsValid( phys ) then return false end
		end

		-- Saving the entities
		local objId = ( stage == 0 ) and 1 or 2 -- The vehicle base will be saved as Id 1, while the wheel will be saved as Id 2.
		if SERVER then
			ply:SetNW2Entity( mode .. "_ent" .. objId, ent )
			if stage == 2 then
				self.localSusPos = self:getClickPosition( trace )
				ply:SetNW2Vector( mode .. "_local_sus_pos", self.localSusPos )
			end
			self:playSuccessSound( ply )
		end

		self:SetObject( objId, ent, trace.HitPos, phys, trace.PhysicsBone, trace.HitNormal )
		self:SetStage( stage + 1 )

		return true

	end

	-- Save suspension up/down direction
	if stage == 1 then

		if SERVER then
			self.localZVec = self:GetPhys( 1 ):WorldToLocalVector( trace.HitNormal )
			ply:SetNW2Angle( mode .. "_local_z_vec_angle", ent:WorldToLocalAngles( trace.HitNormal:Angle() ) )
			self:playSuccessSound( ply )
		end

		self:SetStage( 2 )

		return true

	end

	if SERVER then
		self:playSuccessSound( ply )
	end
	self:SetStage( 2 ) -- prepare for next wheel

	if CLIENT then return true end -- No checks needed clientside anymore

	-- Save wheel spin axis, try to create the suspension
	self.wheelAxisVec = trace.HitNormal

	self.zVec = self:GetPhys( 1 ):LocalToWorldVector( self.localZVec )
	self.zVec:Normalize() -- in case there is some imprecision on the local/world conversions

	self.yVec = self.wheelAxisVec:Cross( self.zVec )
	if self.yVec:IsZero() then
		if self:GetClientInfo( "tr_type" ) == "curved_rope" then
			return self:Fail( ply, "For curved travel you need to choose a different direction than the top of your vehicle! You can click on the side of your vehicle for example." )
		end
		self.yVec = getPerpendicularVector( self.zVec )
	end
	self.yVec:Normalize()

	self.xVec = self.zVec:Cross( self.yVec )
	self.xVec:Normalize()

	self.dirVectors = { self.xVec, self.yVec, self.zVec }

	-- Create the suspension.
	suspension = self:makeSuspension()

	-- Verify that at least one constraint is valid, otherwise the suspension creation has completely failed.
	if noValidConstraintInTable( suspension ) then
		self:ClearObjects() -- not called clientside, potential problem
		return self:Fail( ply, "The suspension was not created as no constraints were valid/existed. Check your settings in the menu." )
	end

	-- Add to ply's undo, add suspension to cleanup and increase ply's constraints count.
	undo.Create("Rope Suspension")
	undo.SetPlayer(ply)
	for k, constr in pairs( suspension ) do
		if IsValid(constr) then
			undo.AddEntity(constr)
			ply:AddCount("ropeconstraints", constr) -- Small issue here: the AdvBallsocket is added to ropeconstraints, should be added to constraints instead.
			ply:AddCleanup("ropeconstraints", constr)
		end
	end
	undo.Finish()

	return true

end


function TOOL:RightClick( trace )

	if self:GetStage() ~= 3 then return false end
	if IsValid( trace.Entity ) and trace.Entity ~= self:GetEnt( 1 ) then
		self:SetStage( 2 )
		return self:LeftClick( trace )
	end
end

function TOOL:Reload(trace)
	self:ClearObjects()
	return true
end


function TOOL:Holster()

	self:ClearObjects()
	if CLIENT then return true end

	local ply = self:GetOwner()

	if not IsValid(ply) then return false end

	ply:SetNW2Entity(mode .. "_ent1", nil)
	ply:SetNW2Entity(mode .. "_ent2", nil)
	ply:SetNW2Vector(mode .. "_ent2_pos", nil)
	ply:SetNW2Entity(mode .. "_phys1", nil)
	ply:SetNW2Vector(mode .. "_local_z_vec_angle", nil)

	return true
end



if CLIENT then

	local function getLineData2D(originPos, vector, start_multiplier, end_multiplier)
		local p1_Scr	= (originPos + vector * start_multiplier):ToScreen()
		local p2_Scr	= (originPos + vector * end_multiplier):ToScreen()
		return p1_Scr, p2_Scr
	end


	-- converts travel distance to arc angle
	local function zDistToAngle(length, radius)
		return math.acos(math.Clamp(1 - (length * length) / (2 * radius * radius), -1, 1))
	end

	-- converts the upper and lower extension to angular limits
	local function getSuspensionArcRange( upDist, downDist, radius )
		local upAngle = zDistToAngle( upDist, radius)
		local downAngle = zDistToAngle( downDist, radius)
		return -downAngle, upAngle
	end

	-- custom polar-to-cartesian conversion
	local function getSuspensionArcPoint( center, xVec, zVec, radius, angle )
		return center + radius * ( xVec * math.cos( angle ) + zVec * math.sin( angle ) )
	end

	-- for 2 ropes slider
	function TOOL:drawSuspensionArc( pos, xVec, zVec, radius, upDist, downDist, segments, color, segWidth )
		segments = segments or 40
		radius = radius or 40

		if radius <= 0.5 then return end

		local center	= pos - xVec * radius
		local arcStart, arcEnd = getSuspensionArcRange( upDist, downDist, radius )
		local angleStep = ( arcEnd - arcStart ) / segments
		local isFullCircle = arcEnd - arcStart >= 2 * math.pi
		local ang = arcStart

		cam.Start3D()

		render.StartBeam( segments + 3 )

		if not isFullCircle then
			render.AddBeam( center, 3, 0, color )
		end
		for i = 0, segments do

			local p = getSuspensionArcPoint( center, xVec, zVec, radius, ang )
			render.AddBeam( p, segWidth, 0, color )
			render.DrawQuad( Vector( 0, 0, -150 ), Vector( 0, 100, -150 ),Vector( 100, 100, -150 ), Vector( 100, 0, -150 ), Color( 255, 0, 0, 128 ) )

			--render.DrawLine( p, center, color )
			ang = ang + angleStep

		end
		if not isFullCircle then
			render.AddBeam( center, 3, 0, color )
		end
		render.SetColorMaterial()
		render.EndBeam()


		cam.End3D()

	end


	local coolDown = 1
	local lastOccurance = - coolDown -- Ensure the first trigger attempt will work
	local partAng = 0


	-- Not sure how to do this properly.
	function TOOL:DrawHUD()

		local stage = self:GetStage()


		if stage < 1 then return true end

		local ply = self:GetOwner()
		local baseEnt = ply:GetNW2Entity(mode .. "_ent1")
		if not ( IsValid( baseEnt ) or baseEnt.IsWorld and baseEnt:IsWorld() ) then return false end

		local baseCenterPos	= baseEnt:LocalToWorld( baseEnt:OBBCenter() )

		-- Draw the indicator for the vehicle base.
		local textColor		= Color( 0, 0, 0, 255 )
		local font			= "GModWorldtip"
		local bgColor		= Color( 255, 255, 255, 160 )
		local bgRad			= 4

		local arcColor		= Color( 0, 100, 200, 160 )

		local zVec = stage >= 2 and baseEnt:LocalToWorldAngles( ply:GetNW2Angle( mode .. "_local_z_vec_angle" ) ):Forward()

		if stage == 2 then 		-- Draw the vector normal to the top of the vehicle
			local p1_Scr, p2_Scr = getLineData2D( baseCenterPos, zVec, 5, 50 )
			if p1_Scr.visible or p2_Scr.visible then
				local playerDistance = ( baseCenterPos - ply:EyePos() ):Length()
				surface.SetDrawColor( color_white )
				cam.Start3D()
					render.SetColorMaterial()
					render.DrawBeam( baseCenterPos - zVec, baseCenterPos + zVec * 50, playerDistance / 256, 0, 0, color_white )
				cam.End3D()
				draw.WordBox( bgRad, p2_Scr.x, p2_Scr.y, "TOP", font, bgColor, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		end

		local baseCenterPosScr	= baseCenterPos:ToScreen()
		if baseCenterPosScr.visible then draw.WordBox( bgRad, baseCenterPosScr.x, baseCenterPosScr.y, "Vehicle Entity", font, bgColor, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER ) end


		if stage < 3 then return true end

		local wheelEnt		= ply:GetNW2Entity(mode .. "_ent2")
		local wheelRadius	= wheelEnt:BoundingRadius()
		local susLPos		= ply:GetNW2Vector(mode .. "_local_sus_pos")

		-- Draw the suspension position and direction indicators

		local susPos	= wheelEnt:LocalToWorld( susLPos )
		local susPosScr	= susPos:ToScreen()

		if susPosScr.visible then
			--surface.DrawCircle( susPosScr.x, susPosScr.y, 8, Color(225, 100, 190) )
			surface.SetDrawColor( Color( 255, 0, 0 ) )
			surface.DrawLine( susPosScr.x - 10, susPosScr.y, susPosScr.x + 10, susPosScr.y )
			surface.DrawLine( susPosScr.x, susPosScr.y - 10, susPosScr.x, susPosScr.y + 10 )
		end

		local playerDistance = (susPos - ply:EyePos()):Length()

		local isExtLimited = self:GetClientBool( "limitrope_enabled" )
		local upDist, lowDist	= self:GetClientNumber("limitrope_upper_dist"), self:GetClientNumber("limitrope_lower_dist")

		local suspensionAxis	= zVec
		local suspensionRadius	= self:GetClientInfo( "tr_type" ) == "curved_rope" and self:GetClientNumber("tr_curved_offx")
		local radius			= suspensionRadius and suspensionRadius * 0.5 or wheelRadius
		local d1, d2			= isExtLimited and -lowDist or -radius, isExtLimited and upDist or radius
		local p1_Scr, p2_Scr	= getLineData2D( susPos, suspensionAxis, d1, d2 )

		if p1_Scr.visible or p2_Scr.visible then
			cam.Start3D()
				render.SetColorMaterial()
				render.DrawBeam( susPos + d1 * suspensionAxis, susPos + d2 * suspensionAxis, playerDistance / 256, 0, 0, Color( 0, 100, 200, 220 ))
			cam.End3D()
			draw.WordBox( bgRad, p2_Scr.x, p2_Scr.y, "Suspension (UP)", font, bgColor, textColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
		end

		-- Draw the wheel entity indicator

		if wheelEnt:IsValid() then
			local wheelData2D = ( wheelEnt:LocalToWorld( wheelEnt:OBBCenter() ) ):ToScreen()
			if wheelData2D.visible then draw.WordBox( bgRad, wheelData2D.x, wheelData2D.y, "Wheel entity", font, bgColor, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM ) end
		end

		-- Draw the wheel axis indicator

		local eyeTrace = ply:GetEyeTrace()
		if not eyeTrace.Hit then return true end


		if suspensionRadius then
			local yVec = eyeTrace.HitNormal:Cross( zVec )
			if not yVec:IsZero() then
				local xVec = zVec:Cross( yVec )
				xVec:Normalize()
				self:drawSuspensionArc( susPos, xVec, zVec, suspensionRadius, isExtLimited and upDist or 2 * suspensionRadius, isExtLimited and lowDist or 2 * suspensionRadius, nil, arcColor, 0.01 * playerDistance )
			end

		end

		-- If we don't add a ballsocket, we can stop here (we don't need to show the rotation axis of the wheel)

		--if not self:GetClientBool( "abs_enabled" ) then return true end

		local timeElapsed = CurTime() - lastOccurance
		if timeElapsed >= coolDown then

			lastOccurance	= CurTime()

			--debugoverlay.BoxAngles( wheelEnt:GetPos(), wheelEnt:OBBMins(), wheelEnt:OBBMaxs(), wheelEnt:GetAngles(), 1, hitPos != nil and Color(0,255,0,100) or Color( 255,0, 0,100) )

			local emitter = ParticleEmitter( susPos, true )

			local part = emitter:Add( "effects/wheel_ring", susPos )
			local spinSpeed = -90
			partAng = ( partAng + spinSpeed * coolDown ) % 360

			if part then
				part:SetDieTime( coolDown + 0.01 )

				part:SetStartAlpha( 255 )
				part:SetEndAlpha( 255 )

				part:SetStartSize( wheelRadius * 0.75 )
				part:SetEndSize( wheelRadius * 0.75 )

				local startAng = eyeTrace.HitNormal:Angle()
				startAng:RotateAroundAxis( eyeTrace.HitNormal, partAng )
				part:SetAngles( startAng )

				local ang = Angle()
				part:SetThinkFunction( function( p )
					local pos		= wheelEnt:LocalToWorld( susLPos )
					local normal	= ply:GetEyeTrace().HitNormal
					local v			= normal * wheelRadius * 2
					local trace		= util.TraceLine( {
						start		= pos + v,
						endpos		= pos - v,
						filter		= { wheelEnt },
						whitelist	= true
					} )
					local pPos		= trace.Entity == wheelEnt and trace.HitPos or util.IntersectRayWithOBB( pos + v, -v, wheelEnt:GetPos(), wheelEnt:GetAngles(), wheelEnt:OBBMins(), wheelEnt:OBBMaxs() ) or pos + normal * radius
					ang:Set( normal:Angle() )
					p:SetPos( pPos )
					ang:RotateAroundAxis( normal, partAng + p:GetLifeTime() * spinSpeed )
					p:SetAngles( ang )
					p:SetNextThink( CurTime() )
				end )

			end

			emitter:Finish()

		end


		local rotationAxis	= eyeTrace.HitNormal * wheelRadius

		p1_Scr, p2_Scr = getLineData2D( susPos, rotationAxis, 0, 1 )
		if p1_Scr.visible or p2_Scr.visible then
			cam.Start3D()
				render.SetColorMaterial()
				render.DrawBeam( susPos, susPos + rotationAxis, playerDistance / 256, 0, 0, Color( 240, 228, 66, 220 ) )
			cam.End3D()
			draw.WordBox( bgRad, p2_Scr.x, p2_Scr.y, "Rotation Axis", font, bgColor, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		end

		return true

	end

end

if CLIENT then

	local cVarList = TOOL:BuildConVarList()
	for cVar, data in pairs( cVarList ) do
		cVarList[ cVar ] = data[ 1 ]
	end

	local ropeMaterials = {
		"cable/redlaser",
		"cable/cable2",
		"cable/rope",
		"cable/blue_elec",
		"cable/xbeam",
		"cable/physbeam",
		"cable/hydra"
	}

	function TOOL.BuildCPanel(CPanel)

		local t = "tool." .. mode
		local function l( ... )
			local a = { ... }
			if #a == 1 then table.insert( a, 1, t )
			elseif #a < 1 then return end
			return language.GetPhrase( a[1] .. "." .. a[2] )
		end

		local color_blue		= Color( 50, 100, 200 )
		--local color_gray		= Color(240, 240, 240)

		local function addVisuals( controlPanel, widthTable, matTable, colTable)
			controlPanel.Header:SetImage( "icon16/paintbrush.png" )
			controlPanel:NumSlider( widthTable.text, widthTable.cVar, 0, 10, 2 )
			local matSelect = controlPanel:MatSelect( matTable.cVar , ropeMaterials, false, 40, 80)
				matSelect:SetNumRows( 1 )
			local colorMixer = vgui.Create( "DColorMixer", controlPanel )
				controlPanel:AddItem( colorMixer )
				function colorMixer:ValueChanged( col )
					RunConsoleCommand( colTable.cVar, col:ToHex() )
				end

			return controlPanel
		end

		local function CatSetActive( panel, b )
			if panel:GetExpanded() and not b then
				timer.Simple( panel:GetAnimTime(), function() panel:SetVisible( false ) end )
			else
				panel:SetVisible( b )
			end
			panel:DoExpansion( b )
			panel:SetExpanded( b )
		end

		CPanel:Help("A suspension is made of multiple constraints. With this tool, you can combine them in many different ways!")
		CPanel:Help("First, select your vehicle base and click its top, then you can create as many suspensions as you want by clicking wheels and choosing their rotation axis.")

		CPanel:ToolPresets( mode, cVarList )

		local propertySheet = vgui.Create( "DPropertySheet", CPanel )
			propertySheet:Dock( TOP )
			propertySheet:SetTall( 600 )
			propertySheet:DockMargin( 10, 10, 10, 0 )

		local generalCTab = vgui.Create( "DControlTab", propertySheet )
			propertySheet:AddSheet( "General", generalCTab, "icon16/cog.png" )

			local hitPosComboBox = generalCTab:ComboBox( "Hit Position", mode .. "_pos_type" )
				hitPosComboBox:SetSortItems( false )
				hitPosComboBox:AddChoice( "Bounding Box Center",	"1" )
				hitPosComboBox:AddChoice( "Coordinates Center",		"2" )
				hitPosComboBox:AddChoice( "Mass Center",			"3" )
				hitPosComboBox:AddChoice( "Hit Position",			"4" )
				generalCTab:ControlHelp( "Choose what will be considered as the center of the wheel. If you use the \'Make Spherical\' tool, set this to coordinates center." )

			local snapTypeComboBox = generalCTab:ComboBox( "Snap Type", mode .. "_snap_type" )
				snapTypeComboBox:SetSortItems( false )
				snapTypeComboBox:AddChoice( "None",						"0", false, "icon16/shape_square.png" )
				snapTypeComboBox:AddChoice( "Corners",					"1", false, "icon16/shape_handles.png" )
				snapTypeComboBox:AddChoice( "Midpoints",				"2", false, "icon16/shape_align_center.png" )
				snapTypeComboBox:AddChoice( "Corners and midpoints",	"3", false, "icon16/shape_ungroup.png" )
				generalCTab:ControlHelp( "Choose snap" )

			local soundCheckBox = generalCTab:CheckBox( "Enable sounds", mode .. "_sound" )
				soundCheckBox:SetTooltip( "Enable the beeping sounds when using the tool." )

			--[[
			local constrVisualCPanel = addVisuals( generalCTab:ControlPanel( "Constraints appearence", color_dark_blue ),
				{ text = "Constraints Width" },
				{},
				{}
			)
			]]


		local elaCTab = vgui.Create( "DControlTab", propertySheet )
			propertySheet:AddSheet( "Strength", elaCTab, "icon16/control_eject_blue.png", false, false, "Manage how strong the suspension is." )

			local elaSettForm
			local elaCountComboBox = elaCTab:ComboBox( "Elastics layout:", mode .. "_elastic_type" )
				elaCountComboBox:SetSortItems( false )
				local v = GetConVar( mode .. "_elastic_type" ):GetString()
				elaCountComboBox:AddChoice( "0 (   ): None",					"0", v == "0" )
				elaCountComboBox:AddChoice( "1 ( * ): Centered",				"1", v == "1" )
				elaCountComboBox:AddChoice( "2 (* *): Offset",					"2", v == "2" )
				elaCountComboBox:AddChoice( "3 (***): Centered + Offset",		"3", v == "3" )
				elaCountComboBox:SetTooltip("Choose how many elastics are created and where. Each '*' represents an elastic.")
				elaCTab:ControlHelp( "Choose how many elastics are created and where. If you don't use elastics, the suspension won't support the weight of your vehicle." )

				local g = elaCountComboBox.OnSelect
				function elaCountComboBox:OnSelect( index, value, data )
					if index then g( self, index, value, data ) end
					CatSetActive( elaSettForm, data ~= "0" )
				end

			elaSettForm = elaCTab:Form( "Elastic strength", color_blue, color_white )

				elaSettForm:Hide()

				elaSettForm:Help("Below you can change the strength of the elastic(s).")

				local constSlider = elaSettForm:NumSlider("#tool.elastic.constant", mode .. "_elastic_constant", 0, 50000, 2)
					constSlider:SetTooltip( "Directly multiplies the distance-proportional force the elastic applies on the wheel." )
					elaSettForm:ControlHelp( "#tool.elastic.constant.help" )

				local dampSlider = elaSettForm:NumSlider( "#tool.elastic.damping", mode .. "_elastic_damping", 0, 50000, 2)
					dampSlider:SetTooltip( "Slows down any movement of the wheel relative to the vehicle base.\nHigh values of this, relative to your vehicle weight, will cause violent shaking." )
					elaSettForm:ControlHelp( "#tool.elastic.damping.help" )

				local rDampSlider = elaSettForm:NumSlider("#tool.elastic.rdamping", mode .. "_elastic_rdamping", 0, 50000, 2)
					rDampSlider:SetTooltip( "Similar to damping, but proportional to the velocity of the wheel\nrelative to the vehicle base. Can cause shaking if #tool.elastic.constant is too high." )

			elaCountComboBox:OnSelect( nil, elaCountComboBox:GetSelected() )

		local travelCTab = vgui.Create( "DControlTab", propertySheet )
		--"icon16/control_equalizer_blue.png"
			propertySheet:AddSheet( "Travel", travelCTab, "icon16/drive_cd.png", false, false, "Manage the linear degrees of freedom of the wheel." )

			local TrCurSettForm, TrLinSettForm

			local travelTypeComboBox = travelCTab:ComboBox( "Travel path:", mode .. "_tr_type" )
				v = GetConVar( mode .. "_tr_type" ):GetString()
				travelTypeComboBox:SetSortItems( false )
				travelTypeComboBox:AddChoice( "Any",	"any",			v == "any" )
				travelTypeComboBox:AddChoice( "Curved",	"curved_rope",	v == "curved_rope" )
				travelTypeComboBox:AddChoice( "Linear",	"linear_rope",	v == "linear_rope" )

				travelCTab:ControlHelp( "Choose the way the suspension extends relative to the vehicle base.")
				local f = travelTypeComboBox.OnSelect

				function travelTypeComboBox:OnSelect( index, value, data )
					if index then f( self, index, value, data ) end
					CatSetActive( TrCurSettForm, data == "curved_rope" )
					CatSetActive( TrLinSettForm, data == "linear_rope" )
					travelCTab:GetCanvas():InvalidateChildren( true )
				end

			TrCurSettForm = travelCTab:Form( "Curved travel settings", color_blue, color_white )

				TrCurSettForm:Hide()

				local offXSlider = TrCurSettForm:NumSlider("Arc radius", mode .. "_tr_curved_offx", 40, 2000, 2)
					TrCurSettForm:ControlHelp( "Increase this to straighten the travel path." )

				local offYSlider = TrCurSettForm:NumSlider("Anchor spacing", mode .. "_tr_curved_offy", 40, 2000, 2)
					TrCurSettForm:ControlHelp( "Set this to the same as Arc radius for best stability." )
					offYSlider:SetTooltip( "This is equal to half the distance between the vehicle base anchor points of the two ropes" )

				local stabilityButton = vgui.Create( "DButton" )
					TrCurSettForm:AddItem( stabilityButton )
					stabilityButton:SetText( "Stabilize" )
					stabilityButton:DockMargin( 32, 0, 32, 8 )
					stabilityButton:GetParent():DockPadding( 0, 8, 0, 8 )
					function stabilityButton:DoClick()
						local val = offXSlider.Scratch:GetFloatValue()
						offYSlider.Scratch:SetValue( val )
						offYSlider:ValueChanged( val )
					end

			TrLinSettForm = travelCTab:Form( "Linear travel settings", color_blue, color_white )

				TrLinSettForm:Hide()

				TrLinSettForm:Help( "The rope slider created to allow linear travel is not perfect as it has an extension limit. It might also act as a very weak elastic." )

				local TrLinCountSlider = TrLinSettForm:NumSlider( "Rope count", mode .. "_tr_linear_rope_count", 3, 4, 0 )
					TrLinCountSlider:SetTooltip( "How many ropes are created to allow linear travel." )
					TrLinSettForm:ControlHelp( "Set to 3 to let the suspension extend farther. You can use very high numbers but it'll just reduce performance." )

				local TrLinLengthSlider = TrLinSettForm:NumSlider( "Rope length", mode .. "_tr_linear_rope_length", 10, 16000, 0 )
					TrLinLengthSlider:SetTooltip( "Changes the length of the slider's 4 ropes.\nThe shorter, the stiffer the suspension.\nHigh values (16000+ ?) will overflow and can actually lead to shorter ropes." )
					TrLinSettForm:ControlHelp( "Use higher numbers to let the suspension extend farther. If you're not sure, set at 16000.\n" )

			travelTypeComboBox:OnSelect( nil, travelTypeComboBox:GetSelected() )

			local extSettForm
			local extLimCheckBox = travelCTab:CheckBox( "Limit travel", mode .. "_limitrope_enabled" )

				function extLimCheckBox:OnChange( bVal ) -- called twice for some reason. might be cause of instant hiding
					if extSettForm:GetExpanded() == bVal then return end
					CatSetActive( extSettForm, bVal )
				end

				travelCTab:ControlHelp( "If this is checked, a rope will be added to control how far the suspension can extend." )

			extSettForm = travelCTab:Form( "Extension rope limits", color_blue, color_white )

				extSettForm:Hide()

				extSettForm:Help( "Be aware that this rope can sometimes 'paralyze' the suspension, making your vehicle tilted on one side." )

				extSettForm:NumSlider("Bump travel", mode .. "_limitrope_upper_dist", 0, 200, 2)
					extSettForm:ControlHelp("How far the suspension can extend upwards from its resting position.")

				extSettForm:NumSlider("Droop travel", mode .. "_limitrope_lower_dist", 0, 200, 2)
					extSettForm:ControlHelp("How far the suspension can extend downwards from its resting position.")

			extLimCheckBox:OnChange( extLimCheckBox:GetChecked() )

		local RotCTab = vgui.Create( "DControlTab", propertySheet )
			--"icon16/arrow_rotate_clockwise.png"
			propertySheet:AddSheet( "Rotation", RotCTab, "icon16/cd.png", false, false, "Manage the rotational degrees of freedom of the wheel." )


			RotCTab:Help( "Options such as steering are available here." )

			local RotSettForm --, steerAngleSlider
			local RotABSSliders = {}
				local function updateRotABSSliders( ... )
					for i, val in ipairs( { ... } ) do
						RotABSSliders[ i ]:SetValue( val )
					end
				end

			local RotLimCheckBox = RotCTab:CheckBox( "Use advanced ballsocket", mode .. "_abs_enabled" )

				function RotLimCheckBox:OnChange( bVal )
					if RotSettForm:GetExpanded() == bVal then return end
					CatSetActive( RotSettForm, bVal )
				end

				RotCTab:ControlHelp( "If this is checked, your wheel rotation will be limited relative to your vehicle base prop by an advanced ballsocket." )

			RotSettForm = RotCTab:Form( "Adv. ballsocket settings", color_blue, color_white )

				RotSettForm:Help( "Keep in mind that the base GMod duplicator won't recreate advanced ballsockets properly most of the time." )

				local RotTypeComboBox = RotSettForm:ComboBox( "Rotation presets" )
					RotTypeComboBox:SetSortItems( false )
					RotTypeComboBox:Dock( TOP )
					RotTypeComboBox:AddChoice( "Normal wheel",		"spin" )
					RotTypeComboBox:AddChoice( "Steering wheel",	"steer" )
					RotTypeComboBox:AddChoice( "Unlimited",			"any" )

					function RotTypeComboBox:OnSelect( index, value, data )
						if data == "any" then
							updateRotABSSliders( -180, 180, 0, -180, 180, 0, -180, 180, 0 )
							--steerAngleSlider:SetValue( 180 )
						elseif data == "spin" then
							updateRotABSSliders( -180, 180, 0, -0.01, 0.01, 0, -0.01, 0.01, 0 )
							--steerAngleSlider:SetValue( 0.01 )
						elseif data == "steer" then
							local a = 35
							updateRotABSSliders( -180, 180, 0, -0.01, 0.01, 0, -a, a, 0 )
							--steerAngleSlider:SetValue( a )
						end
					end

				--[[
				steerAngleSlider = RotSettForm:NumSlider( "Steering Angle", nil, 0.01, 180, 2 )
					function steerAngleSlider:OnValueChanged( val ) -- this is not always called for some reason
						RotABSSliders[ 7 ].Scratch:SetValue( - val )
						RotABSSliders[ 8 ].Scratch:SetValue( val )
					end
					RotSettForm:ControlHelp( "This is the same as changing both Z Min and Z Max, but is quicker.")
				]]

				local axisInfo = {
					x = { ord = 1, def = "The 'forward' axis settings, min / max should be set to -180 / 180." },
					y = { ord = 2, def = "The 'tilt' axis settings, min / max should be set to -0.01 / 0.01." },
					z = { ord = 3, def = "The 'steering' axis settings." }
				}
				for _, axis in ipairs( { "z", "x", "y" } ) do
					local i = 3 * axisInfo[ axis ].ord
					local lbl = RotSettForm:ControlHelp( axisInfo[ axis ].def )
					lbl:DockMargin( 32, 16, 32, 8 )
					RotABSSliders[ i - 2 ]	= RotSettForm:NumSlider( string.upper( axis ) .. " Minimum Rotation", mode .. "_abs_" .. axis .. "min", -180, 180, 2 )
					RotABSSliders[ i - 1]	= RotSettForm:NumSlider( string.upper( axis ) .. " Maximum Rotation", mode .. "_abs_" .. axis .. "max", -180, 180, 2 )
					RotABSSliders[ i ]		= RotSettForm:NumSlider( string.upper( axis ) .. " " .. l( "tool", "hingefriction" ), mode .. "_abs_" .. axis .. "fric", 0, 1000, 2 )
				end

				local RotColCheckBox = RotSettForm:CheckBox( "No Collide", mode .. "_abs_nocollide" )
					RotColCheckBox:SetTooltip( "#tool.nocollide.help")
					RotColCheckBox:GetParent():DockPadding( 8, 8, 0, 8 )

			RotLimCheckBox:OnChange( RotLimCheckBox:GetChecked() )

		local visualCTab = vgui.Create( "DControlTab", propertySheet )
			propertySheet:AddSheet( "Visual", visualCTab, "icon16/paintcan.png", false, false, "Manage the appearence of the constraints." )

			visualCTab:Help( "Change the settings below if you want to see what the constraints that make up the suspension look like." )

			addVisuals( visualCTab:ControlPanel( "Elastic appearence", color_blue, color_white ),
				{ cVar = mode .. "_elastic_width", text = "Width" },
				{ cVar = mode .. "_elastic_mat" },
				{ cVar = mode .. "_elastic_color" }
			)

			addVisuals( visualCTab:ControlPanel( "Slider appearence", color_blue, color_white ),
				{ cVar = mode .. "_tr_width", text = "Slider Width" },
				{ cVar = mode .. "_tr_mat" },
				{ cVar = mode .. "_tr_color" }
			)

			addVisuals( visualCTab:ControlPanel( "Extension rope appearence", color_blue, color_white ),
				{ cVar = mode .. "_limitrope_width", text = "Width" },
				{ cVar = mode .. "_limitrope_mat" },
				{ cVar = mode .. "_limitrope_color" }
			)

	end
end
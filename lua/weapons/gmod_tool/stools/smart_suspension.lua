local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file)

TOOL.Category = "Constraints"
TOOL.Name = "#Tool." .. mode .. ".listname"
TOOL.ConfigName = ""


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
		pos_type				= { "3", 1, 4 },
		snap_type				= { "3", 0, 3 },
		tr_type					= { "linear_rope" },

		tr_linear_rope_count	= { "3", 3, not game.SinglePlayer() and 4 or nil },
		tr_linear_rope_length	= { "5000", 0.1, 16000 },
		tr_curved_offx			= { "500" },
		tr_curved_offy			= { "500" },
		tr_width				= { "0", 0, 100 },
		tr_mat					= { "cable/cable2" },
		tr_col					= { "#FFFFFF" },

		limitrope_enabled		= { "0", 0, 1 },
		limitrope_upper_dist	= { "50", 0 },
		limitrope_lower_dist	= { "50", 0 },
		limitrope_width			= { "0", 0, 100 },
		limitrope_mat			= { "cable/rope" },
		limitrope_col			= { "#FFFFFF" },

		elastic_pos_type	= { "1", 0, 3 },
		elastic_constant	= { "12000", 0 },
		elastic_damping		= { "300", 0 },
		elastic_rdamping	= { "100", 0 },
		elastic_method		= { "static_sag" },
		elastic_wheel_count	= { "4", 1 },
		elastic_static_sag	= { "12", 0.1, 4000 },
		elastic_width		= { "0", 0, 100 },
		elastic_mat			= { "cable/cable" },
		elastic_col			= { "#FFFFFF" },

		rot_method			= { "none" },

		rot_rope_type		= { "spin" },
		rot_rope_steer_ang	= { "35", 0, 180 }, -- 90 is the max in the menu but it's fine if you really wants to use more than that
		rot_rope_width		= { "0", 0, 100 },
		rot_rope_mat		= { "cable/cable2" },
		rot_rope_col		= { "#FFFFFF" },

		abs_nocollide		= { "1", 0, 1 },

		hydraulic_steer_enabled	= { "0", 0, 1 },
		hydraulic_steer_key1	= { KEY_LEFT, 0, 159 },
		hydraulic_steer_key2	= { KEY_RIGHT, 0, 159 },
		hydraulic_steer_width	= { "0", 0, 100 },
		hydraulic_steer_mat		= { "cable/rope" },
		hydraulic_steer_col		= { "#FFFFFF" },

		sound	= { "1", 0, 1 }
	}
	for i, axis in ipairs( { "x", "y", "z" } ) do
		TOOL.ClientConVar[ "abs_" .. axis .. "max" ]	= { axis == "x" and "180" or "0.01", -180, 180 }
		TOOL.ClientConVar[ "abs_" .. axis .. "min" ]	= { axis == "x" and "-180" or "-0.01", -180, 180 }
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


	function TOOL:GetClientColor( cvar )
		local _, col = xpcall(
			function() return HexToColor( self:GetClientInfo( cvar ) ) end,
			function() return color_white end
		)
		return col
	end

	function TOOL:makeSuspension() -- Returns a table of ropeconstraints (ropes and/or elastics), but can also return an empty table.

		local travelType		= self:GetClientInfo( "tr_type" )
		local elasticPosType	= self:GetClientNumber( "elastic_pos_type" )
		local rotMethod			= self:GetClientInfo( "rot_method" )

		local dirVectors 			= self.dirVectors
		local wheelAxisVec 			= self.wheelAxisVec
		local wheelZVec				= dirVectors[2]:Cross( wheelAxisVec )

		local baseEnt, wheelEnt		= self:GetEnt( 1 ), self:GetEnt( 2 )
		local baseBone, wheelBone	= self:GetBone( 1 ), self:GetBone( 2 )
		local localSusPos			= self.localSusPos
		local susPos				= wheelEnt:LocalToWorld( localSusPos )

		local suspension	= {}
		local ply			= self:GetOwner()


		 if travelType ~= "any" then

			local width	= self:GetClientNumber( "tr_width" )
			local mat	= self:GetClientInfo( "tr_mat" )
			local col	= self:GetClientColor( "tr_col")
			local constrs

			if travelType == "linear_rope" then
				local length	= self:GetClientNumber( "tr_linear_rope_length" )
				local count		= self:GetClientNumber( "tr_linear_rope_count")
				constrs = SmartSuspension.MakeRopeSlider( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, dirVectors, length, width, mat, col, count, ply )

			elseif travelType == "curved_rope" then
				local offsetX	= self:GetClientNumber( "tr_curved_offx" )
				local offsetY	= self:GetClientNumber( "tr_curved_offy" )
				constrs = SmartSuspension.MakeRopeCurver( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, dirVectors, offsetX, offsetY, width, mat, col, ply )
			end

			if constrs then table.Add( suspension, constrs ) end

		end

		if self:GetClientBool( "limitrope_enabled" ) then

			local width	= self:GetClientNumber( "limitrope_width" )
			local mat	= self:GetClientInfo( "limitrope_mat" )
			local col	= self:GetClientColor( "limitrope_col")

			local upperDistance	= self:GetClientNumber("limitrope_upper_dist")
			local lowerDistance	= self:GetClientNumber("limitrope_lower_dist")
			local constr = SmartSuspension.MakeLimitRope( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, dirVectors, lowerDistance, upperDistance, width, mat, col, ply )
			if constr then table.insert( suspension, constr ) end

		end

		if elasticPosType > 0 then

			local width	= self:GetClientNumber( "elastic_width" )
			local mat	= self:GetClientInfo( "elastic_mat" )
			local col	= self:GetClientColor( "elastic_col")

			local constant

			if self:GetClientInfo( "elastic_method" ) == "static_sag" then
				local g				= 600 -- gravity
				local wheelCount	= self:GetClientNumber( "elastic_wheel_count" )
				local staticSag		= self:GetClientNumber( "elastic_static_sag" )

				-- applied force = dist * constant
				-- gravity force = mass * g
				-- we want: staticSag * constant = mass * g / ( wheelCount * elasticCount )
				-- this means constant = mass * g / ( staticSag * wheelCount * elasticCount )
				constant	= baseEnt:GetPhysicsObject():GetMass() * g / ( staticSag * wheelCount * elasticPosType )

			else
				constant	= self:GetClientNumber( "elastic_constant" )
			end

			local damping	= self:GetClientNumber( "elastic_damping" )
			local rdamping	= self:GetClientNumber( "elastic_rdamping" )

			local offsetsX = {}
			if elasticPosType ~= 2 then table.insert( offsetsX, 0 ) end
			if elasticPosType > 1 then table.Add( offsetsX, { -20, 20 } ) end

			for _, offsetX in ipairs( offsetsX ) do
				local constr = SmartSuspension.MakeElastic( wheelEnt, baseEnt, wheelBone, baseBone, localSusPos, wheelAxisVec, offsetX, constant, damping, rdamping, width, mat, col, ply )
				if constr then table.insert( suspension, constr ) end
			end

		end


		if rotMethod == "rot_rope" then

			local rotRopeType	= self:GetClientInfo( "rot_rope_type" )
			local travelCurved	= travelType	== "curved_rope"
			local steerAng		= math.rad( math.abs( self:GetClientNumber( "rot_rope_steer_ang" ) ) )
			local canSteer		= steerAng ~= 0 and rotRopeType	== "steer"

			local offY		= wheelEnt:BoundingRadius() / 2
			local offX		= travelCurved and self:GetClientNumber( "tr_curved_offx" ) or 16000
			-- curver need shorter ropes since if the rope is long it tries to move towards the rope and weird movement happens
			local dirVecs	= { wheelAxisVec, wheelZVec, dirVectors[2] }
			local farVec	= - dirVecs[1] * offX
			local farPos 	= susPos + farVec
			local farDist	= math.abs( offX )
			if travelCurved then dirVecs[1] = - dirVecs[1] end

			local width		= self:GetClientNumber( "rot_rope_width" )
			local mat		= self:GetClientInfo( "rot_rope_mat" )
			local col		= self:GetClientColor( "rot_rope_col")

			local e1, e2 = wheelEnt, baseEnt
			local b1, b2 = wheelBone, baseBone

			if travelCurved then

				if canSteer then
					local constrs = SmartSuspension.MakeRopeCurver(
						e1, e2, wheelBone, baseBone,
						e1:WorldToLocal( farPos ),
						dirVecs, offX, offY / 2,
						width, mat, col, ply
					)
					if constrs then table.Add( suspension, constrs ) end
				else
					-- powerful rope frame that forces the wheel to face the arc center while letting it roll
					for _, vec in ipairs( { susPos, farPos + farVec, farPos + dirVecs[2] * offX, farPos + dirVecs[3] * offX } ) do
						local constr = SmartSuspension.MakeGoodRope(
							ply, e1, e2, b1, b2,
							e1:WorldToLocal( farPos ),
							e2:WorldToLocal( vec ),
							nil, 0, 0, width, mat, true, col
						)
						table.insert( suspension, constr )
					end
				end

			else

				for _, dir in ipairs( { -1, 1 } ) do
					local constr = SmartSuspension.MakeGoodRope(
						ply, e1, e2, b1, b2,
						e1:WorldToLocal( farPos ),
						e2:WorldToLocal( susPos + dirVecs[2] * offY * dir ),
						nil, 0, 0, width, mat, true, col
					)
					table.insert( suspension, constr )
					if not canSteer then
						constr = SmartSuspension.MakeGoodRope(
							ply, e1, e2, b1, b2,
							e1:WorldToLocal( farPos ),
							e2:WorldToLocal( susPos + dirVecs[3] * offX * dir ),
							nil, 0, 0, width, mat, true, col
						)
						table.insert( suspension, constr )
					end
				end

			end

			if canSteer and steerAng < math.pi then
				-- Angle limitation
				suspension[#suspension + 1] = SmartSuspension.MakeGoodRope(
					ply, e1, e2, b1, b2,
					e1:WorldToLocal( farPos ),
					e2:WorldToLocal( farPos ),
					farDist * 2 * math.sin( steerAng / 2), 0, 0, width, mat, false, col
				)
			end

		elseif rotMethod == "abs" then

			local nocollide	= self:GetClientNumber("abs_nocollide")

			local axises = { "x", "y", "z" }
			local params = { "min", "max", "fric" }
			local function f( axisIndex, paramIndex )
				return self:GetClientNumber( "abs_" .. axises[axisIndex] .. params[ paramIndex ] )
			end

			local coordSpace	= { wheelAxisVec, dirVectors[2], wheelZVec }
			local constr		= SmartSuspension.MakeAlignedAdvBallsocket( baseEnt, wheelEnt, baseBone, wheelBone, coordSpace, f(1,1), f(2,1), f(3,1), f(1,2), f(2,2), f(3,2), f(1,3), f(2,3), f(3,3), nocollide, ply )
			if constr then table.insert( suspension, constr ) end

		end

		if self:GetClientBool( "hydraulic_steer_enabled" ) then
			local pos1, pos2	= susPos + dirVectors[2] * 100, susPos + wheelAxisVec * 50
			local length		= ( pos2 - pos1 ):Length()
			local constr		= SmartSuspension.MakeConstrSafe(
				ply, nil, constraint.Hydraulic, ply,
				baseEnt, wheelEnt, baseBone, wheelBone,
				baseEnt:WorldToLocal( susPos + dirVectors[2] * 100 ),
				wheelEnt:WorldToLocal( susPos + wheelAxisVec * 50 ),
				length, length + 100,
				0,				-- width
				KEY_SPACE,		-- key
				0,				-- slider
				200,			-- speed
				"",				-- material
				false,			-- toggle
				color_white
			)
			suspension[#suspension + 1] = constr
		end

		return suspension

	end


	function TOOL:getClickPosition( trace )

		local ent			= trace.Entity
		local phys			= ent:GetPhysicsObjectNum( trace.PhysicsBone )
		local pos_type		= self:GetClientNumber( "pos_type" )
		local snap_type		= self:GetClientNumber( "snap_type" )
		local corner_snap	= bit.band( snap_type, 1 ) ~= 0
		local center_snap	= bit.band( snap_type, 2 ) ~= 0

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
			ply:SetNW2Angle( mode .. "_local_z_vec_angle", self:GetEnt( 1 ):WorldToLocalAngles( trace.HitNormal:Angle() ) )
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

	local completelyFailed = true
	for _, constr in pairs( suspension ) do
		if IsValid(constr) then
			completelyFailed = false
			break
		end
	end

	-- Verify that at least one constraint is valid, otherwise the suspension creation has completely failed.
	if completelyFailed then
		self:ClearObjects() -- TODO: not called clientside, potential problem
		return self:Fail( ply, "The suspension was not created as no constraints were valid/existed. Check your settings in the menu." )
	end

	-- Add to ply's undo, add suspension to cleanup and increase ply's constraints count.
	undo.Create("Rope Suspension")
	undo.SetPlayer(ply)
	for _, constr in ipairs( suspension ) do
		if IsValid(constr) then
			undo.AddEntity(constr)
			-- TODO: is this deprecated or not??
			-- ply:AddCount( "ropeconstraints", constr ) -- TODO: Small issue here: the AdvBallsocket is added to ropeconstraints, should be added to constraints instead.
			-- ply:AddCleanup( "ropeconstraints", constr )
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
	self:SetStage( 0 )
	self:ClearObjects()
	return true
end


function TOOL:Holster()

	self:SetStage( 0 )
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
		local color_gray		= Color( 240, 240, 240 )

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

		CPanel:Help( "This tool lets you toggle and customize the different groups of constraints that make up a suspension." )
		CPanel:Help( "After having looked at the settings, you can create suspensions by following these 4 steps:.")
		CPanel:Help( "1. Select your vehicle base (can be any prop) by clicking on it." )
		CPanel:Help( "2. Click on any surface to define the top direction of your vehicle (if you're not sure, click on your vehicle's roof)." )
		CPanel:Help( "3. Click on a wheel to start a suspension" )
		CPanel:Help( "4. Click on any surface to define the spin axis of your wheel (if you're not sure, click on your wheel or vehicle's side.\nYou can now repeat step 3 and 4 for any wheels." )

		CPanel:ToolPresets( mode, cVarList )

		local propertySheet = vgui.Create( "DPropertySheet", CPanel )
			propertySheet:Dock( TOP )
			propertySheet:SetTall( 600 )
			propertySheet:DockMargin( 10, 10, 10, 0 )

		local function paint( panel, w, h, col )
			local margin = 5
			draw.RoundedBoxEx( 4, margin, margin, w - 2 * margin, h - margin, col, true, true, true, true )
		end

		local function createSheet( name, icon, panel, ... )
			local scrollPanel = vgui.Create( "DScrollPanel", propertySheet )
			propertySheet:AddSheet( name, scrollPanel, icon, ... )
				scrollPanel:Dock( FILL )
				panel = panel or vgui.Create( "DForm" )
				scrollPanel:AddItem( panel )
					panel:SetPaintBackground( false )
					panel:SetExpanded( true )
					panel:DockPadding( 0, 0, 0, 5 )
					panel:SetHeaderHeight( 0 )
					panel:Dock( TOP )
					function panel:Paint( w, h ) paint( self, w, h, color_gray ) end
			return panel
		end

		local generalForm = createSheet( "General", "icon16/cog.png" )

			local hitPosComboBox = generalForm:ComboBox( "Wheel center", mode .. "_pos_type" )
				hitPosComboBox:Dock( TOP )
				hitPosComboBox:SetSortItems( false )
				hitPosComboBox:AddChoice( "Bounding Box Center",	"1" )
				hitPosComboBox:AddChoice( "Coordinates Center",		"2" )
				hitPosComboBox:AddChoice( "Mass Center",			"3" )
				hitPosComboBox:AddChoice( "Hit Position",			"4" )
				generalForm:ControlHelp( "Choose what will be considered as the center of the wheel. If you use the \'Make Spherical\' tool, set this to coordinates center." )

			local snapTypeComboBox = generalForm:ComboBox( "Snap Type", mode .. "_snap_type" )
				snapTypeComboBox:Dock( TOP )
				snapTypeComboBox:SetSortItems( false )
				snapTypeComboBox:AddChoice( "None",							"0", false, "icon16/shape_square.png" )
				snapTypeComboBox:AddChoice( "Prop corners",					"1", false, "icon16/shape_handles.png" )
				snapTypeComboBox:AddChoice( "Prop midpoints",				"2", false, "icon16/shape_align_center.png" )
				snapTypeComboBox:AddChoice( "Prop corners and midpoints",	"3", false, "icon16/shape_ungroup.png" )
				generalForm:ControlHelp( "Choose the way snapping works whenever you click using this tool" )

			local soundCheckBox = generalForm:CheckBox( "Enable sounds", mode .. "_sound" )
				soundCheckBox:SetTooltip( "Enable the beeping sounds when using the tool." )


		local elaForm = createSheet( "Elastic", "icon16/control_eject_blue.png", nil, false, false, "Manage how strong the suspension is." )

			local elaMethodComboBox, wheelCountSlider, wheelCountHelp, staticSagSlider, staticSagHelp, constSlider, constHelp

			local elaPosTypeComboBox = elaForm:ComboBox( "Elastics layout:", mode .. "_elastic_pos_type" )
				elaPosTypeComboBox:Dock( TOP )
				elaPosTypeComboBox:SetSortItems( false )
				elaPosTypeComboBox:AddChoice( "No elastics" )
				elaPosTypeComboBox:AddChoice( "1 Elastic (Centered on wheel)" )
				elaPosTypeComboBox:AddChoice( "2 Elastics (Offset along the wheel's rotation axis" )
				elaPosTypeComboBox:AddChoice( "3 Elastics (Centered + Offset)" )
				elaPosTypeComboBox:SetTooltip( "Choose how many elastics are created and where. Each '*' represents an elastic." )
				elaForm:ControlHelp( "Choose how many elastics are created and where. If you don't use elastics, the suspension won't support the weight of your vehicle." )

				local oldElaPosTypeComboBoxSetValue = elaPosTypeComboBox.SetValue
				function elaPosTypeComboBox.SetValue( ... )
					oldElaPosTypeComboBoxSetValue( ... )

					local b = GetConVar( mode .. "_elastic_pos_type" ):GetInt() ~= 0

					for i, panel in ipairs( elaForm:GetChildren() ) do
						panel:SetVisible( b or i < 4 )
					end

					if b then
						local value = elaMethodComboBox:GetSelected()
						if value then
							elaMethodComboBox:SetValue( value )
						end
					end

					elaForm:InvalidateChildren( true )
				end


				elaForm:Help( "Below you can change the strength of the elastic(s) used for the suspension." )

				elaMethodComboBox = elaForm:ComboBox( "Parameters type", mode .. "_elastic_method" )
					elaMethodComboBox:Dock( TOP )
					elaMethodComboBox:SetSortItems( false )
					elaMethodComboBox:AddChoice( "Stiffness",	"constant", true )
					elaMethodComboBox:AddChoice( "Static sag",	"static_sag" )

					local oldElaMethodComboBoxSetValue = elaMethodComboBox.SetValue
					function elaMethodComboBox.SetValue( ... )
						oldElaMethodComboBoxSetValue( ... )
						local b = "static_sag" == GetConVar( mode .. "_elastic_method" ):GetString()

						staticSagSlider:SetVisible( b )
						staticSagHelp:SetVisible( b )
						wheelCountSlider:SetVisible( b )
						wheelCountHelp:SetVisible( b )
						constSlider:SetVisible( not b )
						constHelp:SetVisible( not b )

						elaForm:InvalidateChildren( true )
					end

					elaForm:ControlHelp( "Choose the way you want to define the suspension's strength." )

				wheelCountSlider = elaForm:NumSlider( "Wheel count", mode .. "_elastic_wheel_count", 1, 12, 0 )
					wheelCountHelp = elaForm:ControlHelp( "The tool needs to account for the number of wheels on your vehicle when calculating the strength of the suspension." )

				staticSagSlider = elaForm:NumSlider( "Static sag", mode .. "_elastic_static_sag", 0.1, 1000, 2 )
					staticSagHelp = elaForm:ControlHelp( "Sets the distance (in hammer units) the vehicle drops under its own weight. Larger number means weaker suspension." )

				constSlider = elaForm:NumSlider( "Stiffness", mode .. "_elastic_constant", 0, 50000, 2 )
					constSlider:SetTooltip( "Directly multiplies the distance-proportional force the elastic applies on the wheel." )
					constHelp = elaForm:ControlHelp( "#tool.elastic.constant.help" )

				dampSlider = elaForm:NumSlider( "#tool.elastic.damping", mode .. "_elastic_damping", 0, 50000, 2)
					dampSlider:SetTooltip( "Slows down any movement of the wheel relative to the vehicle base.\nHigh values of this, relative to your vehicle weight, will cause violent shaking." )
					elaForm:ControlHelp( "#tool.elastic.damping.help" )

				rDampSlider = elaForm:NumSlider("#tool.elastic.rdamping", mode .. "_elastic_rdamping", 0, 50000, 2)
					elaForm:ControlHelp( "Similar to damping, but effect is proportional to the velocity of the wheel relative to the vehicle base. Can cause shaking if too high." )


		local travelForm = createSheet( "Travel", "icon16/arrow_up.png", nil, false, false, "Manage the linear degrees of freedom of the wheel." )
		--"icon16/control_equalizer_blue.png"
		--"icon16/arrow_up.png"
		--"icon16/drive_cd.png"*

			local travelCurvedLastIndex
			local travelLinearLastIndex

			local travelTypeComboBox = travelForm:ComboBox( "Travel path:", mode .. "_tr_type" )
				travelTypeComboBox:Dock( TOP )
				travelTypeComboBox:SetSortItems( false )
				travelTypeComboBox:AddChoice( "Unlimited",	"any" )
				travelTypeComboBox:AddChoice( "Curved",	"curved_rope" )
				travelTypeComboBox:AddChoice( "Linear",	"linear_rope" )

				travelForm:ControlHelp( "Choose how restricted the wheel movement will be." )

				local oldTravelTypeComboBoxSetValue = travelTypeComboBox.SetValue
				function travelTypeComboBox.SetValue( ... )
					oldTravelTypeComboBoxSetValue( ... )

					local tr_type = GetConVar( mode .. "_tr_type" ):GetString()
					local curved, linear = ( tr_type == "curved_rope" ), ( tr_type == "linear_rope" )

					for i, panel in ipairs( travelForm:GetChildren() ) do
						if i > 3 then
							panel:SetVisible(
								( i <= travelCurvedLastIndex and curved )
								or ( i > travelCurvedLastIndex and linear )
							)
						end
						if i >= travelLinearLastIndex then break end
					end

					travelForm:InvalidateChildren( true )
				end


			local offXSlider = travelForm:NumSlider("Arc radius", mode .. "_tr_curved_offx", 40, 2000, 2)
			travelForm:ControlHelp( "Increase this to straighten the travel path." )

			local offYSlider = travelForm:NumSlider("Anchor spacing", mode .. "_tr_curved_offy", 40, 2000, 2)
				offYSlider:SetTooltip( "This is equal to half the distance between the vehicle base anchor points of the two ropes" )
			travelForm:ControlHelp( "Set this to the same as Arc radius for best stability." )

			local stabilityButton = vgui.Create( "DButton" )
				travelForm:AddItem( stabilityButton )
				stabilityButton:SetText( "Stabilize" )
				stabilityButton:DockMargin( 32, 0, 32, 8 )
				stabilityButton:GetParent():DockPadding( 0, 8, 0, 8 )
				function stabilityButton:DoClick()
					local val = offXSlider.Scratch:GetFloatValue()
					offYSlider.Scratch:SetValue( val )
					offYSlider:ValueChanged( val )
				end

			travelCurvedLastIndex = #travelForm:GetChildren()


			travelForm:Help( "Note that the rope sliders used for linear travel have an extension limit, and act as elastics." )

			travelForm:NumSlider( "Rope count", mode .. "_tr_linear_rope_count", 3, 4, 0 )
			travelForm:ControlHelp( "How many ropes are created for the slider. Low count reduces lag and diminishes the problems stated above. If you're not sure, set to 3." )

			travelForm:NumSlider( "Rope length", mode .. "_tr_linear_rope_length", 10, 16000, 0 )
			travelForm:ControlHelp( "How long each of the slider's rope is. Greater rope length will diminish the problems stated above. If you're not sure, set to 5000. Keep below 16000.\n" )

			travelLinearLastIndex = #travelForm:GetChildren()


			local extLimCheckBox = travelForm:CheckBox( "Limit travel distances", mode .. "_limitrope_enabled" )

				extLimCheckBox:DockMargin( 0, 24, 0, 0 )

				function extLimCheckBox:OnChange( bVal ) -- called twice for some reason. might be cause of instant hiding
					for i, panel in ipairs( travelForm:GetChildren() ) do
						if i > travelLinearLastIndex + 2 then
							panel:SetVisible( bVal )
						end
						travelForm:InvalidateChildren( true )
					end
				end

			travelForm:ControlHelp( "Enable this to control how far the suspension can extend. Adds a single rope." )

			travelForm:Help( "Note that the created rope can sometimes 'paralyze' the suspension, making your vehicle tilted on one side." )

			travelForm:NumSlider("Bump travel", mode .. "_limitrope_upper_dist", 0, 200, 2)
			travelForm:ControlHelp("How far the suspension can extend upwards from its resting position.")

			travelForm:NumSlider("Droop travel", mode .. "_limitrope_lower_dist", 0, 200, 2)
			travelForm:ControlHelp("How far the suspension can extend downwards from its resting position.")

			extLimCheckBox:OnChange( extLimCheckBox:GetChecked() )

		local rotForm = createSheet( "Rotation", "icon16/cd.png", nil, false, false, "Manage the rotational degrees of freedom of the wheel." )

			rotForm:Help( "Steering options and more are available here." )

			local aBSPanels

			local rotMethodComboBox = rotForm:ComboBox( "Rotation method:", mode .. "_rot_method" )
				rotMethodComboBox:SetSortItems( false )
				rotMethodComboBox:Dock( TOP )
				rotMethodComboBox:AddChoice(
					"None",
					"none"
				)
				rotMethodComboBox:AddChoice(
					"Use ropes (NOT compatible with all vehicles)",
					"rot_rope"
				)
				rotMethodComboBox:AddChoice(
					"Use adv. ballsockets (NOT workshop compatible)",
					"abs"
				)


				local oldRotMethodComboBoxSetValue = rotMethodComboBox.SetValue
				function rotMethodComboBox.SetValue( ... )
					oldRotMethodComboBoxSetValue( ... )

					local rot_method = GetConVar( mode .. "_rot_method" ):GetString()
					local rot_rope_enabled, abs_enabled = ( rot_method == "rot_rope" ), ( rot_method == "abs" )

					-- dirty hacks
					for i, panel in ipairs( rotForm:GetChildren() ) do
						panel:SetVisible( i < 4 or rot_rope_enabled )
					end

					for i, panel in ipairs( aBSPanels ) do
						panel:SetVisible( i < 4 or abs_enabled )
					end

					rotForm:InvalidateChildren( true )
				end

				rotForm:ControlHelp( "Note that the base GMod Duplicator won't recreate advanced ballsockets properly most of the time." )

				local ABSSliders = {}
				local function updateABSSliders( ... )
					for i, val in ipairs( { ... } ) do
						ABSSliders[ i ]:SetValue( val )
					end
				end

				local aBSPresets = rotForm:ComboBox( "Rotation presets:" )
					aBSPresets:SetSortItems( false )
					aBSPresets:Dock( TOP )
					aBSPresets:AddChoice( "Unlimited",					"any" )
					aBSPresets:AddChoice( "Only allow spin",			"spin" )
					aBSPresets:AddChoice( "Only allow spin and steer",	"steer" )
					aBSPresets:AddChoice( "No rotation",				"none" )

					function aBSPresets:OnSelect( index, value, data )
						if data == "none" then
							updateABSSliders( -0.01, 0.01, 0, -0.01, 0.01, 0, -0.01, 0.01, 0 )
						elseif data == "any" then
							updateABSSliders( -180, 180, 0, -180, 180, 0, -180, 180, 0 )
						elseif data == "spin" then
							updateABSSliders( -180, 180, 0, -0.01, 0.01, 0, -0.01, 0.01, 0 )
						elseif data == "steer" then
							local a = 35
							updateABSSliders( -180, 180, 0, -0.01, 0.01, 0, -a, a, 0 )
						end
					end



				local axisInfo = {
					x = { ord = 1, def = "The 'wheel spin' axis settings, min / max should be set to -180 / 180." },
					y = { ord = 2, def = "The 'tilt' axis settings, min / max should be set to -0.01 / 0.01." },
					z = { ord = 3, def = "The 'steering' axis settings." }
				}

				for _, axis in ipairs( { "z", "x", "y" } ) do
					local i = 3 * axisInfo[ axis ].ord
					local lbl = rotForm:ControlHelp( axisInfo[ axis ].def )
					lbl:DockMargin( 32, 16, 32, 8 )
					ABSSliders[ i - 2 ]	= rotForm:NumSlider( string.upper( axis ) .. " Minimum Rotation", mode .. "_abs_" .. axis .. "min", -180, 180, 2 )
					ABSSliders[ i - 1]	= rotForm:NumSlider( string.upper( axis ) .. " Maximum Rotation", mode .. "_abs_" .. axis .. "max", -180, 180, 2 )
					ABSSliders[ i ]		= rotForm:NumSlider( string.upper( axis ) .. " " .. l( "tool", "hingefriction" ), mode .. "_abs_" .. axis .. "fric", 0, 1000, 2 )
				end

				local ABSColCheckBox = rotForm:CheckBox( "No Collide", mode .. "_abs_nocollide" )
					ABSColCheckBox:SetTooltip( "Disable collisions between the wheel and the vehicle base.")
					ABSColCheckBox:GetParent():DockPadding( 8, 8, 0, 8 )

			aBSPanels = rotForm:GetChildren()

			rotForm:ControlHelp(
				"This option doesn't work properly for some vehicle setups!\nFor this to work, you must:\n- Choose a wheel rotation axis that's perpendicular to your vehicle top axis\n- Choose a travel path (linear or curved)\nOtherwise, here's what will happen:\n- The suspension won't extend\n- The rotation and/or travel path won't be what you expected."
			)

			local rotRopeComboBox, rotRopeLabel = rotForm:ComboBox( "Rotation type:", mode .. "_rot_rope_type" )
				rotRopeLabel:SetWide( 160 )
				rotRopeComboBox:Dock( TOP )
				rotRopeComboBox:SetSortItems( false )
				rotRopeComboBox:AddChoice( "Spin",				"spin" )
				rotRopeComboBox:AddChoice( "Spin and steer",	"steer" )

			rotForm:NumSlider( "Steer angle", mode .. "_rot_rope_steer_ang", 0, 90, 2 )

			rotForm:ControlHelp( "This value is used only if you choose 'Spin and steer'.")


		local powForm = createSheet( "Power", "icon16/cd.png", nil, false, false, "Options to power steering" )


		local visualCTab = vgui.Create( "smart_suspension_control_tab", propertySheet )
			propertySheet:AddSheet( "Visual", visualCTab, "icon16/paintcan.png", false, false, "Manage the appearence of the constraints." )

			visualCTab:Help( "Change the settings below if you want to see what the constraints that make up the suspension look like." )

			addVisuals( visualCTab:ControlPanel( "Elastic appearence", color_blue, color_white ),
				{ cVar = mode .. "_elastic_width", text = "Width" },
				{ cVar = mode .. "_elastic_mat" },
				{ cVar = mode .. "_elastic_color" }
			)

			addVisuals( visualCTab:ControlPanel( "Travel path constraints appearence", color_blue, color_white ),
				{ cVar = mode .. "_tr_width", text = "Width" },
				{ cVar = mode .. "_tr_mat" },
				{ cVar = mode .. "_tr_color" }
			)

			addVisuals( visualCTab:ControlPanel( "Extension rope appearence", color_blue, color_white ),
				{ cVar = mode .. "_limitrope_width", text = "Width" },
				{ cVar = mode .. "_limitrope_mat" },
				{ cVar = mode .. "_limitrope_color" }
			)

			addVisuals( visualCTab:ControlPanel( "Rotation ropes appearence", color_blue, color_white ),
				{ cVar = mode .. "_rot_rope_width", text = "Width" },
				{ cVar = mode .. "_rot_rope_mat" },
				{ cVar = mode .. "_rot_rope_color" }
			)

	end
end
local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file)

TOOL.Category = "Constraints"
TOOL.Name = "#Tool." .. mode .. ".listname"
TOOL.ConfigName = ""

-- Defining conVars and their default values
TOOL.ClientConVar = {

	[ "slider_type" ]		= "rope_4",
	[ "pos_type" ]			= "1",
	[ "snap_type" ]			= "3",
	[ "two_rope_offx" ]		= "500",
	[ "two_rope_offy" ]		= "500",
	[ "four_rope_length" ]	= "150000",
	[ "slider_width" ]		= "0",
	[ "slider_mat" ]		= "cable/rope",
	[ "slider_col" ]		= "#FFFFFF",

	[ "add_limitrope" ]			= "1",
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

	[ "add_ballsocket" ]		= "1",
	[ "ballsocket_friction" ]	= "0",
	[ "ballsocket_nocollide" ]	= "1",

	[ "sound" ]	= "1"
}

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "left_1", stage = 1 },
	{ name = "left_2", stage = 2 },
	{ name = "left_3", stage = 3 },
	{ name = "reload" }
}

TOOL.SuccessSounds = {
	[1] = {name = "buttons/button9.wav",	level = 75,	pitchPercent = 90	},
	[2] = {name = "buttons/button9.wav",	level = 75,	pitchPercent = 110	},
	[3] = {name = "buttons/button15.wav",	level = 75,	pitchPercent = 100	},
	[4] = {name = "buttons/button14.wav",	level = 75,	pitchPercent = 100	}
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
	language.Add( t .. "reload",	"Reset the tool")
end



if SERVER then

	function makeFourRopesSlider(ent1, ent2, bone1, bone2, pos1, dirVectors, length, width, material, color) -- Returns a table of 4 rope constraints

			local slider = {}
			local xvec, yvec = dirVectors[1], dirVectors[2]
			local offsetDirections = { xvec, -xvec, yvec, -yvec }

			for _, direction in pairs( offsetDirections ) do

				local pos2 = pos1 + direction * length

				local localPos1 = ent1:WorldToLocal( pos1 )
				local localPos2 = ent2:WorldToLocal( pos2 )

				local ent1Pos, ent2Pos = ent1:GetPos(), ent2:GetPos()
				ent1:SetPos( vector_origin )
				ent2:SetPos( ent2Pos - ent1Pos )

				local constr = constraint.Rope(ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, true, color )
				table.insert( slider, constr )

				ent1:SetPos( ent1Pos )
				ent2:SetPos( ent2Pos )

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


	function TOOL:makeSuspension() -- Returns a table of ropeconstraints (ropes and/or elastics), but can also return an empty table.

		local sliderType	= self:GetClientInfo( "slider_type" )
		local elasticType	= self:GetClientNumber( "elastic_type" )

		local dirVectors 			= self.dirVectors
		local wheelAxisVec 			= self.wheelAxisVec
		local baseEnt, wheelEnt		= self:GetEnt( 1 ), self:GetEnt( 2 )
		local baseBone, wheelBone	= self:GetBone( 1 ), self:GetBone( 2 )
		local suspensionPos			= self.suspensionPos

		local suspension = {}

		local function getClientColor( cvar )
			local _, col = xpcall( function() return HexToColor( self:GetClientInfo( cvar ) ) end, function () return color_white end )
			return col
		end

		 if sliderType ~= "none" then

			local width	= self:GetClientNumber( "slider_width" )
			local mat	= self:GetClientInfo( "slider_mat" )
			local col	= getClientColor( "slider_col")

			if sliderType == "rope_4" then
				local length = self:GetClientNumber( "four_rope_length" )
				table.Add( suspension, makeFourRopesSlider( wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, length, width, mat, col ) )

			elseif sliderType == "rope_2" then
				local offsetX	= self:GetClientNumber( "two_rope_offx" )
				local offsetY	= self:GetClientNumber( "two_rope_offy" )
				table.Add( suspension, makeTwoRopesSlider( wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, offsetX, offsetY, width, mat, col ) )
			end

		end

		if self:GetClientBool( "add_limitrope" ) then

			local width	= self:GetClientNumber( "limitrope_width" )
			local mat	= self:GetClientInfo( "limitrope_mat" )
			local col	= getClientColor( "limitrope_col")
			local upperDistance	= self:GetClientNumber("limitrope_upper_dist")
			local lowerDistance	= self:GetClientNumber("limitrope_lower_dist")
			local constr = makeLimitRope( wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, lowerDistance, upperDistance, width, mat, col )
			table.insert( suspension, constr )

		end

		if elasticType > 0 then

			local width	= self:GetClientNumber( "elastic_width" )
			local mat	= self:GetClientInfo( "elastic_mat" )
			local col	= getClientColor( "elastic_col")
			local constant	= self:GetClientNumber("elastic_constant")
			local damping	= self:GetClientNumber("elastic_damping")
			local rdamping	= self:GetClientNumber("elastic_rdamping")

			if elasticType ~= 2 then
				local constr = makeElastic( wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, wheelAxisVec, 0, constant, damping, rdamping, width, mat, col )
				table.insert( suspension, constr )
			end

			if elasticType > 1 then
				for _, offsetX in ipairs({-20, 20}) do
					local constr = makeElastic( wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, wheelAxisVec, offsetX, constant, damping, rdamping, width, mat, col )
					table.insert( suspension, constr )
				end
			end

		end


		if self:GetClientBool( "add_ballsocket" ) then

			local friction	= self:GetClientNumber("ballsocket_friction")
			local nocollide	= self:GetClientNumber("ballsocket_nocollide")
			local constr	= makeRotationLimitingAdvBallsocket( wheelEnt, baseEnt, wheelBone, baseBone, wheelAxisVec, friction, nocollide )
			table.insert( suspension, constr )

		end

		return suspension

	end


	function TOOL:getClickPosition( trace )
		local ent = trace.Entity
		local phys = ent:GetPhysicsObjectNum( trace.PhysicsBone )
		local pos_type = self:GetClientNumber( "pos_type" )
		local snap_type = self:GetClientNumber( "snap_type" )
		local edge_snap = bit.band( snap_type, 1 ) == 1
		local centre_snap = bit.band( snap_type, 2 ) == 1

		if pos_type == 1 then
			return ent:LocalToWorld( ent:OBBCenter() )

		elseif pos_type == 2 then
			return ent:GetPos()

		elseif pos_type == 3 then
			return ent:LocalToWorld( phys:GetMassCenter() )

		end

	end


	function TOOL:playSuccessSound()
		local soundId = 1 + self:GetStage()
		if not self:GetClientBool("sound") or soundId > 4 then return false end

		local sound = self.SuccessSounds[soundId]
		self:GetOwner():EmitSound(sound["name"], sound["level"], sound["pitchPercent"])

		return true
	end


	function TOOL:playFailSound()
		if not self:GetClientBool("sound") then return false end

		self:GetOwner():EmitSound("buttons/combine_button7.wav", 100, 100)

		return true
	end


end




function TOOL:LeftClick(trace)

	local stage = self:GetStage()

	local ply = self:GetOwner()
	local ent = trace.Entity

	-- At stage 0 and 2, try to save the hit object.
	if stage == 0 or stage == 2 then

		-- Some checks
		if not ( IsValid(ent) or ent:IsWorld() ) then return false end
		if ent:IsPlayer() then return false end
		if SERVER and not util.IsValidPhysicsObject( ent, trace.PhysicsBone ) then return false end -- If there's no physics object then we can't constraint it! (only check on server?)
		if stage == 2 and ( ent:IsWorld() or ent == self:GetEnt(1) ) then return false end -- The wheel can't be the vehicle base or the world

		-- Saving the entities
		local objId = ( stage == 0 ) and 1 or 2 -- The vehicle base will be saved as Id 1, while the wheel will be saved as Id 2.
		if SERVER then
			ply:SetNW2Entity(mode .. "_ent" .. objId, ent)
			if stage == 2 then
				self.suspensionPos = ent:IsWorld() and trace.HitPos or self:getClickPosition(trace)
				ply:SetNW2Vector(mode .. "_suspension_pos", self.suspensionPos)
			end
			self:playSuccessSound()
		end

		self:SetObject( objId, ent, trace.HitPos, ent:GetPhysicsObjectNum( trace.PhysicsBone ), trace.PhysicsBone, trace.HitNormal )
		self:SetStage( stage + 1 )

		return true

	end

	if not trace.Hit then return false end

	-- At stage 1 and 3, try to save the HitNormal (direction normal to the hit surface).
	if stage == 1 then -- Save suspension up/down direction

		self.zvec = trace.HitNormal

		if SERVER then
			ply:SetNW2Vector(mode .. "_zvec", trace.HitNormal)
			self:playSuccessSound()
			self:SetStage(2)
		end

		return true
	end

	if stage ~= 3 then return false end -- Should not be needed.

	-- Verify that player hasn't hit the rope constraints limit.
	if not ply:CheckLimit( "ropeconstraints" ) then
		self:ClearObjects()
		self:SetStage(0)
		return false
	end

	-- No checks needed clientside anymore
	if CLIENT then return true end
	self:SetStage(4) -- Just here to play the correct sound
	self:playSuccessSound()
	self:SetStage(2) -- prepare for next wheel

	-- Save wheel spin axis, try to create the suspension
	local v = trace.HitNormal
	self.wheelAxisVec = v

	self.yvec = v:Cross( self.zvec )
	if self.yvec:IsZero() then
		if self:GetClientNumber( "slider_type" ) == 2 then
			self:playFailSound()
			ply:ChatPrint("For 2 ropes slider you need to choose a different direction than the top of your vehicle! You can click on the side of your vehicle for example.")
			return false
		end
		self.yvec = getPerpendicularVector( self.zvec )
	end
	self.yvec:Normalize()

	self.xvec = self.zvec:Cross( self.yvec )
	self.xvec:Normalize()

	self.dirVectors = { self.xvec, self.yvec, self.zvec }

	-- Create the suspension.
	suspension = self:makeSuspension()

	-- Verify that at least one constraint is valid, otherwise the suspension creation has completely failed.
	if noValidConstraintInTable( suspension ) then
		self:ClearObjects() -- not called clientside, potential problem
		self:playFailSound()
		ply:ChatPrint("The suspension was not created. Check your settings in the menu.")
		return false
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

	if self:GetClientBool("sound") then ply:EmitSound("buttons/button14.wav", 100, 100) end

	return true

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
	ply:SetNW2Vector(mode .. "_zvec", nil)

	return true
end



if CLIENT then


	local function getVectorDisplayData2D(originPos, vector, start_multiplier, end_multiplier)
		local p1_Scr	= (originPos + vector * start_multiplier):ToScreen()
		local p2_Scr	= (originPos + vector * end_multiplier):ToScreen()
		return p1_Scr, p2_Scr
	end


	-- converts travel distance to arc angle in suspension context
	local function zDistToAngle(length, radius)
		return math.acos(math.Clamp(1 - (length * length) / (2 * radius * radius), -1, 1))
	end

	-- converts the upper and lower extension to a angular range
	local function getSuspensionArcRange( upDist, downDist, radius )
		local upAngle = zDistToAngle( upDist, radius)
		local downAngle = zDistToAngle( downDist, radius)
		return -downAngle, upAngle
	end

	-- custom polar-to-cartesian conversion
	local function getSuspensionArcPoint( center, yvec, zvec, radius, angle )
		return center + radius * ( yvec * math.cos( angle ) + zvec * math.sin( angle ) )
	end

	-- for 2 ropes slider
	function TOOL:drawSuspensionArc( pos, yvec, zvec, radius, upDist, downDist, segments, color )
		color = color or Color( 0, 114, 178 )
		segments = segments or 16
		radius = radius or 40

		local center	= pos - yvec * radius
		local p0_scr = center:ToScreen()
		local arcStart, arcEnd = getSuspensionArcRange( upDist, downDist, radius )
		local angleStep = ( arcEnd - arcStart ) / segments

		for i = 0, segments - 1 do
			local ang = arcStart + i * angleStep

			local p1 = getSuspensionArcPoint( center, yvec, zvec, radius, ang )
			local p2 = getSuspensionArcPoint( center, yvec, zvec, radius, ang + angleStep )

			local p1_scr = p1:ToScreen()
			local p2_scr = p2:ToScreen()

			if ( p1_scr.visible or p2_scr.visible ) then
				surface.SetDrawColor( color )
				surface.DrawLine( p1_scr.x, p1_scr.y, p2_scr.x, p2_scr.y )
				surface.DrawLine( p0_scr.x, p0_scr.y, p1_scr.x, p1_scr.y )
				surface.DrawLine( p0_scr.x, p0_scr.y, p2_scr.x, p2_scr.y )
			end
		end

	end


	-- Not sure how to do this properly.
	function TOOL:DrawHUD()

		local stage = self:GetStage()

		if stage < 1 then return true end

		local ply = self:GetOwner()
		local baseEnt = ply:GetNW2Entity(mode .. "_ent1")
		if not baseEnt:IsValid() then return false end

		-- Draw the indicator for the vehicle base.
		local ent_textcolor	= Color( 255, 240, 220 )
		local black	= Color(0, 0, 0)
		local white = Color(255, 255, 255)
		local baseCenterPos	= baseEnt:LocalToWorld( baseEnt:OBBCenter() )
		local baseData2D	= baseCenterPos:ToScreen()
		if baseData2D.visible then draw.SimpleTextOutlined( "Vehicle entity", "Default", baseData2D.x, baseData2D.y, ent_textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black ) end



		if stage < 2 then return true end

		local zvec = ply:GetNW2Vector(mode .. "_zvec") -- Should verify if this vector is valid.

		if stage == 2 then 		-- Draw the vector normal to the top of the vehicle
			local p1_Scr, p2_Scr = getVectorDisplayData2D(baseCenterPos, zvec, 5, 50)
			if p1_Scr.visible or p2_Scr.visible then
				surface.SetDrawColor( Color(255, 255, 255) )
				surface.DrawLine( p1_Scr.x, p1_Scr.y, p2_Scr.x, p2_Scr.y)
				draw.SimpleTextOutlined( "TOP", "Default", p2_Scr.x, p2_Scr.y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black )
			end
		end



		if stage < 3 then return true end

		-- Draw the suspension position and direction indicators

		local susPos	= ply:GetNW2Vector(mode .. "_suspension_pos") -- Should verify if this vector is valid.
		local susPosScr	= susPos:ToScreen()

		if susPosScr.visible then surface.DrawCircle(susPosScr.x, susPosScr.y, 8, Color(225, 100, 190)) end

		local playerDistance = (susPos - ply:EyePos()):Length()

		local upDist, lowDist = self:GetClientNumber("limitrope_upper_dist"), self:GetClientNumber("limitrope_lower_dist")
		local suspensionAxis = zvec
		local p1_Scr, p2_Scr = getVectorDisplayData2D(susPos, suspensionAxis, -lowDist, upDist)

		if p1_Scr.visible or p2_Scr.visible then
			surface.SetDrawColor( Color(0, 158, 115) )
			surface.DrawLine( p1_Scr.x, p1_Scr.y, p2_Scr.x, p2_Scr.y)
			draw.SimpleTextOutlined( "Suspension (UP)", "Default", p2_Scr.x, p2_Scr.y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black )
		end

		-- Draw the wheel entity

		local wheelEnt = ply:GetNW2Entity(mode .. "_ent2")
		if wheelEnt:IsValid() then
			local wheelData2D = ( wheelEnt:LocalToWorld( wheelEnt:OBBCenter() ) ):ToScreen()
			if wheelData2D.visible then draw.SimpleTextOutlined( "Wheel entity", "Default", wheelData2D.x, wheelData2D.y, ent_textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black ) end
		end

		-- Draw the wheel axis indicator, if possible.

		local eyeTrace = ply:GetEyeTrace()
		if not eyeTrace.Hit then return true end


		if self:GetClientNumber("slider_type") == 2 then
			local radius = self:GetClientNumber("two_rope_offx")
			self:drawSuspensionArc( susPos, eyeTrace.HitNormal, zvec, radius, upDist, lowDist )
		end

		-- If we don't add a ballsocket, we can stop here (we don't need to show the rotation axis of the wheel)

		if not self:GetClientBool( "add_ballsocket" ) then return true end

		local rotationAxis	= eyeTrace.HitNormal * 0.25 * math.Clamp(20, playerDistance, 1000) -- This is the normal vector of the surface the player is looking at, multiplied by player distance
		p1_Scr, p2_Scr = getVectorDisplayData2D(susPos, rotationAxis, -0.1, 1)
		if p1_Scr.visible or p2_Scr.visible then
			surface.SetDrawColor( Color( 240, 228, 66 ) )
			surface.DrawLine( p1_Scr.x, p1_Scr.y, p2_Scr.x, p2_Scr.y)
			draw.SimpleTextOutlined( "Wheel Rotation Axis", "Default", p2_Scr.x, p2_Scr.y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black )
		end

		return true

	end


end


local cvarlist = TOOL:BuildConVarList()
local RopeMaterials = {
	"cable/redlaser",
	"cable/cable2",
	"cable/rope",
	"cable/blue_elec",
	"cable/xbeam",
	"cable/physbeam",
	"cable/hydra"
}

function TOOL.BuildCPanel(CPanel)

	local col_dark_blue = Color(50, 100, 200)
	local col_

	local function paint( panel, w, h, hcol )
		local topHeight = panel:GetHeaderHeight()
		local c = not panel:GetExpanded()
		draw.RoundedBoxEx(4, 0, 0, w, topHeight, hcol or col_dark_blue, true, true, c, c)
		draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
	end

	local function customAddItem( parent, panel )
		panel:Dock( TOP )
		panel:DockMargin( 10, 10, 10, 0 )
		parent:AddItem( panel )
		return panel
	end

	local function customHelp( parent, label )
		local panel = vgui.Create( "DLabel", parent )
			panel:SetText( label )
			panel:SetDark( true )
			panel:SetWrap( true )
			customAddItem( parent, panel )
		return panel
	end

	-- near exact copy from dform.lua
	local function customComboBox( parent, label, strConVar )
		local left = vgui.Create( "DLabel", self )
		left:SetText( label )
		left:SetDark( true )

		local right = vgui.Create( "DComboBox", self )
		right:SetConVar( strConVar )
		right:Dock( TOP )
		function right:OnSelect( _, value, data )
			if not self.m_strConVar then return end
			RunConsoleCommand( self.m_strConVar, tostring( data or value ) )
		end

		parent.Items = {}
		CPanel.AddItem( parent, left, right )

		return right, left

	end

	local function customDForm( parent, label )
		local panel = vgui.Create( "DForm" )
			parent.Items = {}
			CPanel.AddItem( parent, panel )
			panel:SetLabel( label )
			panel:DoExpansion( false )
			panel:SetPaintBackground( false )
		return panel
	end

	local function constrVisualCPanel( parent, label, widthTable, matTable, colTable)

		local panel = vgui.Create( "ControlPanel", parent )
			parent.Items = {}
			CPanel.AddItem( parent, panel )
			panel:SetLabel( label )
			panel:DoExpansion(false)
			panel:SetPaintBackground( false )

			function panel:Paint( w, h ) paint( self, w, h ) end

			local numSlider		= panel:NumSlider( widthTable.text, widthTable.cVar, 0, 20, 2 )
			local matSelect		= panel:MatSelect( matTable.cVar , RopeMaterials, true, 45, 100)
			local colorMixer	= vgui.Create( "DColorMixer", panel )
				panel:AddItem( colorMixer )
				function colorMixer:ValueChanged( col )
					RunConsoleCommand( colTable.cvar, col:ToHex() )
				end

		return panel, numSlider, matSelect, colorCombo

	end


	CPanel:Help("A suspension is made of multiple constraints. With this tool, you can combine them in many different ways!")
	CPanel:Help("First, select your vehicle base and click its top, then you can create as many suspensions as you want by clicking wheels and choosing their rotation axis.")

	CPanel:ToolPresets( mode, cvarlist )

	local propertySheet = vgui.Create( "DPropertySheet", CPanel )
		propertySheet:Dock( TOP )
		propertySheet:SetTall( 320 )
		propertySheet:DockMargin( 10, 10, 10, 0 )

	local sliderOptTab = vgui.Create( "DScrollPanel", propertySheet )
		sliderOptTab:SetPaintBackground( true )
		propertySheet:AddSheet( "Sliding", sliderOptTab )

		customHelp( sliderOptTab, "How the suspension moves." )

		local RSSettForm, RS2SettForm, RS4SettForm
		local sliderTypeComboBox = customComboBox( sliderOptTab, "Slider type:", mode .. "_slider_type" )
			sliderTypeComboBox:SetSortItems( false )
			sliderTypeComboBox:AddChoice("4-Ropes (linear movement)",	"rope_4")
			sliderTypeComboBox:AddChoice("2-Ropes (curved movement)",	"rope_2")
			sliderTypeComboBox:AddChoice("None (any movement)",			"none")
			sliderTypeComboBox:SetTooltip("Choose the type of rope slider")

			--CPanel.ControlHelp( sliderOptTab, "\nThis is the type of slider for the suspension. A 4-ropes slider moves in a straight line, while a 2-ropes slider moves in a curve.\n")
			local f = sliderTypeComboBox.OnSelect
			function sliderTypeComboBox:OnSelect( index, value, data )
				f( self, index, value, data )
				RSSettForm:DoExpansion( data ~= "none" )
				RS2SettForm:DoExpansion( data == "rope_2" )
				RS4SettForm:DoExpansion( data == "rope_4" )
			end

		RSSettForm = customDForm( sliderOptTab, "Rope Slider settings" )

			function RSSettForm:Paint(w, h) paint( self, w, h ) end

			local sliderPosComboBox = customComboBox( RSSettForm, "Slider Position:", mode .. "_pos_type" )
				sliderPosComboBox:SetSortItems( false )
				sliderPosComboBox:AddChoice("Bounding Box Center",	"1")
				sliderPosComboBox:AddChoice("Coordinates Center",	"2")
				sliderPosComboBox:AddChoice("Mass center",			"3")
				sliderPosComboBox:SetTooltip("Choose where the slider is created")
				RSSettForm:ControlHelp("\nChoose where on the wheel the rope slider is attached. If you use the \"Make Spherical\" tool, I recommend setting this to coordinates center.\n\n" )


		RS2SettForm = customDForm( sliderOptTab, "2-Ropes Slider settings" )

			function RS2SettForm:Paint(w, h) paint( self, w, h ) end

			RS2SettForm:Help("The options below only affect 2-ropes 'sliders'. \nKeep them at around the same value for best stability.")

			local offXSlider = RS2SettForm:NumSlider("Offset X", mode .. "_two_rope_offx", 40, 2000, 2)
				offXSlider:SetTooltip("Changes the rope X offset")
				RS2SettForm:ControlHelp("Increase to make the slider move less in a curve and more in a straight line.\n" )

			local offYSlider = RS2SettForm:NumSlider("Offset Y", mode .. "_two_rope_offy", 40, 2000, 2)
				offYSlider:SetTooltip("Changes the rope Y offset")
				RS2SettForm:ControlHelp("Set to around the same as Offset X for best stability.\n" )


		RS4SettForm = customDForm( sliderOptTab, "4-Ropes Slider settings" )

			function RS4SettForm:Paint( w, h ) paint( self, w, h ) end

			RS4SettForm:Help("The option below only affects 4-ropes sliders.")

			local NumSlider = RS4SettForm:NumSlider( "Rope length", mode .. "_four_rope_length", 10, 16000, 0 )
				NumSlider:SetTooltip( "Changes the length of the slider's 4 ropes.\nThe shorter, the stiffer the suspension.\nHigh values (16000+ ?) will overflow and can actually lead to shorter ropes." )
				RS4SettForm:ControlHelp( "Use higher numbers to let the suspension extend farther.\n" )

		constrVisualCPanel( sliderOptTab, "Slider appearence",
			{ cvar = mode .. "_slider_width", text = "Slider Width" },
			{ cvar = mode .. "_slider_mat" },
			{ cvar = mode .. "_slider_color" }
		)


	local extOptTab = vgui.Create( "DScrollPanel", propertySheet )
		extOptTab:SetPaintBackground( true )
		propertySheet:AddSheet( "Extension", extOptTab )

		customHelp( extOptTab, "How far the suspension can extend.")

		local extLimCheckBox = vgui.Create( "DCheckBoxLabel", extOptTab )
			extLimCheckBox:SetConVar( mode .. "_add_limitrope" )
			extLimCheckBox:SetText( "Limit the suspension extension" )
			extLimCheckBox:SetDark( true )
			customAddItem( extOptTab, extLimCheckBox )

			--extOptTab:ControlHelp("If this is checked, a rope will be added to control how far the suspension can extend.")

		local extSettForm = customDForm( extOptTab, "Extension settings" )

			function extSettForm:Paint(w, h) paint( self, w, h ) end

			function extLimCheckBox:OnChange( bVal )
				extSettForm:DoExpansion( bVal )
			end

			local upperExtSlider = extSettForm:NumSlider("Upper extension", mode .. "_limitrope_upper_dist", 0.01, 200, 2)
				upperExtSlider:SetTooltip("How far the suspension can extend upwards")

			local lowerExtSlider = extSettForm:NumSlider("Lower extension", mode .. "_limitrope_lower_dist", 0.01, 200, 2)
				lowerExtSlider:SetTooltip("How far the suspension can extend downwards")

		constrVisualCPanel( extOptTab, "Extension rope appearence",
			{ cvar = mode .. "_limitrope_width", text = "Width" },
			{ cvar = mode .. "_limitrope_mat" },
			{ cvar = mode .. "_limitrope_color" }
		)


	local elaOptTab = vgui.Create( "DScrollPanel", propertySheet )
		elaOptTab:SetPaintBackground( true )
		propertySheet:AddSheet( "Elasticity", elaOptTab )

		customHelp( elaOptTab, "How strong the suspension is." )

		local elaSettForm
		local elaCountComboBox = customComboBox( elaOptTab, "Number of elastics:", mode .. "_elastic_type" )
			elaCountComboBox:SetSortItems( false )
			elaCountComboBox:AddChoice("0 (   ): None",					"0")
			elaCountComboBox:AddChoice("1 ( * ): Centered",				"1")
			elaCountComboBox:AddChoice("2 (* *): Offset",				"2")
			elaCountComboBox:AddChoice("3 (***): Centered + Offset",	"3")
			elaCountComboBox:SetTooltip("Choose how many elastics are created and where. Each '*' represents an elastic.")
			--elaOptTab:ControlHelp("\nChoose how many elastics are created and where. If you don't use elastics, the suspension won't support the weight of your vehicle.\n")

			local g = elaCountComboBox.OnSelect
			function elaCountComboBox:OnSelect( index, value, data )
				g( self, index, value, data )
				elaSettForm:DoExpansion( data ~= "0" )
			end

		elaSettForm = customDForm( elaOptTab, "Elastic settings" )

			function elaSettForm:Paint(w, h) paint( self, w, h ) end

			elaSettForm:Help("Below you can change the strength of the elastic(s). High values can make your vehicle violently shake, especially if you use props that are too light.")

			elaSettForm:NumSlider("#tool.elastic.constant", mode .. "_elastic_constant", 0, 50000, 2)
				elaSettForm:ControlHelp("#tool.elastic.constant.help")

			elaSettForm:NumSlider("#tool.elastic.damping", mode .. "_elastic_damping", 0, 5000, 2)
				elaSettForm:ControlHelp("#tool.elastic.damping.help")

			elaSettForm:NumSlider("#tool.elastic.rdamping", mode .. "_elastic_rdamping", 0, 2500, 2)
				elaSettForm:ControlHelp("#tool.elastic.rdamping.help")

		constrVisualCPanel( elaOptTab, "Elastic appearence",
			{ cvar = mode .. "_elastic_width", text = "Width" },
			{ cvar = mode .. "_elastic_mat" },
			{ cvar = mode .. "_elastic_color" }
		)


	local ABSOptTab = vgui.Create( "DScrollPanel", propertySheet )
		ABSOptTab:SetPaintBackground( true )
		propertySheet:AddSheet( "Rotation", ABSOptTab )
		customHelp( ABSOptTab, "Manage the rotation of the wheel." )

		local ABSAddCheckBox = vgui.Create( "DCheckBoxLabel", ABSOptTab )
			ABSAddCheckBox:SetConVar( mode .. "_add_ballsocket" )
			ABSAddCheckBox:SetText( "Add advanced ballsocket" )
			ABSAddCheckBox:SetDark( true )
			customAddItem( ABSOptTab, ABSAddCheckBox )

			--ABSOptTab:ControlHelp("If this is checked, your wheel rotation will be limited to a single axis relative to your vehicle base prop. This is done using an advanced ballsocket.")

		local ABSSettForm = customDForm( ABSOptTab, "Adv. ballsocket settings" )

			function ABSSettForm:Paint(w, h) paint( self, w, h ) end

			function ABSAddCheckBox:OnChange(bVal)
				ABSSettForm:DoExpansion( bVal )
			end

			ABSSettForm:NumSlider("#tool.hingefriction", mode .. "_ballsocket_friction", 0, 50000, 2)

			ABSSettForm:CheckBox("No Collide", mode .. "_ballsocket_nocollide")
				ABSSettForm:ControlHelp("#tool.nocollide.help")


	local otherOptTab = customDForm( CPanel, "Other options" )

		otherOptTab:CheckBox("Enable sounds", mode .. "_sound")
			otherOptTab:ControlHelp( "If you uncheck this, you won't hear the beeping sounds when using the tool." )

end
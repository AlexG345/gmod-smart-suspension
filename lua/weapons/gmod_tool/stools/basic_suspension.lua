local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file) 

TOOL.Category = "Constraints"
TOOL.Name = "#Tool."..mode..".listname"
TOOL.ConfigName = ""

-- Defining conVars and their default values
TOOL.ClientConVar[ "ropeslider_type" ]		= "1"
TOOL.ClientConVar[ "pos_type" ]				= "1"
TOOL.ClientConVar[ "two_rope_offx" ]		= "500"
TOOL.ClientConVar[ "two_rope_offy" ]		= "500"

TOOL.ClientConVar[ "add_limitrope" ]		= "1"
TOOL.ClientConVar[ "limitrope_upper_dist" ]	= "24"
TOOL.ClientConVar[ "limitrope_lower_dist" ]	= "24"

TOOL.ClientConVar[ "elastic_type" ]	= "3"
TOOL.ClientConVar[ "elastic_constant" ]		= "12000"
TOOL.ClientConVar[ "elastic_damping" ]		= "300"
TOOL.ClientConVar[ "elastic_rdamping" ]		= "100"

TOOL.ClientConVar[ "add_ballsocket" ]		= "1"
TOOL.ClientConVar[ "ballsocket_friction" ]	= "0"
TOOL.ClientConVar[ "ballsocket_nocollide" ]	= "1"
--[[ UNUSED
TOOL.ClientConVar[ "add_axis" ]				= "1"
TOOL.ClientConVar[ "axis_friction" ]		= "0"
]]
TOOL.ClientConVar[ "rope_material" ]		= "cable/rope"
TOOL.ClientConVar[ "ropeslider_width" ]		= "0"
TOOL.ClientConVar[ "limitrope_width" ]		= "0"
TOOL.ClientConVar[ "elastic_width" ]		= "0"
TOOL.ClientConVar[ "rope_color_r" ]			= "255"
TOOL.ClientConVar[ "rope_color_g" ]			= "255"
TOOL.ClientConVar[ "rope_color_b" ]			= "255"

TOOL.ClientConVar[ "sound" ]				= "1"


TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "left_1", stage = 1 },
	{ name = "left_2", stage = 2 },
	{ name = "left_3", stage = 3 },
	{ name = "reload" }
}

TOOL.SuccessSounds = {
	[1] = {soundName = "buttons/button9.wav",	soundLevel = 75,	pitchPercent = 90	},
	[2] = {soundName = "buttons/button9.wav",	soundLevel = 75,	pitchPercent = 110	},
	[3] = {soundName = "buttons/button15.wav",	soundLevel = 75,	pitchPercent = 100	},
	[4] = {soundName = "buttons/button14.wav",	soundLevel = 75,	pitchPercent = 100	}
}


if CLIENT then
	language.Add( "tool."..mode..".listname",	"Smart Suspension" )
	language.Add( "tool."..mode..".name",		"Smart Suspension" )
	language.Add( "tool."..mode..".desc",		"Allows you to create Suspensions (or any of its components) between wheels and a vehicle base." )
	language.Add( "tool."..mode..".left",		"Select the vehicle base object" )
	language.Add( "tool."..mode..".left_1",		"Click on a surface paralell to the TOP of your vehicle" )
	language.Add( "tool."..mode..".left_2",		"Select a wheel (not the vehicle base) to start a Suspension" )
	language.Add( "tool."..mode..".left_3",		"Click on a surface perpendicular to your wheel axis of rotation to finish this Suspension" )
	language.Add( "tool."..mode..".reload",		"Reset the tool")
end




local function getFourRopesSlider(ent1, ent2, bone1, bone2, pos1, dirVectors, length, width, material, color) -- Returns a table of 4 rope constraints
		
		local slider = {}
		local xvec = dirVectors[1]
		local yvec = dirVectors[2]
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




local function getTwoRopesSlider(ent1, ent2, bone1, bone2, pos1, dirVectors, offsetX, offsetY, width, material, color) -- Returns a table of 2 rope constraints
		
		local slider = {}
		local xvec = dirVectors[1]
		local yvec = dirVectors[2]
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




local function getLimitRope(ent1, ent2, bone1, bone2, pos, dirVectors, lowerDistance, upperDistance, width, material, color) -- Returns a rope constraint
	
	local xvec		= dirVectors[1]
	local zvec		= dirVectors[3]
	
	local pos1		= pos + xvec * 5 -- This rope causes problems such as suspension locking, offsetting the rope along xvec helps fix this issue.
	
	local posDiff	= zvec * ( upperDistance - lowerDistance ) / 2
	local pos2 		= pos1 + posDiff
	
	local length	= math.abs( upperDistance + lowerDistance ) / 2
	
	local localPos1	= ent1:WorldToLocal( pos1 )
	local localPos2	= ent2:WorldToLocal( pos2 )
	
	return constraint.Rope(ent1, ent2, bone1, bone2, localPos1, localPos2, length, 0, 0, width, material, false, color)
	
end


-- This is not very clear but rotationAxis is the axis of the wheel.

local function getElastic(ent1, ent2, bone1, bone2, pos, rotationAxis, offsetX, constant, damping, rdamping, width, material, color) -- Returns an elastic constraint whose local positions are the same world positions
	
	local elastic_pos	= pos + offsetX * rotationAxis -- The limit rope causes problems such as suspension locking, offsetting the elastic along xvec helps fix this issue.
	
	local localPos1		= ent1:WorldToLocal( elastic_pos )
	local localPos2		= ent2:WorldToLocal( elastic_pos )
	
	return constraint.Elastic(ent1, ent2, bone1, bone2, localPos1, localPos2, constant, damping, rdamping, material, width, false, color)
	
end




local function getRotationLimitingAdvBallsocket(ent1, ent2, bone1, bone2, rotationAxis, friction, nocollide)
    
	-- ent1 will only be able to turn along rotationAxis relative to ent2.
	local rotAxisAngle	= rotationAxis:Angle()
	
	 -- The only way I found to rotate the entities the same amount was to use this function, Euler Angles addition didn't work for this.
	local newAngle1		= ent1:AlignAngles(rotAxisAngle, angle_zero)
	local newAngle2		= ent2:AlignAngles(rotAxisAngle, angle_zero)
	
	-- Save the entities initial angles
	local startAngle1 = ent1:GetAngles()
    local startAngle2 = ent2:GetAngles()
	
    -- Rotate both entities
    ent1:SetAngles(newAngle1)
    ent2:SetAngles(newAngle2)
	
    -- The positions values are not very important since onlyrotation = true, here we use the coordinates center
    local localPos1 = ent1:WorldToLocal(ent1:GetPos())
    local localPos2 = ent2:WorldToLocal(ent2:GetPos())

    -- Create the advanced ballsocket that will limit the axis of rotation (of ent1 relative to ent2) to rotationAxis
    local constr = constraint.AdvBallsocket(ent1, ent2, bone1, bone2, localPos1, localPos2, 0, 0, -180, -0.01, -0.01, 180, 0.01, 0.01, friction, 0, 0, 1, nocollide)

    -- Rotate the entities back to their initial angles
    ent1:SetAngles(startAngle1)
    ent2:SetAngles(startAngle2)

    -- Return the created constraint in case it is needed
    return constr
end




local function noValidConstraintInTable(constraints) -- Returns true if no constraints are valid in a table of constraints.
	
	for _, constr in pairs( constraints ) do
	
		if IsValid(constr) then return false end
	
	end
	
	return true
end




function TOOL:getSuspension() -- Returns a table of ropeconstraints (ropes and/or elastics), but can also return an empty table.
	
	local ropeSlider_type	= self:GetClientNumber( "ropeslider_type" )
	local add_limitRope		= self:GetClientBool( "add_limitrope" )
	local elastic_type		= self:GetClientNumber( "elastic_type" )
	local add_ballsocket	= self:GetClientBool( "add_ballsocket" )
	local add_axis			= self:GetClientBool( "add_axis" )
	
	local material	= self:GetClientInfo( "rope_material" )
	local width		= self:GetClientNumber( "ropeslider_width" )
	
	
	local colorR	= self:GetClientNumber( "rope_color_r" )
	local colorG	= self:GetClientNumber( "rope_color_g" )
	local colorB	= self:GetClientNumber( "rope_color_b" )
	local color		= Color( colorR, colorG, colorB )
	
	local dirVectors 			= self.dirVectors
	local wheelAxisVec 			= self.wheelAxisVec
	local baseEnt, wheelEnt		= self:GetEnt( 1 ), self:GetEnt( 2 )
	local baseBone, wheelBone	= self:GetBone( 1 ), self:GetBone( 2 )
	local suspensionPos			= self.suspensionPos
	
	if ropeSlider_type == 1 then -- This type of slider uses four ropes.
		
		suspension = getFourRopesSlider(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, 150000, width, material, color)
		
	elseif ropeSlider_type == 2 then -- This type of slider uses two ropes.
		
		local offsetX	= self:GetClientNumber("two_rope_offx")
		local offsetY	= self:GetClientNumber("two_rope_offy")
		suspension = getTwoRopesSlider(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, offsetX, offsetY, width, material, color)
	
	else suspension = {} end
	
	if add_limitRope then
		
		local upperDistance	= self:GetClientNumber("limitrope_upper_dist")
		local lowerDistance	= self:GetClientNumber("limitrope_lower_dist")
		local width	= self:GetClientNumber( "limitrope_width" )
		constr = getLimitRope(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, lowerDistance, upperDistance, width, material, color)
		table.insert(suspension, constr)
		
	end
	
	if elastic_type > 1 then
		local constant	= self:GetClientNumber("elastic_constant")
		local damping	= self:GetClientNumber("elastic_damping")
		local rdamping	= self:GetClientNumber("elastic_rdamping")
		local width	= self:GetClientNumber( "elastic_width" )		

	
		if !( elastic_type == 3 ) then
			constr = getElastic(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, wheelAxisVec, 0, constant, damping, rdamping, width, material, color)
			table.insert(suspension, constr)
		end
	
		if elastic_type > 2 then
			for _, offsetX in pairs({-20, 20}) do
				constr = getElastic(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, wheelAxisVec, offsetX, constant, damping, rdamping, width, material, color)
				table.insert(suspension, constr)
			end
		end
	end
	
	if add_ballsocket then
		
		local friction	= self:GetClientNumber("ballsocket_friction")
		local nocollide	= self:GetClientNumber("ballsocket_nocollide")
		constr = getRotationLimitingAdvBallsocket(wheelEnt, baseEnt, wheelBone, baseBone, wheelAxisVec, friction, nocollide)
		table.insert(suspension, constr)
	
	end

	--[[ UNUSED
	if add_axis then

		local ply	= self:GetOwner()
		ply:ChatPrint(tostring(wheelAxisVec))
		local localPos1 = wheelEnt:WorldToLocal(suspensionPos)
		local localPos2 = baseEnt:WorldToLocal(suspensionPos + wheelAxisVec) -- not used in the constraint creation
		local localAxis = wheelEnt:GetPhysicsObject():WorldToLocalVector(wheelAxisVec)
		local friction	= self:GetClientNumber("axis_friction")
		constr = constraint.Axis(wheelEnt, baseEnt, wheelBone, baseBone, localPos1, localPos2, 0, 0, friction, 1, localAxis)
		table.insert(suspension, constr)
	
	end
	]]
	
	return suspension
	
end




function TOOL:playSuccessSound()
	local soundId		= 1 + self:GetStage()
	local soundEnabled	= self:GetClientBool("sound")
	
	if !soundEnabled || soundId > 4 then return false end
	
	local ply	= self:GetOwner()
	local sound = self.SuccessSounds[soundId]
	
	ply:EmitSound(sound["soundName"], sound["soundLevel"], sound["pitchPercent"])
	
	return true
end




function TOOL:playFailSound()
	local soundEnabled	= self:GetClientBool("sound")
	
	if !soundEnabled then return false end
	
	local ply = self:GetOwner()
	
	ply:EmitSound("buttons/combine_button7.wav", 100, 100)
	
	return true
end




function TOOL:getClickPosition( trace )
	local ent = trace.Entity
	local phys = ent:GetPhysicsObjectNum( trace.PhysicsBone )
	local pos_type = self:GetClientNumber( "pos_type" )
	
	if pos_type == 1 then
		return ent:LocalToWorld( ent:OBBCenter() )
	
	elseif pos_type == 2 then
		return ent:GetPos()
	
	elseif pos_type == 3 then
		return ent:LocalToWorld( phys:GetMassCenter() )
	
	end

end




function TOOL:LeftClick(trace)
	
	local stage = self:GetStage()
	local iNum = self:NumObjects()
	local soundEnabled = self:GetClientBool("sound")
	
	local ply = self:GetOwner()
	
	-- Try to save the hit object,
	if stage == 0 || stage == 2 then
		
		-- Don't use the player as a wheel or vehicle
		if IsValid(trace.Entity) && trace.Entity:IsPlayer() then return false end
		
		-- If there's no physics object then we can't constraint it!
		if SERVER && !util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then return false end
		
		-- The the vehicle base and the wheel can't be the world
		if trace.Entity:IsWorld() then return false end
		
		if stage == 2 then -- The vehicle base can't be the wheel.
			if trace.Entity == self:GetEnt(1) then return false end
			self.suspensionPos = self:getClickPosition(trace)
		end
		
		-- Network some variables (This is necessary in singleplayer but I don't know if it is in multiplayer.)
		if SERVER then
			if stage == 0 then ply:SetNW2Entity(mode.."_ent1", trace.Entity) end
			if stage == 2 then
				ply:SetNW2Entity(mode.."_ent2", trace.Entity)
				ply:SetNW2Vector(mode.."_suspension_pos", self.suspensionPos)
			end
		end
		
		self:playSuccessSound()
		
		-- Save the hit object
		local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		objId = ( stage == 0 ) and 1 or 2	-- The vehicle base will be saved as Id 1, while the wheel will be saved as Id 2.
		self:SetObject( objId, trace.Entity, trace.HitPos, phys, trace.PhysicsBone, trace.HitNormal )
		self:SetStage( stage + 1 )
		return true
	
	
	-- or try to save the HitNormal (direction normal to the hit surface).
	elseif ( stage == 1 ) or (  stage == 3 ) then
		
		if !trace.Hit then return false end
			
		if stage == 1 then
			
			self.zvec = trace.HitNormal
			if SERVER then ply:SetNW2Vector(mode.."_zvec", trace.HitNormal) end
			
			self:playSuccessSound()
			self:SetStage(2)
			
			return true
		
		end
			
		if trace.HitNormal == self.zvec then 
			self:playFailSound()
			ply:ChatPrint("Please choose a different direction than the top of your vehicle! Click on the side of your vehicle for example.")
			return false
		end
		
		self.yvec = trace.HitNormal:Cross(self.zvec)
		self.yvec:Normalize()
		
		self.xvec = self.zvec:Cross(self.yvec)
		self.xvec:Normalize()
		
		self.dirVectors = { self.xvec, self.yvec, self.zvec }
		self.wheelAxisVec = trace.HitNormal
		
		self:playSuccessSound()
		self:SetStage(2)
			
	end
	
	-- Verify that player hasn't hit the rope constraints limit.
	if ( !ply:CheckLimit( "ropeconstraints" ) ) then
		self:ClearObjects()
		return false
	end
	
	-- Client doesn't need to do the rest. (only useful for multiplayer?)
	if CLIENT then
		if ( stage > 2 ) then return true end
	end
	
	
	-- Create the suspension.
	suspension = self:getSuspension()
	
	
	-- Verify that at least one constraint is valid, otherwise the suspension creation has completely failed.
	if noValidConstraintInTable( suspension ) then
		self:ClearObjects()
		self:playFailSound()
		ply:ChatPrint("The suspension was not created. Check your settings in the menu.")
		return false
	end
	
	-- Add the suspension to the undo list, register it in ropeconstraints cleanup, add it to the ropeconstraints count.
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
	
	if soundEnabled then ply:EmitSound("buttons/button14.wav", 100, 100) end
	
	return true
	
end




function TOOL:Reload(trace)
    self:ClearObjects()
    return true
end




function TOOL:Holster()

	self:ClearObjects()
	if !SERVER then return true end
	
	local ply = self:GetOwner()
    
	if !IsValid(ply) then return false end
		
	ply:SetNW2Entity(mode.."_ent1", nil)
	ply:SetNW2Entity(mode.."_ent2", nil)
	ply:SetNW2Vector(mode.."_ent2_pos", nil)
	ply:SetNW2Vector(mode.."_zvec", nil)
	
	return true
end


local function getVectorDisplayData2D(originPos, vector, start_multiplier, end_multiplier)
	local lineP1Data2D	= (originPos + vector * start_multiplier):ToScreen()
	local lineP2Data2D	= (originPos + vector * end_multiplier):ToScreen()
	return lineP1Data2D, lineP2Data2D
end

-- Not sure how to do this properly.
function TOOL:DrawHUD()
	
	if SERVER then return false end
	
	local stage = self:GetStage()
	
	if stage < 1 then return true end
	
	
	local ply = self:GetOwner()
	local baseEnt = ply:GetNW2Entity(mode.."_ent1")
	if !baseEnt:IsValid() then return false end
	
	-- Draw the indicator for the vehicle base.
	local ent_textcolor	= Color( 255, 240, 220 )
	local black	= Color(0, 0, 0)
	local white = Color(255, 255, 255)
	local baseCenterPos	= baseEnt:LocalToWorld( baseEnt:OBBCenter() )
	local baseData2D	= baseCenterPos:ToScreen()
	if baseData2D.visible then draw.SimpleTextOutlined( "Vehicle entity", "Default", baseData2D.x, baseData2D.y, ent_textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black ) end
	
	
	
	if stage < 2 then return true end
	
	local zvec = ply:GetNW2Vector(mode.."_zvec") -- Should verify if this vector is valid.
	
	if stage == 2 then 		-- Draw the vector normal to the top of the vehicle
		lineP1Data2D, lineP2Data2D = getVectorDisplayData2D(baseCenterPos, zvec, 5, 50)
		if lineP1Data2D.visible || lineP2Data2D.visible then
			surface.SetDrawColor( Color(255, 255, 255) )
			surface.DrawLine( lineP1Data2D.x, lineP1Data2D.y, lineP2Data2D.x, lineP2Data2D.y)
			draw.SimpleTextOutlined( "TOP", "Default", lineP2Data2D.x, lineP2Data2D.y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black )
		end
	end
	
	
	
	if stage < 3 then return true end
	
	-- Draw the suspension position and direction indicators
	
	local suspensionPos		= ply:GetNW2Vector(mode.."_suspension_pos") -- Should verify if this vector is valid.
	local suspensionData2D	= suspensionPos:ToScreen()
	
	if suspensionData2D.visible then surface.DrawCircle(suspensionData2D.x, suspensionData2D.y, 10, Color(200, 0, 0)) end
	
	local playerDistance = (suspensionPos - ply:EyePos()):Length()
	local suspensionAxis = zvec * 0.3 * math.Clamp(20, playerDistance, 1000)
	local lineP1Data2D, lineP2Data2D = getVectorDisplayData2D(suspensionPos, suspensionAxis, 0, 1)
	
	if lineP1Data2D.visible || lineP2Data2D.visible then
		surface.SetDrawColor( Color(255, 255, 255) )
		surface.DrawLine( lineP1Data2D.x, lineP1Data2D.y, lineP2Data2D.x, lineP2Data2D.y)
		draw.SimpleTextOutlined( "Suspension Direction", "Default", lineP2Data2D.x, lineP2Data2D.y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black )
	end
	
	-- Draw the wheel entity
	
	local wheelEnt = ply:GetNW2Entity(mode.."_ent2")
	if wheelEnt:IsValid() then
		local wheelData2D = ( wheelEnt:LocalToWorld( wheelEnt:OBBCenter() ) ):ToScreen()
		if wheelData2D.visible then draw.SimpleTextOutlined( "Wheel entity", "Default", wheelData2D.x, wheelData2D.y, ent_textcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, black ) end
	end
	
	 -- If we don't add a ballsocket, we can stop here (we don't need to show the rotation axis of the wheel)
	
	if !self:GetClientBool( "add_ballsocket" ) then return true end
	
	-- Draw the wheel axis indicator, if possible.
	
	local eyeTrace = ply:GetEyeTrace()
	if !eyeTrace.Hit then return true end
	
	local rotationAxis	= eyeTrace.HitNormal * 0.25 * math.Clamp(20, playerDistance, 1000) -- This is the normal vector of the surface the player is looking at, multiplied by player distance
	lineP1Data2D, lineP2Data2D = getVectorDisplayData2D(suspensionPos, rotationAxis, -1, 1)
	
	if lineP1Data2D.visible || lineP2Data2D.visible then
		surface.SetDrawColor( Color( 255, 0, 0 ) )
		surface.DrawLine( lineP1Data2D.x, lineP1Data2D.y, lineP2Data2D.x, lineP2Data2D.y)
		draw.SimpleTextOutlined( "Wheel Rotation Axis", "Default", lineP2Data2D.x, lineP2Data2D.y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black )
	end
	
	return true
	
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
	
	
	CPanel:Help("A suspension is made of multiple constraints. With this tool, you can combine them in many different ways!")
	CPanel:Help("First, select your vehicle base and click its top, then you can create as many suspensions as you want by clicking the wheel and choosing its rotation axis.")
	
	
	-- Presets picker
	
	local ToolPresets = CPanel:ToolPresets( mode, cvarlist )
	
	
	-- Suspension slider options
	
	local Form1 = vgui.Create("DForm")
	CPanel:AddItem(Form1)
	Form1:SetLabel("Slider options")
	Form1:DoExpansion(false)
	Form1:SetPaintBackground( false )
	
	
	Form1:Help("How the suspension moves.")
	
	
	local ComboBox1 = Form1:ComboBox( "Slider type:", mode.."_ropeslider_type")
	ComboBox1:SetSortItems( false )
	ComboBox1:AddChoice("4-Ropes (straight)",	"1")
	ComboBox1:AddChoice("2-Ropes (curved)",		"2")
	ComboBox1:AddChoice("None (no slider)",		"3")
	ComboBox1:SetToolTip("Choose the type of rope slider")
	ComboBox1:Dock(TOP)
	
	Form1:ControlHelp("\nThis is the type of slider for the suspension. A 4-ropes slider moves in a straight line, while a 2-ropes slider moves in a curve.\n\n")
	
	
	local ComboBox2 = Form1:ComboBox( "Slider Position:", mode.."_pos_type" )
	ComboBox2:SetSortItems( false )
	ComboBox2:AddChoice("Bounding Box Center",	"1")
	ComboBox2:AddChoice("Coordinates Center",	"2")
	ComboBox2:AddChoice("Mass center",			"3")
	ComboBox2:SetToolTip("Choose where the slider is created")
	ComboBox2:Dock(TOP)
	
	Form1:ControlHelp("\nChoose where on the wheel the rope slider is attached. If you use the \"Make Spherical\" tool, I recommend setting this to coordinates center.\n\n" )
	
	
	local Form1_1 = vgui.Create("DForm")
	Form1:AddItem(Form1_1)
	Form1_1:SetLabel("2-Ropes Sliders settings")
	Form1_1:DoExpansion(false)
	Form1_1:SetPaintBackground( false )
	
	function Form1_1:Paint(w, h)
		local topHeight = self:GetHeaderHeight()
		if self:GetExpanded() then
			draw.RoundedBoxEx(4, 0, 0, w, topHeight, Color(50, 100, 200), true, true, false, false)
		else
			draw.RoundedBox(4, 0, 0, w, topHeight, Color(50, 100, 200))
		end
		draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
	end
-- Could be used to expand Form1_1 when 2-Ropes slider gets selected,
-- however it stops ToolPresets from changing the Combobox displayed value.
-- I couldn't find a way to easily fix this issue, so instead the function below is unused.
-- function ComboBox1:OnSelect(index, value, data) Form1_1:DoExpansion( data == "2" ) end
	
	
	Form1_1:Help("The options below are for 2-ropes sliders only. \nKeep them at around the same values. Increase both to make the 2-ropes slider move less in a curve and more in a straight line.")
	
	
	local NumSlider = Form1_1:NumSlider("Offset X", mode.."_two_rope_offx", 40, 2000, 2)
	NumSlider:SetToolTip("Changes the rope X offset")
	
	Form1_1:ControlHelp("Use higher numbers for a wider slider.\n" )
	
	
	local NumSlider = Form1_1:NumSlider("Offset Y", mode.."_two_rope_offy", 40, 2000, 2)
	NumSlider:SetToolTip("Changes the rope Y offset")
	
	Form1_1:ControlHelp("Use higher numbers for a narrower slider.\n" )
	
	
	-- Suspension extension options
	
	local Form2 = vgui.Create("DForm")
	CPanel:AddItem(Form2)
	Form2:SetLabel("Extension options")
	Form2:DoExpansion(false)
	Form2:SetPaintBackground( false )
	
	
	Form2:Help("How far the suspension can extend.")
	
	
	local CheckBox = Form2:CheckBox("Limit the suspension extension", mode.."_add_limitrope")
		
	Form2:ControlHelp("If this is checked, a rope will be added to control how far the suspension can extend.")
	
	
	local Form2_1 = vgui.Create("DForm")
	Form2:AddItem(Form2_1)
	Form2_1:SetLabel("Extension settings")
	Form2_1:DoExpansion(false)
	Form2_1:SetPaintBackground( false )
	
	function Form2_1:Paint(w, h)
		local topHeight = self:GetHeaderHeight()
		if self:GetExpanded() then
			draw.RoundedBoxEx(4, 0, 0, w, topHeight, Color(50, 100, 200), true, true, false, false)
		else
			draw.RoundedBox(4, 0, 0, w, topHeight, Color(50, 100, 200))
		end
		draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
	end
	function CheckBox:OnChange(bVal) Form2_1:DoExpansion( bVal ) end
	
	
	local NumSlider = Form2_1:NumSlider("Upper extension", mode.."_limitrope_upper_dist", 0.01, 200, 2)
	NumSlider:SetToolTip("How far the suspension can extend upwards")
	
	
	local NumSlider = Form2_1:NumSlider("Lower extension", mode.."_limitrope_lower_dist", 0.01, 200, 2)
	NumSlider:SetToolTip("How far the suspension can extend downwards")
	
	
	-- Suspension elastic options
	
	local Form3 = vgui.Create("DForm")
	CPanel:AddItem(Form3)
	Form3:SetLabel("Elastics options")
	Form3:DoExpansion(false)
	Form3:SetPaintBackground( false )
	
	
	Form3:Help("How strong the suspension is.")
	
	
	local ComboBox = Form3:ComboBox( "Elastics type:", mode.."_elastic_type" )
	ComboBox:SetSortItems( false )
	ComboBox:AddChoice("None (no elastics)",				"1")
	ComboBox:AddChoice("1 Elastic (Centered)",				"2")
	ComboBox:AddChoice("2 Elastics (Offset)",				"3")
	ComboBox:AddChoice("3 Elastics (Centered + Offset)",	"4")
	ComboBox:SetToolTip("Choose how many elastics are created and where.")
	ComboBox:Dock(TOP)
	
	Form3:ControlHelp("\nChoose how many elastics are created and where. If you don't use elastics, the suspension won't support the weight of your vehicle.\n")
	
	
	Form3:Help("Below you can change the strength of the elastic(s). High values can make your vehicle violently shake, especially if you use props that are too light.")
	
	
	Form3:NumSlider("#tool.elastic.constant", mode.."_elastic_constant", 0, 50000, 2)
	
	Form3:ControlHelp("#tool.elastic.constant.help")
	
	
	Form3:NumSlider("#tool.elastic.damping", mode.."_elastic_damping", 0, 5000, 2)
	
	Form3:ControlHelp("#tool.elastic.damping.help")
	
	
	Form3:NumSlider("#tool.elastic.rdamping", mode.."_elastic_rdamping", 0, 2500, 2)
	
	Form3:ControlHelp("#tool.elastic.rdamping.help")
	
	
	-- Suspension advanced ballsocket options
	
	local Form4 = vgui.Create("DForm")
	CPanel:AddItem(Form4)
	Form4:SetLabel("Advanced ballsocket options")
	Form4:DoExpansion(false)
	Form4:SetPaintBackground( false )
	
	Form4:Help("Can manage the rotation of the wheel.")
	
	
	Form4:CheckBox("Add advanced ballsocket", mode.."_add_ballsocket")
	
	Form4:ControlHelp("If this is checked, your wheel rotation will be limited to a single axis relative to your vehicle base prop. This is done using an advanced ballsocket.")

	Form4:NumSlider("#tool.hingefriction", mode.."_ballsocket_friction", 0, 50000, 2)

	Form4:CheckBox("No Collide", mode.."_ballsocket_nocollide")
	
	Form4:ControlHelp("#tool.nocollide.help")
	
	--[[ UNUSED
	-- Suspension axis options
	
	local Form4 = vgui.Create("DForm")
	CPanel:AddItem(Form4)
	Form4:SetLabel("Axis options")
	Form4:DoExpansion(false)
	Form4:SetPaintBackground( false )
	
	Form4:Help("Can manage the rotation of the wheel.")
	
	
	Form4:CheckBox("Add axis", mode.."_add_axis")
	
	Form4:ControlHelp("If this is checked, your wheel rotation will be limited to a single axis relative to your vehicle base prop. This is done using an axis.")

	
	Form4:NumSlider("#tool.hingefriction", mode.."_axis_friction", 0, 50000, 2)
	
	Form4:ControlHelp("#tool.hingefriction.help")
	]]
	
	-- Suspension visual settings
	
	local CPanel1 = vgui.Create("ControlPanel")
	CPanel:AddItem(CPanel1)
	CPanel1:SetLabel("Suspension visual settings")
	CPanel1:DoExpansion(false)
	CPanel1:SetPaintBackground( false )
	
	
	CPanel1:Help("I recommend setting the constraints widths to 0 to hide them.\n")
	
	
	CPanel1:NumSlider("Slider Rope Width", mode.."_ropeslider_width", 0, 20, 2)
	
	CPanel1:ControlHelp("The width of the ropes that make up the slider of the suspension")
	
	
	CPanel1:NumSlider("Extension Rope Width", mode.."_limitrope_width", 0, 20, 2)
	
	CPanel1:ControlHelp("The width of the rope that limits the extension of the suspension")
	
	
	CPanel1:NumSlider("Elastic Width", mode.."_elastic_width", 0, 20, 2)
	
	CPanel1:ControlHelp("The width of the suspension's elastic")
	
	
	CPanel1:Help("Constraints Material:")
	CPanel1:MatSelect( mode.."_rope_material", RopeMaterials, true, 45, 100)
	
	CPanel1:ColorPicker("Constraints Color:", mode.."_rope_color_r", mode.."_rope_color_g", mode.."_rope_color_b")
	
	
	-- Other options (sound)
	
	local Form5 = vgui.Create("DForm")
	CPanel:AddItem(Form5)
	Form5:SetLabel("Other options")
	Form5:DoExpansion(false)
	Form5:SetPaintBackground( false )
	
	
	Form5:CheckBox("Enable sounds", mode.."_sound")
	Form5:ControlHelp( "If you uncheck this, you won't hear the beeping sounds when using the tool." )
	
end
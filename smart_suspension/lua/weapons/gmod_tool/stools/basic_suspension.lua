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
	[1] = {name = "buttons/button9.wav",	level = 75,	pitchPercent = 90	},
	[2] = {name = "buttons/button9.wav",	level = 75,	pitchPercent = 110	},
	[3] = {name = "buttons/button15.wav",	level = 75,	pitchPercent = 100	},
	[4] = {name = "buttons/button14.wav",	level = 75,	pitchPercent = 100	}
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



if SERVER then

	function TOOL:makeSuspension() -- Returns a table of ropeconstraints (ropes and/or elastics), but can also return an empty table.
		
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
		 -- This type of slider uses four ropes.
		if ropeSlider_type == 1 then
			suspension = makeFourRopesSlider(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, 150000, width, material, color)
			
		elseif ropeSlider_type == 2 then -- This type of slider uses two ropes.
			local offsetX	= self:GetClientNumber("two_rope_offx")
			local offsetY	= self:GetClientNumber("two_rope_offy")
			suspension = makeTwoRopesSlider(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, offsetX, offsetY, width, material, color)
		
		else suspension = {} end
		
		if add_limitRope then
			local upperDistance	= self:GetClientNumber("limitrope_upper_dist")
			local lowerDistance	= self:GetClientNumber("limitrope_lower_dist")
			local width	= self:GetClientNumber( "limitrope_width" )
			constr = makeLimitRope(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, dirVectors, lowerDistance, upperDistance, width, material, color)
			table.insert(suspension, constr)
			
		end
		
		if elastic_type > 1 then
			local constant	= self:GetClientNumber("elastic_constant")
			local damping	= self:GetClientNumber("elastic_damping")
			local rdamping	= self:GetClientNumber("elastic_rdamping")
			local width	= self:GetClientNumber( "elastic_width" )		

		
			if !( elastic_type == 3 ) then
				constr = makeElastic(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, wheelAxisVec, 0, constant, damping, rdamping, width, material, color)
				table.insert(suspension, constr)
			end
		
			if elastic_type > 2 then
				for _, offsetX in pairs({-20, 20}) do
					constr = makeElastic(wheelEnt, baseEnt, wheelBone, baseBone, suspensionPos, wheelAxisVec, offsetX, constant, damping, rdamping, width, material, color)
					table.insert(suspension, constr)
				end
			end
		end
		
		if add_ballsocket then
			
			local friction	= self:GetClientNumber("ballsocket_friction")
			local nocollide	= self:GetClientNumber("ballsocket_nocollide")
			constr = makeRotationLimitingAdvBallsocket(wheelEnt, baseEnt, wheelBone, baseBone, wheelAxisVec, friction, nocollide)
			table.insert(suspension, constr)
		
		end
		
		return suspension
		
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
	local iNum = self:NumObjects()
	
	local ply = self:GetOwner()
	local ent = trace.Entity

	-- At stage 0 and 2, try to save the hit object.
	if stage == 0 or stage == 2 then
		
		-- Some checks
		if not IsValid(ent) then return false end
		if ent:IsPlayer() or ent:IsWorld() then return false end
		if SERVER and !util.IsValidPhysicsObject(ent, trace.PhysicsBone) then return false end -- If there's no physics object then we can't constraint it! (only check on server?)
		if stage == 2 and ent == self:GetEnt(1) then return false end -- The vehicle base can't be the wheel.
		
		-- Saving the entities
		local objId = ( stage == 0 ) and 1 or 2 -- The vehicle base will be saved as Id 1, while the wheel will be saved as Id 2.
		if SERVER then
			ply:SetNW2Entity(mode.."_ent"..objId, ent)
			if stage == 2 then
				self.suspensionPos = self:getClickPosition(trace)
				ply:SetNW2Vector(mode.."_suspension_pos", self.suspensionPos)
			end
			self:playSuccessSound()
		end
		
		self:SetObject( objId, ent, trace.HitPos, ent:GetPhysicsObjectNum( trace.PhysicsBone ), trace.PhysicsBone, trace.HitNormal )
		self:SetStage( stage + 1 )
		
		return true
	
	end
	
	if !trace.Hit then return false end
	
	-- At stage 1 and 3, try to save the HitNormal (direction normal to the hit surface).
	if stage == 1 then -- Save suspension up/down direction

		self.zvec = trace.HitNormal
		
		if SERVER then
			ply:SetNW2Vector(mode.."_zvec", trace.HitNormal)
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
		if self:GetClientNumber( "ropeslider_type" ) == 2 then
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
	CPanel:Help("First, select your vehicle base and click its top, then you can create as many suspensions as you want by clicking wheels and choosing their rotation axis.")
	
	
	-- Presets picker
	CPanel:ToolPresets( mode, cvarlist )
	
	-- Suspension slider options
	local Form1 = vgui.Create("DForm")
		CPanel:AddItem(Form1)
		Form1:SetLabel("Slider options")
		Form1:DoExpansion(false)
		Form1:SetPaintBackground( false )
		
		Form1:Help("How the suspension moves.")
		
		local ComboBox1 = Form1:ComboBox( "Slider type:", mode.."_ropeslider_type")
		 	-- Save now. If saved a few dozen lines below, sliderTypeFunc doesn't change the convar.
			local sliderTypeFunc = ComboBox1["OnSelect"] -- Use a complicated name to limit risk of override ?
			ComboBox1:SetSortItems( false )
			ComboBox1:AddChoice("4-Ropes (straight)",	"1")
			ComboBox1:AddChoice("2-Ropes (curved)",		"2")
			ComboBox1:AddChoice("None (no slider)",		"3")
			ComboBox1:SetToolTip("Choose the type of rope slider")
			ComboBox1:Dock(TOP)
			Form1:ControlHelp("\nThis is the type of slider for the suspension. A 4-ropes slider moves in a straight line, while a 2-ropes slider moves in a curve.\n")
		
		local Form1_1 = vgui.Create("DForm")
			Form1:AddItem(Form1_1)
			Form1_1:SetLabel("Rope Slider settings")
			Form1_1:DoExpansion(false)
			Form1_1:SetPaintBackground( false )
			
			function Form1_1:Paint(w, h)
				local topHeight = self:GetHeaderHeight()
				local c = not self:GetExpanded()
				draw.RoundedBoxEx(4, 0, 0, w, topHeight, Color(50, 100, 200), true, true, c, c)
				draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
			end

			local ComboBox2 = Form1_1:ComboBox( "Slider Position:", mode.."_pos_type" )
				ComboBox2:SetSortItems( false )
				ComboBox2:AddChoice("Bounding Box Center",	"1")
				ComboBox2:AddChoice("Coordinates Center",	"2")
				ComboBox2:AddChoice("Mass center",			"3")
				ComboBox2:SetToolTip("Choose where the slider is created")
				ComboBox2:Dock(TOP)
				Form1_1:ControlHelp("\nChoose where on the wheel the rope slider is attached. If you use the \"Make Spherical\" tool, I recommend setting this to coordinates center.\n\n" )


		local Form1_2 = vgui.Create("DForm")
			Form1:AddItem(Form1_2)
			Form1_2:SetLabel("2-Ropes Slider settings")
			Form1_2:DoExpansion(false)
			Form1_2:SetPaintBackground( false )
			
			function Form1_2:Paint(w, h)
				local topHeight = self:GetHeaderHeight()
				local c = not self:GetExpanded()
				draw.RoundedBoxEx(4, 0, 0, w, topHeight, Color(50, 100, 200), true, true, c, c)
				draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
			end

			Form1_2:Help("The options below are for 2-ropes sliders only. \nKeep them at around the same values. Increase both to make the 2-ropes slider move less in a curve and more in a straight line.")

			local NumSlider = Form1_2:NumSlider("Offset X", mode.."_two_rope_offx", 40, 2000, 2)
				NumSlider:SetToolTip("Changes the rope X offset")
				Form1_2:ControlHelp("Use higher numbers for a wider slider.\n" )
			
			local NumSlider = Form1_2:NumSlider("Offset Y", mode.."_two_rope_offy", 40, 2000, 2)
				NumSlider:SetToolTip("Changes the rope Y offset")
				Form1_2:ControlHelp("Use higher numbers for a narrower slider.\n" )
		
		
		function ComboBox1:OnSelect( index, value, data )
			if sliderTypeFunc then sliderTypeFunc( self, index, value, data ) end -- changes the convar
			Form1_1:DoExpansion( data != "3" )
			Form1_2:DoExpansion( data == "2" )
		end

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
				local c = not self:GetExpanded()
				draw.RoundedBoxEx(4, 0, 0, w, topHeight, Color(50, 100, 200), true, true, c, c)
				draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
			end
			function CheckBox:OnChange( bVal )
				Form2_1:DoExpansion( bVal )
			end
			
			local numSlider = Form2_1:NumSlider("Upper extension", mode.."_limitrope_upper_dist", 0.01, 200, 2)
				numSlider:SetToolTip("How far the suspension can extend upwards")
			
			local numSlider = Form2_1:NumSlider("Lower extension", mode.."_limitrope_lower_dist", 0.01, 200, 2)
				numSlider:SetToolTip("How far the suspension can extend downwards")
		
	-- Suspension elastic options
	local Form3 = vgui.Create("DForm")
		CPanel:AddItem(Form3)
		Form3:SetLabel("Elastics options")
		Form3:DoExpansion(false)
		Form3:SetPaintBackground( false )
		
		Form3:Help("How strong the suspension is.")
		
		local ComboBox = Form3:ComboBox( "Number of elastics:", mode.."_elastic_type" )
			local elasticTypeFunc = ComboBox["OnSelect"]
			ComboBox:SetSortItems( false )
			ComboBox:AddChoice("0 (   ): None","1")
			ComboBox:AddChoice("1 ( * ): Centered",				"2")
			ComboBox:AddChoice("2 (* *): Offset",				"3")
			ComboBox:AddChoice("3 (***): Centered + Offset",	"4")
			ComboBox:SetToolTip("Choose how many elastics are created and where. Each '*' represents an elastic.")
			ComboBox:Dock(TOP)
			Form3:ControlHelp("\nChoose how many elastics are created and where. If you don't use elastics, the suspension won't support the weight of your vehicle.\n")
		
		local Form3_1 = vgui.Create("DForm")
			Form3:AddItem(Form3_1)
			Form3_1:SetLabel("Elastics settings")
			Form3_1:DoExpansion(false)
			Form3_1:SetPaintBackground( false )
			
			function Form3_1:Paint(w, h)
				local topHeight = self:GetHeaderHeight()
				local c = not self:GetExpanded()
				draw.RoundedBoxEx(4, 0, 0, w, topHeight, Color(50, 100, 200), true, true, c, c)
				draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
			end
			
			function ComboBox:OnSelect( index, value, data )
				if elasticTypeFunc then elasticTypeFunc( self, index, value, data ) end
				Form3_1:DoExpansion( data != "1" )
			end

			Form3_1:Help("Below you can change the strength of the elastic(s). High values can make your vehicle violently shake, especially if you use props that are too light.")

			Form3_1:NumSlider("#tool.elastic.constant", mode.."_elastic_constant", 0, 50000, 2)
				Form3_1:ControlHelp("#tool.elastic.constant.help")
			
			Form3_1:NumSlider("#tool.elastic.damping", mode.."_elastic_damping", 0, 5000, 2)
				Form3_1:ControlHelp("#tool.elastic.damping.help")
			
			Form3_1:NumSlider("#tool.elastic.rdamping", mode.."_elastic_rdamping", 0, 2500, 2)
				Form3_1:ControlHelp("#tool.elastic.rdamping.help")
	
	-- Suspension advanced ballsocket options
	local Form4 = vgui.Create("DForm")
		CPanel:AddItem(Form4)
		Form4:SetLabel("Advanced ballsocket options")
		Form4:DoExpansion(false)
		Form4:SetPaintBackground( false )
		Form4:Help("Can manage the rotation of the wheel.")
		
		local CheckBox = Form4:CheckBox("Add advanced ballsocket", mode.."_add_ballsocket")
			Form4:ControlHelp("If this is checked, your wheel rotation will be limited to a single axis relative to your vehicle base prop. This is done using an advanced ballsocket.")
		
		local Form4_1 = vgui.Create("DForm")
			Form4:AddItem(Form4_1)
			Form4_1:SetLabel("Adv. ballsocket settings")
			Form4_1:DoExpansion(false)
			Form4_1:SetPaintBackground( false )
			
			function Form4_1:Paint(w, h)
				local topHeight = self:GetHeaderHeight()
				local c = not self:GetExpanded()
				draw.RoundedBoxEx(4, 0, 0, w, topHeight, Color(50, 100, 200), true, true, c, c)
				draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, Color(240, 240, 240), false, false, true, true)
			end
			
			function CheckBox:OnChange(bVal)
				Form4_1:DoExpansion( bVal )
			end
		
			Form4_1:NumSlider("#tool.hingefriction", mode.."_ballsocket_friction", 0, 50000, 2)

			Form4_1:CheckBox("No Collide", mode.."_ballsocket_nocollide")
				Form4_1:ControlHelp("#tool.nocollide.help")
	
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
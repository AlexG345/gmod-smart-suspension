local PANEL = {}


function PANEL:Init()
	self:SetPaintBackground( true )
end


function PANEL:AddItem( left, right, noPadding )

	local canvas = self:GetCanvas()
	local panel = vgui.Create( "DSizeToContents", canvas ) -- don't parent to self or it crashes
		panel:SetSizeX( false )
		panel:Dock( TOP )
		if not noPadding then panel:DockPadding( 10, 10, 10, 0 ) end
		panel:InvalidateLayout()

	left:SetParent( panel )

	if ( IsValid( right ) ) then

		left:Dock( LEFT )
		left:InvalidateLayout( true )
		left:SetSize( 100, 20 )

		right:SetParent( panel )
		right:SetPos( 110, 0 )
		right:InvalidateLayout( true )

	elseif ( IsValid( left ) ) then

		left:Dock( TOP )

	end

	return left, right

end


function PANEL:CheckBox( strLabel, strConVar )

	local left = vgui.Create( "DCheckBoxLabel", self )
	left:SetText( strLabel )
	left:SetDark( true )
	left:SetConVar( strConVar )

	return left

end


function PANEL:ComboBox( strLabel, strConVar )
	local left = vgui.Create( "DLabel" )
		left:SetText( strLabel )
		left:SetDark( true )

	local right = vgui.Create( "DComboBox" )
		right:SetConVar( strConVar )
		right:Dock( TOP )
		function right:OnSelect( _, value, data )
			if not self.m_strConVar then return end
			RunConsoleCommand( self.m_strConVar, tostring( data or value ) )
		end

	self:AddItem( left, right )
	return right, left

end


function PANEL:CollapsibleCategoryBased( class, label, hcol, bgcol, image )
	local panel = vgui.Create( class )
		self:AddItem( panel )
		panel:SetLabel( label )
		panel:SetExpanded( false )
		panel:DoExpansion( false )
		if hcol and bgcol then
			panel:SetPaintBackground( false )
			function panel:Paint( w, h )
				local topHeight = panel:GetHeaderHeight()
				local c = not panel:GetExpanded()
				draw.RoundedBoxEx(4, 0, 0, w, topHeight, hcol, true, true, c, c)
				draw.RoundedBoxEx(8, 0, topHeight, w, h - topHeight, bgcol, false, false, true, true)
			end
		end
	return panel
end


function PANEL:ControlPanel( ... )
	return self:CollapsibleCategoryBased( "ControlPanel",  ... )
end


function PANEL:Form( ... )
	return self:CollapsibleCategoryBased( "DForm",  ... )
end


function PANEL:Help( strLabel, margin, color, alignment )
	local panel = vgui.Create( "DLabel" )
		panel:SetDark( true )
		panel:SetWrap( true )
		panel:SetTextInset( 0, 0 )
		panel:SetText( strLabel )
		panel:SetContentAlignment( alignment or 7 )
		panel:SetAutoStretchVertical( true )
		panel:DockMargin( unpack( margin or { 8, 8, 8, 8 } ) )
		if color then panel:SetTextColor( color ) end
	return self:AddItem( panel, nil, true )
end


function PANEL:ControlHelp( strLabel )
	return self:Help( strLabel, { 32, 8, 32, 8 }, self:GetSkin().Colours.Tree.Hover, 5 )
end


derma.DefineControl( "DControlTab", "", PANEL, "DScrollPanel")
-- "A scroll panel with helper functions. This is from the Smart Suspension addon.""
--Created by Mka0207 ( Scott Grissinger )
--License here : https://creativecommons.org/licenses/by-nc/3.0/

local PANEL = {}
local h_offset = 40

PANEL.RefreshTime = 5
PANEL.NextRefresh = 0

local PropDataContainer = {}

function PANEL:Init()
	self:DockMargin(0, 0, 0, 0)
	self:DockPadding(0, 0, 0, 0)

	PropDataContainer = {}

	self:ParentToHUD()
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	local screenscale = BetterScreenScale()

	self:SetSize(screenscale * 312, screenscale * 600)

	self:AlignLeft(40)
	self:AlignTop(h_offset)
end

local y_offset = 0
local y_offset2 = 0
local y_offset3 = 0

local y_spacing = 10
local colNail = Color(0, 0, 5, 220)
local x_txt_offset = -20
local x_icon_offset = 40

function PANEL:PushPropData()
	for _, pnls in ipairs( self:GetChildren() ) do
		pnls:Remove()
	end

	local screenscale_sized = 64 * BetterScreenScale()

	y_offset = screenscale_sized
	y_offset2 = screenscale_sized
	y_offset3 = screenscale_sized
	
	local _ = 0
	for prop, bol in pairs( PropDataContainer ) do
		if prop and prop:IsValid() and #prop:GetChildren() > 0 then

			_ = _ + 1

			local PropFrame = vgui.Create("ModelImage", self)
			if _ <= 6 then
				PropFrame:SetPos(0,y_offset)
			elseif _ > 6 and _ < 13 then
				PropFrame:SetPos(screenscale_sized+x_icon_offset,y_offset2)
			elseif _ > 12 then
				PropFrame:SetPos(screenscale_sized+( x_icon_offset * 3.5 ),y_offset3)
			end

			PropFrame:SetSize(screenscale_sized,screenscale_sized)
			PropFrame:SetModel( prop:GetModel() )
			PropFrame.SavedProp = prop

			--local OldPaintOver = PropFrame.PaintOver
			PropFrame.PaintOver = function(pnl,w,h)
				--OldPaintOver(pnl,w,h)
				local screenscale = BetterScreenScale()

				if ( prop and prop:IsValid() ) and #prop:GetChildren() > 0 then
					if prop:GetChildren()[1] and prop:GetChildren()[1]:IsValid() then
						local nail = prop:GetChildren()[1]
						local nhp = nail:GetNailHealth()
						local mnhp = nail:GetMaxNailHealth()
						local repairs = nail:GetRepairs()
						local mrps = nail:GetMaxRepairs()
						
						if mrps > 0 or mnhp > 0 then
							local mu = math.Clamp(nhp / mnhp, 0, 1)
							local green = mu * 200
							colNail.r = 200 - green
							colNail.g = green
							colNail.a = 240
							
							DisableClipping(true)
							surface.SetFont( "ZSHUDFontTinyerX2" )
							surface.SetTextColor( colNail )
							surface.SetTextPos( x_txt_offset*screenscale, 0 )
							surface.DrawText( math.floor( prop:GetChildren()[1]:GetNailHealth() ) )

							surface.SetFont( "ZSHUDFontTinyerX2" )
							surface.SetTextColor( 5, 247, 227 )
							surface.SetTextPos( x_txt_offset*screenscale, 16 )
							surface.DrawText( math.floor( prop:GetChildren()[1]:GetRepairs() ) )
							DisableClipping(false)
						end
					end
				end
			end
		end
		
		if _ <= 6 then
			y_offset = y_offset + screenscale_sized + y_spacing
		elseif _ > 6 and _ < 13 then
			y_offset2 = y_offset2 + screenscale_sized + y_spacing
		elseif _ > 12 then
			y_offset3 = y_offset3 + screenscale_sized + y_spacing
		end
	end
end

function PANEL:Paint(w, h)
end
vgui.Register("ZS_PropJournal", PANEL, "Panel")

--debug tool
concommand.Add( "reload_props", function( pl, cmd, args )
	if GAMEMODE.PropJournal then
		GAMEMODE.PropJournal:Remove()
		GAMEMODE.PropJournal = nil
	else
		GAMEMODE.PropJournal = vgui.Create("ZS_PropJournal")
	end
end )

net.Receive( "zs_nail_destroyed", function( len, pl )
	--print("nailed destryoed")
	if ( IsValid( pl ) and pl:IsPlayer() ) then
		print( "Message from " .. pl:Nick() .. " received. Its length is " .. len .. "." )
	else
		local prop = net.ReadEntity()
		local nailcount = net.ReadInt(5)
		print(nailcount)
		if #GAMEMODE.PropJournal:GetChildren() > 0 then
			for cid, pnls in ipairs( GAMEMODE.PropJournal:GetChildren() ) do
				if pnls.SavedProp == prop and nailcount <= 0 then
					PropDataContainer[ prop ] = nil
					GAMEMODE.PropJournal:PushPropData()
					pnls:Remove()
				end
			end
		end
	end
end )

hook.Add( "KeyPress", "ZS.PropJournalCheck.KeyPress", function( ply, key )
	if ply:IsValid() then
		if GAMEMODE.PropJournal then
			local trace_ent = ply:GetEyeTrace().Entity
			if trace_ent and trace_ent:IsValid() then
				if trace_ent:IsNailed() then
					if #trace_ent:GetChildren() > 0 then
						local nail = trace_ent:GetChildren()[1]
						if nail and nail:IsValid() then
							if nail:GetDeployer() == ply then
								if key == IN_USE and IsFirstTimePredicted() then
									if not PropDataContainer[ nail:GetBaseEntity() ] and #table.GetKeys(PropDataContainer) < 18 then
										PropDataContainer[ nail:GetBaseEntity() ] = true
										GAMEMODE.PropJournal:PushPropData()
									else
										PropDataContainer[ nail:GetBaseEntity() ] = nil
										GAMEMODE.PropJournal:PushPropData()
									end
								end
							end
						end
					end
				end
			end
			
			if ply:IsValidHuman() and ply:KeyDown(IN_SPEED) and ply:KeyDown(IN_RELOAD) and ply:KeyDown(IN_USE) or ply:IsValidZombie() then
				if #table.GetKeys(PropDataContainer) > 0 then
					PropDataContainer = {}
				end

				if #GAMEMODE.PropJournal:GetChildren() > 0 then
					for cid, pnls in ipairs( GAMEMODE.PropJournal:GetChildren() ) do
						pnls:Remove()
					end
				end
			end
		end
	end
end )
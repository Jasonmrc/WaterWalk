--	WaterWalk by JasonMRC of Problem Solvers.

class 'WaterWalk'

function WaterWalk:__init()
	self.Name						=	"Water-Walk"		--	The name of this Surface Class.												Default: "Water-Walk"
	self.ActivationCommand			=	"waterwalk"			--	The chat command to activate this Surface Class.							Default: "waterwalk"
	self.ValueString				=	"Water-Walk"		--	The String Value this Surface Class is bound to.							Default: "WaterWalk"
	self.DisplayScreenNotification	=	true				--	Should a display be shown on the player's screen indicating this is active?	Default: true
	self.FontSize					=	14					--	The size of the indicator text saying that this Surface Class is active.	Default: 14
	self.LocalDisplayAnchor			=	Vector2(0.5, 0.025)	--	Screen notification display psotion.										Default: Vector2(0.5, 0.025)
	self.SurfaceHeight				=	199.99				--	The exact elevation of the Surface from the bottom of the world.			Default: 199.96
	self.UnderWaterOffset			=	0.1575				--	Offset when underwater to make sure the surface is below the player. 		Default: 0.1575
	self.MaxDistance				=	50					--	Maximum distance the Surface can be from the player before forcing a rebuild. This is to guarantee the surface is near them.	Default: 50
	
	--	The model and collision of the Surface. Leave the model as "" to be invisible.
	self.Model		=	""										--	Default: ""
	self.Collision	=	"areaset01.blz/gb245_lod1-d_col.pfx"	--	Default: "areaset01.blz/gb245_lod1-d_col.pfx"
	
	--	Table of Vehicles which when occupied will pause the Walk's effectiveness.
	self.NoSurfaceVehicles	=	{80, 88, 16, 5, 27, 38, 6, 19, 45, 28, 53, 25, 69, 5}
	self.Surfaces	=	{}
	
	self.Version	=	1.0	--	Do not change.
	
	Events:Subscribe("Render", self, self.Render)
	Events:Subscribe("PreTick", self, self.PreTick)
	Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
	Events:Subscribe("ModuleUnload", self, self.RemoveAllSurfaces)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
end

function WaterWalk:PlayerQuit(args)
	self:Remove(args.player)
end

function WaterWalk:Master(player)
	if player:GetValue(self.ValueString) then
		local PlayerVehicle		=	player:GetVehicle()
		if IsValid(PlayerVehicle) then
			local PlayerVehicleID	=	PlayerVehicle:GetModelId()
			if self:CheckList(self.NoSurfaceVehicles, PlayerVehicleID) then
				self:Remove(player)
				return
			end
		end
		self:Move(player)
	else
		self:Remove(player)
	end
end

function WaterWalk:Create(player)
	local Position	=	self:Position(player)
	local Surface	=	ClientStaticObject.Create({
							position = Position.Position,
							angle = Position.Angle,
							model = self.Model,
							collision = self.Collision
													})
	self.Surfaces[player:GetId()]	=	Surface
end

function WaterWalk:Move(player)
	local Surface	=	self.Surfaces[player:GetId()]
	if not IsValid(Surface) then
		self:Create(player)
		return
	end
	if Vector3.Distance(Surface:GetPosition(), player:GetPosition()) >= self.MaxDistance then
		if self:Remove(player) then
			self:Create(player)
		end
	end
	
	local Position	=	self:Position(player)
	Surface:SetPosition(Position.Position)
	Surface:SetAngle(Position.Angle)
end

function WaterWalk:Position(player)
	local Anchor				=	self:Anchor(player)
	local PlayerPosition		=	Anchor:GetPosition()
	local PlayerAngle			=	Anchor:GetAngle()
	local EffectiveAngle		=	Angle(0, 0, 0)
	local EffectiveHeight		=	self.SurfaceHeight
	
	if player:GetState() == 1
	or player:GetState() == 2
	or player:GetState() == 3
	or player:GetState() == 5
	then
		EffectiveAngle		=	Angle(PlayerAngle.yaw, 0, 0) * Angle(math.pi * 1.5, 0, 0)
	end
	if PlayerPosition.y < EffectiveHeight + self.UnderWaterOffset and not player:InVehicle() then
		EffectiveHeight	=	PlayerPosition.y - 1
	end
	
	local Speed	=	math.clamp(player:GetLinearVelocity():Length(), 0, 40)
	if Speed > 5 then
		local SpeedRatio	=	Speed / 150
		EffectiveHeight	=	EffectiveHeight + SpeedRatio
	end
	
	local EffectivePosition	=	Vector3(PlayerPosition.x, EffectiveHeight, PlayerPosition.z)
	
	return {Position = EffectivePosition, Angle = EffectiveAngle}
end

function WaterWalk:Remove(player)
	if IsValid(self.Surfaces[player:GetId()]) then
		self.Surfaces[player:GetId()]:Remove()
		self.Surfaces[player:GetId()]	=	nil
	end
	return true
end

function WaterWalk:Anchor(player)
	local PlayerVehicle		=	player:GetVehicle()
	if IsValid(PlayerVehicle) and player:InVehicle() then
		if Vector3.Distance(PlayerVehicle:GetPosition(), player:GetPosition()) < self.MaxDistance / 2 then
			return PlayerVehicle
		end
	end
	return player
end

function WaterWalk:RemoveAllSurfaces()
	for k, v in pairs(self.Surfaces) do
		if IsValid(v) then
			v:Remove()
		end
	end
end

function WaterWalk:PreTick()
	self:Master(LocalPlayer)
	for players in Client:GetStreamedPlayers() do
		self:Master(players)
	end
end

function WaterWalk:Render()
	if Game:GetState() ~= GUIState.Game then return end
	if not self.DisplayScreenNotification then return end
	if LocalPlayer:GetValue(self.ValueString) then
		local DisplayPos	=	Vector2(Render.Width * self.LocalDisplayAnchor.x, Render.Height * self.LocalDisplayAnchor.y)
		self:DrawTextOnScreen(DisplayPos, self.Name .. " Active", Color.Green, self.FontSize, 2)
	end
end

function WaterWalk:CheckList(tableList, modelID)
	for k,v in pairs(tableList) do
		if v == modelID then return true end
	end
	return false
end

function WaterWalk:LocalPlayerChat(args)
	local msg	=	string.split(args.text, " ")	--	Split at Spaces.
    if string.lower(msg[1]) == "/" .. string.lower(self.ActivationCommand) then
		if LocalPlayer:GetValue(self.ValueString) then
			LocalPlayer:SetSystemValue(self.ValueString, false)
			Chat:Print(self.Name .. " Disabled.", Color.Red)
		else
			LocalPlayer:SetSystemValue(self.ValueString, true)
			Chat:Print(self.Name .. " Enabled.", Color.Green)
		end
    end
end

function WaterWalk:DrawTextOnScreen(pos, text, color, fontsize)
	if pos:IsNaN() then return end

	--	Calculate text variables.
	local DisplayText			=	text
	local EffectiveFontSize		=	fontsize * Render.Size.y / 1000
	local Textsize				=	Render:GetTextSize(DisplayText, EffectiveFontSize)
	local DisplayPosition		=	Vector2(pos.x - Textsize.x / 2, pos.y  - Textsize.y / 2)
	
	--	And finally, render the text.
    Render:DrawText(DisplayPosition + Vector2(1, 1), DisplayText, Color.Black, EffectiveFontSize)
    Render:DrawText(DisplayPosition, DisplayText, color, EffectiveFontSize)
end

WaterWalk = WaterWalk()

function LocalPlayer:SetSystemValue(valueName, value)
	if IsValid(self) and valueName then
		local SendInfo		=	{}
			SendInfo.player	=	self
			SendInfo.name	=	tostring(valueName)
			SendInfo.value	=	value
		Network:Send("SetSystemValue", SendInfo)
	end
end
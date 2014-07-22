class 'WaterWalk'

function WaterWalk:__init()
	Network:Subscribe("SetSystemValue", self, self.SetSystemValue)
end

function WaterWalk:SetSystemValue(args)
	args.player:SetNetworkValue(args.name, args.value)
end

WaterWalk = WaterWalk()
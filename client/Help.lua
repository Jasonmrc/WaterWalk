function ModulesLoad()
    Events:Fire( "HelpAddItem",
        {
            name = "WaterWalk",
            text = 
				"WaterWalk allows you to walk, drive, or land a plane or helicopter on water.\n"..
				"Boats are not affected by this and you can easily enter a boat and it will operate like normal-\n"..
				"Or exit a boat and stand on the water.\n"..
				"Use '/waterwalk' to enable and disable it.\n"..
				"\n:: WaterWalk was developed by JasonMRC of Problem Solvers.\n"
        } )
end

function ModuleUnload()
    Events:Fire( "HelpRemoveItem",
        {
            name = "WaterWalk"
        } )
end

Events:Subscribe("ModulesLoad", ModulesLoad)
Events:Subscribe("ModuleUnload", ModuleUnload)
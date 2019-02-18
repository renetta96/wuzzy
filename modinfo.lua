-- This information tells other players more about the mod
name = "Ozzy The Buzzy"
description = "The bee master"
author = "Zeta"
version = "1.4.2" -- This is the version of the template. Change it to your own number.

-- This is the URL name of the mod's thread on the forum; the part after the ? and before the first & in the url
forumthread = ""


-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 6

dont_starve_compatible = true
reign_of_giants_compatible = true
porkland_compatible = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- The mod's tags displayed on the server list
server_filter_tags = {
"character",
}

configuration_options =
{
	{
		name = "NUM_BEES_IN_HIVE",
		label = "Number of bees in beehive",
		options = {
			{description = "Fewer", data = -1},
			{description = "Default", data = 0},
			{description = "More", data = 1}
		},
		default = 0,
		hover = "Affects number of bees and their respawn time."
	},

	{
		name = "BEE_DAMAGE",
		label = "Bee damage",
		options = {
			{description = "Low", data = -1},
			{description = "Medium", data = 0},
			{description = "High", data = 1}
		},
		default = 0,
		hover = "Affects damage output of bees, including attack damage, attack speed, poison damage, etc."
	}
}
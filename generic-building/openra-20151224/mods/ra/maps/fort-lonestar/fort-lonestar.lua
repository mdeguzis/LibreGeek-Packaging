
SovietEntryPoints = { Entry1, Entry2, Entry3, Entry4, Entry5, Entry6, Entry7, Entry8 }
PatrolWaypoints = { Entry2, Entry4, Entry6, Entry8 }
ParadropWaypoints = { Paradrop1, Paradrop2, Paradrop3, Paradrop4 }
SpawnPoints = { Spawn1, Spawn2, Spawn3, Spawn4 }
Snipers = { Sniper1, Sniper2, Sniper3, Sniper4, Sniper5, Sniper6, Sniper7, Sniper8, Sniper9, Sniper10, Sniper11, Sniper12 }

if Map.Difficulty == "Very Easy (1P)" then
	ParaChance = 20
	Patrol = { "e1", "e2", "e1" }
	Infantry = { "e4", "e1", "e1", "e2", "e2" }
	Vehicles = { "apc" }
	Tank = { "3tnk" }
	LongRange = { "arty" }
	Boss = { "v2rl" }
	Swarm = { "shok", "shok", "shok" }
elseif Map.Difficulty == "Easy (2P)" then
	ParaChance = 25
	Patrol = { "e1", "e2", "e1" }
	Infantry = { "e4", "e1", "e1", "e2", "e1", "e2", "e1" }
	Vehicles = { "ftrk", "apc", "arty" }
	Tank = { "3tnk" }
	LongRange = { "v2rl" }
	Boss = { "4tnk" }
	Swarm = { "shok", "shok", "shok", "shok", "ttnk" }
elseif Map.Difficulty == "Normal (3P)" then
	ParaChance = 30
	Patrol = { "e1", "e2", "e1", "e1" }
	Infantry = { "e4", "e1", "e1", "e2", "e1", "e2", "e1" }
	Vehicles = { "ftrk", "ftrk", "apc", "arty" }
	Tank = { "3tnk" }
	LongRange = { "v2rl" }
	Boss = { "4tnk" }
	Swarm = { "shok", "shok", "shok", "shok", "ttnk", "ttnk", "ttnk" }
elseif Map.Difficulty == "Hard (4P)" then
	ParaChance = 35
	Patrol = { "e1", "e2", "e1", "e1", "e4" }
	Infantry = { "e4", "e1", "e1", "e2", "e1", "e2", "e1" }
	Vehicles = { "arty", "ftrk", "ftrk", "apc", "apc" }
	Tank = { "3tnk" }
	LongRange = { "v2rl" }
	Boss = { "4tnk" }
	Swarm = { "shok", "shok", "shok", "shok", "shok", "ttnk", "ttnk", "ttnk", "ttnk" }
else
	ParaChance = 40
	Patrol = { "e1", "e2", "e1", "e1", "e4", "e4" }
	Infantry = { "e4", "e1", "e1", "e2", "e1", "e2", "e1", "e1" }
	Vehicles = { "arty", "arty", "ftrk", "apc", "apc" }
	Tank = { "ftrk", "3tnk" }
	LongRange = { "v2rl" }
	Boss = { "4tnk" }
	Swarm = { "shok", "shok", "shok", "shok", "shok", "shok", "ttnk", "ttnk", "ttnk", "ttnk", "ttnk" }
end

Wave = 0
Waves =
{
	{ delay = 500, units = { Infantry } },
	{ delay = 500, units = { Patrol, Patrol } },
	{ delay = 700, units = { Infantry, Infantry, Vehicles }, },
	{ delay = 1500, units = { Infantry, Infantry, Infantry, Infantry } },
	{ delay = 1500, units = { Infantry, Infantry, Patrol, Vehicles } },
	{ delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Tank, Vehicles } },
	{ delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Tank, Tank, Swarm } },
	{ delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Infantry, Infantry, LongRange } },
	{ delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Infantry, Infantry, Infantry, LongRange, Tank, LongRange } },
	{ delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Infantry, Infantry, Infantry, Infantry, LongRange, LongRange, Tank, Tank, Vehicles } },
	{ delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Infantry, Infantry, Infantry, Infantry, Infantry, Boss, Swarm } }
}

-- Now do some adjustments to the waves
if Map.Difficulty == "Real tough guy" or Map.Difficulty == "Endless mode" then
	Waves[8] = { delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Infantry, Infantry }, ironUnits = { LongRange } }
	Waves[9] = { delay = 1500, units = { Infantry, Infantry, Patrol, Infantry, Infantry, Infantry, Infantry, Infantry, LongRange, LongRange, Vehicles, Tank }, ironUnits = { Tank } }
	Waves[11] = { delay = 1500, units = { Vehicles, Infantry, Patrol, Patrol, Patrol, Infantry, LongRange, Tank, Boss, Infantry, Infantry, Patrol } }
end

SendUnits = function(entryCell, unitTypes, targetCell, extraData)
	Reinforcements.Reinforce(soviets, unitTypes, { entryCell }, 40, function(a)
		if not a.HasProperty("AttackMove") then
			Trigger.OnIdle(a, function(a)
				a.Move(targetCell)
			end)
			return
		end

		Trigger.OnIdle(a, function(a)
			if a.Location ~= targetCell then
				a.AttackMove(targetCell)
			else
				a.Hunt()
			end
		end)

		if extraData == "IronCurtain" then
			a.GrantUpgrade("invulnerability")
			Trigger.AfterDelay(DateTime.Seconds(25), function()
				a.RevokeUpgrade("invulnerability")
			end)
		end
	end)
end

SendWave = function()
	Wave = Wave + 1
	local wave = Waves[Wave]

	Trigger.AfterDelay(wave.delay, function()
		Utils.Do(wave.units, function(units)
			local entry = Utils.Random(SovietEntryPoints).Location
			local target = Utils.Random(SpawnPoints).Location

			SendUnits(entry, units, target)
		end)

		if wave.ironUnits then
			Utils.Do(wave.ironUnits, function(units)
				local entry = Utils.Random(SovietEntryPoints).Location
				local target = Utils.Random(SpawnPoints).Location

				SendUnits(entry, units, target, "IronCurtain")
			end)
		end

		Utils.Do(players, function(player)
			Media.PlaySpeechNotification(player, "EnemyUnitsApproaching")
		end)

		if (Wave < #Waves) then
			if Utils.RandomInteger(1, 100) < ParaChance then
				local units = ParaProxy.SendParatroopers(Utils.Random(ParadropWaypoints).CenterPosition)
				Utils.Do(units, function(unit)
					Trigger.OnIdle(unit, function(a)
						if a.IsInWorld then
							a.Hunt()
						end
					end)
				end)

				local delay = Utils.RandomInteger(DateTime.Seconds(20), DateTime.Seconds(45))
				Trigger.AfterDelay(delay, SendWave)
			else
				SendWave()
			end
		else
			if Map.Difficulty == "Endless mode" then
				Wave = 0
				IncreaseDifficulty()
				SendWave()
				return
			end

			Trigger.AfterDelay(DateTime.Minutes(1), SovietsRetreating)
			Media.DisplayMessage("You almost survived the onslaught! No more waves incoming.")
		end
	end)
end

SovietsRetreating = function()
	Utils.Do(Snipers, function(a)
		if not a.IsDead and a.Owner == soviets then
			a.Destroy()
		end
	end)
end

IncreaseDifficulty = function()
	local additions = { Infantry, Patrol, Vehicles, Tank, LongRange, Boss, Swarm }
	Utils.Do(Waves, function(wave)
		wave.units[#wave.units + 1] = Utils.Random(additions)
	end)
end

Tick = function()
	if (Utils.RandomInteger(1, 200) == 10) then
		local delay = Utils.RandomInteger(1, 10)
		Lighting.Flash("LightningStrike", delay)
		Trigger.AfterDelay(delay, function()
			Media.PlaySound("thunder" .. Utils.RandomInteger(1,6) .. ".aud")
		end)
	end
	if (Utils.RandomInteger(1, 200) == 10) then
		Media.PlaySound("thunder-ambient.aud")
	end
end

WorldLoaded = function()
	soviets = Player.GetPlayer("Soviets")
	players = { }
	for i = 0, 4, 1 do
		local player = Player.GetPlayer("Multi" ..i)
		players[i] = player
	end

	Media.DisplayMessage("Defend Fort Lonestar at all costs!")

	ParaProxy = Actor.Create("powerproxy.paratroopers", false, { Owner = soviets })
	SendWave()
end

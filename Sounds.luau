local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local clips = {
	Pickup={"action_jump.mp3",1.78,.28},
	Pair={"action_jump_land.mp3",1.52,.35},
	Open={"volume_slider.ogg",1.45,.18},
	Reward={"action_get_up.mp3",1.45,.28},
	First={"impact_water.mp3",1.9,.26},
	Alarm={"action_falling.ogg",1.45,.22},
}
local Sounds = {}

function Sounds.Play(cue)
	local clip = clips[cue]
	if not clip then return end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/"..clip[1]
	sound.PlaybackSpeed = clip[2]
	sound.Volume = clip[3]
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound,4)
end

return Sounds

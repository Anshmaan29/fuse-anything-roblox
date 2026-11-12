-- Background music: a looping playlist of free APM cartoon tracks.
local SoundService = game:GetService("SoundService")
local tracks = {
	"rbxassetid://1839397110", -- Nobody Else (Cartoon)
	"rbxassetid://1839398075", -- Unlucky At Cards (Cartoon)
	"rbxassetid://1839413595", -- Hey You (Cartoon)
}
local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.Volume = .22
music.Parent = SoundService
local player = game:GetService("Players").LocalPlayer
local function apply() music.Volume = player:GetAttribute("MusicMuted") and 0 or .22 end
player:GetAttributeChangedSignal("MusicMuted"):Connect(apply)
apply()

local index = math.random(#tracks)
while true do
	music.SoundId = tracks[index]
	music:Play()
	music.Ended:Wait()
	task.wait(1)
	index = index % #tracks + 1
end

repeat task.wait() until game:IsLoaded()
repeat task.wait(5) until game.Players.LocalPlayer

local Collection = {}

local PlaceID = game.PlaceId

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage:WaitForChild("Framework")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

function Collection:GetRootPart(Character)
  return Character:WaitForChild("HumanoidRootPart")
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Collection:GetRootPart(Character)

function Collection:WaitPath(root, ...)
  local obj = root
  for _, name in ipairs({ ... }) do
    obj = obj:WaitForChild(name)
  end
  return obj
end

local SpinsLeft = Collection:WaitPath(PlayerGui, "MainGuiIgnoreGuiInset", "ScreenRace", "Reroll", "Reroll", "Spins")
local GloryCoreAmount = Collection:WaitPath(PlayerGui, "MainGuiIgnoreGuiInset", "ScreenHonor", "Store", "CurrencyFrame","TextLabel")
local LotteryTicket = Collection:WaitPath(PlayerGui, "MainGuiIgnoreGuiInset", "ScreenHonor", "Lottery", "LotteryTicket","TextLabel")

local TitleRaceLabel = Collection:WaitPath(HumanoidRootPart, "PlayerTitleGUI", "Root", "Title", "Race")
local TitleRaceText = TitleRaceLabel.Text

local StarFormat = tonumber(TitleRaceText:match("(%d+)"))
local RaceFormat = TitleRaceText:match("%d+%s*(.+)")

if not StarFormat or not RaceFormat then
  error("Failed to parse race title text: " .. tostring(TitleRaceText))
end

local StarsEmoji = string.rep("⭐", StarFormat)

local SpinUsed = 0
local HonorSpinUsed = 0
local GloryCoreOld = tonumber(GloryCoreAmount.Text)
local GloryCoreTarget = GloryCoreOld + getgenv().Configs.GloryCore['Spin Settings']['Glory Core Amount']
local RollbackState = false
local FinishRerollRace = false

function Collection:SetRollback(Value)
  if Value then
    Framework.Features.TutoriialSystem.RemoteEvent:FireServer("SetStep", "\xFF", nil)
    RollbackState = true
  else
    Framework.Features.TutoriialSystem.RemoteEvent:FireServer("SetStep", "1", nil)
    RollbackState = false
  end
end

function Collection:Spin()
  Framework.Gameplay.RaceSystem.RaceRE:FireServer("Rolling", "1")
end

function Collection:HonorSpin(Used)
  Framework.Features.HonorSystem.RemoteEvent:FireServer("HonorSpin", Used)
end

local AccessoryMap = {
  Orc = "orcAccessory",
  Goblin = "goblinAccessory",
  Undead = "undeadAccessory",
  Dragonkin = "dragonbornAccessory",
  Sorcerer = "CurseAccessory",
  Fairy = "FairyHat",
  Angel = "AngelWings",
  Demon = "DemonHat",
  ['Night Elf'] = "ElfWing",
  Lucifer = "LuciferhatAccessory",
}

function Collection:GetRaceNameEnglish(Character)
  for raceName, accessoryName in pairs(AccessoryMap) do
    if Character:FindFirstChild(accessoryName) then
      return raceName
    end
  end
  return RaceFormat
end

function Collection:GetMatchRace(Character)
  local targetAccessory = AccessoryMap[getgenv().Configs.Race.RaceLock]

  if not targetAccessory then
    for _, accessoryName in pairs(AccessoryMap) do
      if Character:FindFirstChild(accessoryName) then
        return false
      end
    end
    return true
  end

  return Character:FindFirstChild(targetAccessory) ~= nil
end

function Collection:GetStar(Star)
  if Star == getgenv().Configs.Race.Star then
    return true
  else
    return false
  end
end

local cascade = loadstring(game:HttpGet("https://github.com/biggaboy212/Cascade/releases/download/v1.2.0/dist.luau"))()
local ConsoleComponent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Songkranz/console/refs/heads/main/console.lua"))()

local app = cascade.New({
  WindowPill = true,
  Theme = cascade.Themes.Dark,
  Accent = cascade.Accents.Blue,
})

local window = app:Window({
  Title    = "My Script Hub",
  Subtitle = "Made by You",
  Size     = UDim2.fromOffset(850, 530),
})

local minimizeKeybind = Enum.KeyCode.RightControl
game:GetService("UserInputService").InputEnded:Connect(function(input, gpe)
  if input.KeyCode == minimizeKeybind and not gpe then
    window.Minimized = not window.Minimized
  end
end)

local exampleSection = window:Section({ Title = "Example", Disclosure = true })
local exampleTab = exampleSection:Tab({
  Title    = "All Components",
  Icon     = cascade.Symbols.switch2,
  Selected = true,
})

local controlSection = exampleTab:PageSection({ Title = "Controls" })
local form = controlSection:Form()

console = ConsoleComponent.new(controlSection.__instance or controlSection, {
  Height   = 220,
  RichText = true,
  FontSize = 13,
})

console:AppendText('<font color="#888888">— Console ready —</font>')

while getgenv().Configs.Race.Enabled do task.wait()

  local CurrentSpinsLeft = tonumber(SpinsLeft.Text:match("%d+"))
  local StarFormat = tonumber(TitleRaceLabel.Text:match("(%d+)"))
  local RaceFormat = TitleRaceLabel.Text:match("%d+%s*(.+)")

  if not StarFormat or not RaceFormat then
    warn("Failed to parse race title text, skipping frame")
    continue
  end

  local RaceMatch = Collection:GetMatchRace(Character)
  local StarMatch = Collection:GetStar(StarFormat)

  if not RaceMatch then
    if CurrentSpinsLeft <= 0 then
      console:AppendText("No Spins Left [1]")
      _G.Horst_SetDescription("NOT SPIN LEFT❌")
      if RollbackState then
        console:AppendText("Rollback active, Rejoin in 3 Second 🔴")
        task.wait(3)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
      end
      break
    end

    if not RollbackState then
      console:AppendText('Set rollback [1] true , Data not save')
      Collection:SetRollback(true)
    end

    Collection:Spin()

    SpinUsed = SpinUsed + 1

    console:AppendText('Reroll : ' .. SpinUsed)

    task.wait(1)

    local NewStarFormat = tonumber(TitleRaceLabel.Text:match("(%d+)"))
    local NewRaceFormat = TitleRaceLabel.Text:match("%d+%s*(.+)")

    if NewStarFormat and NewRaceFormat then
      StarFormat, RaceFormat = NewStarFormat, NewRaceFormat
      RaceMatch = Collection:GetMatchRace(Character)
      StarMatch = Collection:GetStar(StarFormat)
    end

    if SpinUsed >= getgenv().Configs.Race["Amount Reroll"] and not RaceMatch then
      console:AppendText("Race : " .. StarsEmoji .. " " .. RaceFormat)
      console:AppendText("Glory Core 🍊 : " .. GloryCoreAmount.Text)
      console:AppendText("Spin Left : " .. SpinsLeft.Text)
      console:AppendText("Race not matched, Rejoin in 3 Second 🔴")
      _G.Horst_SetDescription("NOT RACE MATCH ❌")
      task.wait(3)
      TeleportService:Teleport(game.PlaceId, LocalPlayer)
    elseif SpinUsed >= 0 and RaceMatch then
      console:AppendText("Race matched turn off rollback, Rejoin for save data in 3 Second")
      Collection:SetRollback(false)
      task.wait()
      _G.Horst_SetDescription("✅" .. " 🧌 Race: " .. StarsEmoji .. " " .. Collection:GetRaceNameEnglish(Character) .. ". 🍊 Glory Core: " .. GloryCoreAmount.Text .. ". 🔄Spin Left: " .. CurrentSpinsLeft)
      task.wait(3)
      TeleportService:Teleport(game.PlaceId, LocalPlayer)
      break
    end
  elseif RaceMatch then
    if RollbackState then
      console:AppendText('Set rollback [1] false , Continue to Star')
      Collection:SetRollback(false)
    end
  end


  if RaceMatch and not StarMatch then
    if CurrentSpinsLeft <= 0 then
      console:AppendText("No Spins Left [2]")
      _G.Horst_SetDescription("NOT SPIN LEFT ❌")
      if RollbackState then
        console:AppendText("Rollback active, Rejoin in 3 Second 🔴")
        task.wait(3)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
      end
      break
    end


    if not RollbackState then
      console:AppendText('Set rollback [2] true , Data not save')
      Collection:SetRollback(true)
    end

    Collection:Spin()

    SpinUsed = SpinUsed + 1

    task.wait(1)

    local NewStarFormat = tonumber(TitleRaceLabel.Text:match("(%d+)"))
    local NewRaceFormat = TitleRaceLabel.Text:match("%d+%s*(.+)")

    if NewStarFormat and NewRaceFormat then
      StarFormat, RaceFormat = NewStarFormat, NewRaceFormat
      RaceMatch = Collection:GetMatchRace(Character)
      StarMatch = Collection:GetStar(StarFormat)
    end

    if SpinUsed >= getgenv().Configs.Race["Amount Reroll"] and not (RaceMatch and StarMatch) then
      console:AppendText("Race : " .. StarsEmoji .. " " .. RaceFormat)
      console:AppendText("Glory Core 🍊 : " .. GloryCoreAmount.Text)
      console:AppendText("Spin Left : " .. SpinsLeft.Text)
      console:AppendText("Star not matched, Rejoin in 3 Second")
      task.wait()
      _G.Horst_SetDescription("NOT STAR MATCH ❌")
      task.wait(3)
      TeleportService:Teleport(game.PlaceId, LocalPlayer)
      break
    elseif SpinUsed >= 0 and RaceMatch and StarMatch then
      console:AppendText("Race : " .. StarsEmoji .. " " .. RaceFormat)
      console:AppendText("Glory Core 🍊 : " .. GloryCoreAmount.Text)
      console:AppendText("Star matched turn off rollback, Rejoin for save data in 3 Second 🔴")
      console:AppendText("Success auto reroll race")
      Collection:SetRollback(false)
      task.wait()
      _G.Horst_SetDescription("✅" .. " 🧌 Race: " .. StarsEmoji .. " " .. Collection:GetRaceNameEnglish(Character) .. ". 🍊 Glory Core: " .. GloryCoreAmount.Text .. ". 🔄Spin Left: " .. CurrentSpinsLeft)
      task.wait(3)
      TeleportService:Teleport(game.PlaceId, LocalPlayer)
      break
    end
  end

  if RaceMatch and StarMatch then
    console:AppendText("Race : " .. StarsEmoji .. " " .. RaceFormat)
    console:AppendText("Glory Core 🍊 : " .. GloryCoreAmount.Text)
    console:AppendText("Spin Left : " .. CurrentSpinsLeft)
    console:AppendText("Success auto reroll race 🟢")
    FinishRerollRace = true
    task.wait()
    _G.Horst_SetDescription("✅" .. " 🧌 Race: " .. StarsEmoji .. " " .. Collection:GetRaceNameEnglish(Character) .. ". 🍊 Glory Core: " .. GloryCoreAmount.Text .. ". 🔄Spin Left: " .. CurrentSpinsLeft)
    break
  end
end


if FinishRerollRace or not getgenv().Configs.Race.Enabled then
  while getgenv().Configs.GloryCore.Enabled do task.wait()

    local GloryCoreNew = tonumber(GloryCoreAmount.Text)
    local CurrentTicket = tonumber(LotteryTicket.Text)


    if getgenv().Configs.GloryCore.Enabled then

      if CurrentTicket < 160 then
        console:AppendText("No Ticket Left")
        _G.Horst_SetDescription("NOT TICKET LEFT ❌")
        break
      end


      if not RollbackState then
        console:AppendText('Set rollback [3] true , Data not save')
        Collection:SetRollback(true)
      end


      Collection:HonorSpin(getgenv().Configs.GloryCore['Spin Settings'].Use)

      HonorSpinUsed = HonorSpinUsed + 1

      console:AppendText('Honor Spin : ' .. HonorSpinUsed)

      task.wait(6)

      if HonorSpinUsed >= getgenv().Configs.GloryCore['Spin Settings']['Spin Amount'] and GloryCoreNew < GloryCoreTarget then
        console:AppendText('<font color="#FF4444">[ Dont got any Glory core, rejoin in 3 Second ]</font>')
        task.wait()
        _G.Horst_SetDescription("FARMING GROLY CORE ...")
        task.wait(4)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
        break
      elseif HonorSpinUsed >= 0 and GloryCoreNew >= GloryCoreTarget then
        console:AppendText('<font color="#FFD700">[ Got Glory Core! ]</font>')
        task.wait()
        _G.Horst_SetDescription("✅🍊" .. " 🧌 Race: " .. StarsEmoji .. " " .. Collection:GetRaceNameEnglish(Character) .. ". 🍊 Glory Core: " .. GloryCoreAmount.Text .. ". 🔄Spin Left: " .. tonumber(SpinsLeft.Text:match("%d+")))
        task.wait()
        Collection:SetRollback(false)
        break
      end
    end
  end
end

if not getgenv().Configs.Race.Enabled and not getgenv().Configs.GloryCore.Enabled then
  console:AppendText('<font color="#FFD700">[ NO CONFIG ENABLE SEND LOG TO HORST ]</font>')
  task.wait()
  _G.Horst_SetDescription("✅🍊" .. " Race: " .. StarsEmoji .. " " .. Collection:GetRaceNameEnglish(Character) .. ". 🍊 Glory Core: " .. GloryCoreAmount.Text .. ". 🔄Spin Left: " .. tonumber(SpinsLeft.Text:match("%d+")))
end

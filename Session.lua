--| SERVICES:
local HttpS = game:GetService("HttpService")
	local RunS = game:GetService("RunService")
	
	if RunS:IsRunning() then
		return
	end
	
local StudioS = game:GetService("StudioService")
	
local toolbar = plugin:CreateToolbar("Session Logger")
 
local SessionBtn = toolbar:CreateButton("Session Logger", "prints your Session Data", "rbxassetid://5514776308")

--| VARIABLES:

local startTime = os.time()

local UniqeId = game:FindFirstChild("UniqeId",true)
local createdTime, sessionData, sessions
local activeScript, activeTime = nil, os.time()

--| FUNCTIONS:

local function ToTimerFormat(value)
	if value >= 86400 then
		return string.format("%d:%02d:%02d:%02d", value/86400, value/3600%24, value/60%60, value%60)
	elseif value >= 3600 then
		return string.format("%02d:%02d:%02d", value/3600%24, value/60%60, value%60)
	end
	return string.format("%02d:%02d", value/60%60, value%60)
end

local function init()
	if (not UniqeId) then
		UniqeId = Instance.new("StringValue")
		UniqeId.Name = "UniqeId"
		UniqeId.Value = HttpS:GenerateGUID(false)
		UniqeId.Parent = game.ServerStorage

		sessionData = {
			createdTime = os.date(),
			sessions = {},
			totalSessionsTime = 0,
		}
		
		plugin:SetSetting(UniqeId.Value,HttpS:JSONEncode(sessionData))
	else
		sessionData = HttpS:JSONDecode(plugin:GetSetting(UniqeId.Value))
	end
	
	--[[
	
--	local totalSessionsTime = 0;
--	for _,v in ipairs(sessionData.sessions) do
--		totalSessionsTime = totalSessionsTime + v.sessionTime
--	end
--	
--	sessionData.totalSessionsTime = totalSessionsTime;

	--]]
	
	if #sessionData.sessions > 0 then
		local recentSession = sessionData.sessions[#sessionData.sessions]
		print("Recent Session Data:",recentSession.Date)
		print("Recent Session Time:",ToTimerFormat(recentSession.sessionTime))
		
		print("Total Sessions:",#sessionData.sessions)
		print("Total Sessions Time:",ToTimerFormat(sessionData.totalSessionsTime))
		
		print("Created:",sessionData.createdTime)
	end
	
	activeScript = StudioS.ActiveScript
	StudioS:GetPropertyChangedSignal("ActiveScript"):Connect(function()
		if activeScript and StudioS.ActiveScript ~= activeScript then
			print(("You have edited %s for"):format(activeScript:GetFullName()),ToTimerFormat(os.time() - activeTime))
		end
		activeTime = os.time()
		activeScript = StudioS.ActiveScript
	end)
end

--| SCRIPTS:

init()

SessionBtn.Click:Connect(function()
	if #sessionData.sessions > 0 then
		local recentSession = sessionData.sessions[#sessionData.sessions]
		print("Recent Session Data:",recentSession.Date)
		print("Recent Session Time:",ToTimerFormat(recentSession.sessionTime))
		
		print("Total Sessions:",#sessionData.sessions)
		print("Total Sessions Time:",ToTimerFormat(sessionData.totalSessionsTime))
		
		print("Created:",sessionData.createdTime)
	end	
end)

game.Close:Connect(function()
	UniqeId.Parent = game.ServerStorage
	local osTime = os.time()
	local currentSession = {
		Date = os.date(),
		sessionTime = osTime - startTime,
		startTime = startTime,
		endTime = osTime,
	}
	table.insert(sessionData.sessions,currentSession)
	sessionData.totalSessionsTime = sessionData.totalSessionsTime + currentSession.sessionTime
	plugin:SetSetting(UniqeId.Value,HttpS:JSONEncode(sessionData))
end)

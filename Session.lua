--| SERVICES:
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

if RunService:IsRunning() then
	return
end

local StudioService = game:GetService("StudioService")
local Selection = game:GetService("Selection")
local lastActivity = os.time()

local toolbar = plugin:CreateToolbar("Session Logger")

local SessionBtn = toolbar:CreateButton("Session Logger", "prints your Session Data", "rbxassetid://5514776308")
SessionBtn.ClickableWhenViewportHidden = true

--| VARIABLES:

local startTime = os.time()
local totalInactivity

local UniqeId = game:FindFirstChild("UniqeId",true)
local createdTime, sessionData, sessions
local activeScript, activeTime = nil, os.time()

local SpecialCharacters = {
	['\a'] = '\\a',
	['\b'] = '\\b',
	['\f'] = '\\f',
	['\n'] = '\\n',
	['\r'] = '\\r',
	['\t'] = '\\t',
	['\v'] = '\\v',
	['\0'] = '\\0'
}

--| FUNCTIONS:

local function ToTimerFormat(value)
	if value >= 86400 then
		return string.format("%d:%02d:%02d:%02d", value/86400, value/3600%24, value/60%60, value%60)
	elseif value >= 3600 then
		return string.format("%02d:%02d:%02d", value/3600%24, value/60%60, value%60)
	end
	return string.format("%02d:%02d", value/60%60, value%60)
end

local function SerializeType(Value, Class)
	local NewValue = ''
	
	if Class == 'string' then
		-- Not using %q as it messes up the special characters fix
		NewValue = ('"%s"'):format(Value:gsub('[%c%z]', SpecialCharacters))
	elseif Class == 'Instance' then
		NewValue = "game."..Value:GetFullName()..","
	elseif type(Value) ~= Class then -- CFrame, Vector3, UDim2, ...
		NewValue = Class .. '.new(' .. tostring(Value) .. ')'
	elseif Class == 'userdata' then
		NewValue = ('[Userdata, Metatable Field: %s]'):format(tostring(not not getmetatable(Value)))
	else -- thread, number, boolean, nil, ...
		NewValue = tostring(Value)
	end
	
	return NewValue
end

local function TableToString(Table, IgnoredTables, Depth)
	IgnoredTables = IgnoredTables or {}
	if IgnoredTables[Table] then
		return '[Cyclic Table]'
	end
	
	Depth = Depth or 0
	Depth = Depth + 1
	
	IgnoredTables[Table] = true
	local Tab = ('    '):rep(Depth)
	local TrailingTab = ('    '):rep(Depth - 1)
	local Result = '{'
	
	local LineTab = '\n' .. Tab
	for Key, Value in next, Table do
		local KeyClass, ValueClass = typeof(Key), typeof(Value)
		if KeyClass == 'string' then
			Key = Key:gsub('[%c%z]', SpecialCharacters)
			if Key:match'%s' then
				Key = ('["%s"]'):format(Key)
			end
		else
			Key = '[' .. (KeyClass == 'table' and TableToString(Key, IgnoredTables, Depth):gsub('^[\n\r%s]*(.-)[\n\r%s]*$', '%1') or SerializeType(Key, KeyClass)) .. ']'
		end
		
		Value = ValueClass == 'table' and TableToString(Value, IgnoredTables, Depth) or SerializeType(Value, ValueClass)
		Result = Result .. LineTab .. Key .. ' = ' .. Value..","
	end
	
	return Result .. '\n' .. TrailingTab .. '}'
end

local function init()
	local key = UniqeId and UniqeId.Value or game:GetDebugId()
	local data = plugin:GetSetting(key)
	sessionData = data and HttpService:JSONDecode(data)
	if (not sessionData) then
		sessionData = {
			createdTime = os.date(),
			sessions = {},
			totalSessionsTime = 0,
		}
		plugin:SetSetting(game:GetDebugId(),HttpService:JSONEncode(sessionData))
		warn("new session")
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
		print(
			"Recent Session Data:", recentSession.Date,
			"| Recent Session Time:", ToTimerFormat(recentSession.sessionTime),
			"| Total Sessions:", #sessionData.sessions,
			"| Total Sessions Time:", ToTimerFormat(sessionData.totalSessionsTime),
			"| Created:", sessionData.createdTime
		)
	end
	
	activeScript = StudioService.ActiveScript
	StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(function()
		if activeScript and StudioService.ActiveScript ~= activeScript then
			--			print(("You have edited %s for"):format(activeScript:GetFullName()),ToTimerFormat(os.time() - activeTime))
		end
		activeTime = os.time()
		activeScript = StudioService.ActiveScript
		lastActivity = os.time()
	end)
end

local function LogActivity()
	local osTime = os.time()
	
	if osTime - lastActivity > 60 then
		totalInactivity = (osTime - lastActivity)
	end
	lastActivity = os.time()
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
		
		print(TableToString(sessionData))
	end	
end)

game.Close:Connect(function()
	LogActivity()
	local osTime = os.time()
	
	local currentSession = {
		Date = os.date(),
		sessionTime = totalInactivity,
		startTime = startTime,
		endTime = osTime,
	}
	if osTime - startTime >= 600 then
		table.insert(sessionData.sessions,currentSession)
		sessionData.totalSessionsTime = sessionData.totalSessionsTime + currentSession.sessionTime
	end
	if UniqeId then
		UniqeId.Parent = game.ServerStorage
		plugin:SetSetting(UniqeId.Value,HttpService:JSONEncode(sessionData))
	else
		plugin:SetSetting(game:GetDebugId(),HttpService:JSONEncode(sessionData))
	end
end)

Selection.SelectionChanged:Connect(function()
	lastActivity = os.time()
end)

local function calculateTotalSessionsTime()
	local TotalSessionsTime = 0
	for _,v in ipairs(sessionData.sessions) do
		TotalSessionsTime += v.sessionTime
	end
	sessionData.totalSessionsTime = TotalSessionsTime
	plugin:SetSetting(UniqeId.Value,HttpService:JSONEncode(sessionData))
end

local function removeRecentSession()
	table.remove(sessionData.sessions,#sessionData.sessions)
	plugin:SetSetting(UniqeId.Value,HttpService:JSONEncode(sessionData))
end

-- return:
return nil

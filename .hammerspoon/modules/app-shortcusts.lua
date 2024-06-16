-- helper functions
local function showFocusAlert(content)
	hs.alert.show(content, hs.alert.defaultStyle, hs.screen.mainScreen(), 0.5)
end

local function keyStroke(mods, key)
	if key == nil then
		key = mods
		mods = {}
	end

	return function()
		hs.eventtap.keyStroke(mods, key, 1000)
	end
end

local function remap(mods, key, pressFn)
	return hs.hotkey.bind(mods, key, pressFn, nil, pressFn)
end

local function switchPane(key)
	local paneOption

	if key == "h" then
		paneOption = "-L"
	elseif key == "j" then
		paneOption = "-D"
	elseif key == "k" then
		paneOption = "-U"
	elseif key == "l" then
		paneOption = "-R"
	end

	return remap({ "cmd", "ctrl" }, key, function()
		hs.eventtap.keyStroke({ "ctrl" }, "b", 1000)
		hs.eventtap.keyStroke({ "shift" }, ";", 1000)
		hs.eventtap.keyStrokes("select-pane " .. paneOption)
		hs.timer.doAfter(0.1, function()
			hs.eventtap.keyStroke({}, "return", 1000)
		end)
	end)
end

-- configs
local scenarioShortcuts = {
	chrome = {
		nextTab = remap({ "cmd", "ctrl" }, "l", keyStroke({ "ctrl" }, "tab")),
		prevTab = remap({ "cmd", "ctrl" }, "h", keyStroke({ "ctrl", "shift" }, "tab")),
	},
	tmux = {
		paneRight = switchPane("l"),
		paneLeft = switchPane("h"),
		paneUp = switchPane("k"),
		paneDown = switchPane("j"),
	},
}

local function serializeTable(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then
		tmp = tmp .. name .. " = "
	end

	if type(val) == "table" then
		tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

		for k, v in pairs(val) do
			tmp = tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
		end

		tmp = tmp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	else
		tmp = tmp .. '"[inserializeable datatype:' .. type(val) .. ']"'
	end

	return tmp
end

local function enableScenarioShortcuts(scenario)
	for _, value in pairs(scenarioShortcuts[scenario]) do
		value:enable()
	end
end

local function disableScenarioShortcuts(scenario)
	for _, value in pairs(scenarioShortcuts[scenario]) do
		value:disable()
	end
	-- print(serializeTable(scenarioShortcuts))
end

-- main fn
local function applicationWatcher(appName, eventType, appObject)
	print(appName .. " active!!!")
	if eventType == hs.application.watcher.activated then
		-- 初始化senarioShortcuts
		if appName == "Finder" then
			-- Bring all Finder windows forward when one gets activated
			appObject:selectMenuItem({ "Window", "Bring All to Front" })
		end
		-- if appName == "iTerm2" then
		-- 	showFocusAlert("TERMINAL")
		-- 	enableScenarioShortcuts("tmux")
		-- 	disableScenarioShortcuts("chrome")
		-- end
		if appName == "Google Chrome" then
			showFocusAlert("CHROME")
			enableScenarioShortcuts("chrome")
			disableScenarioShortcuts("tmux")
		end
	end
	-- print("current" .. serializeTable(scenarioShortcuts))
end
local appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

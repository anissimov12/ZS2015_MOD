-- centralized functions for calling logs

ZS = ZS or {}
ZS.Log = ZS.Log or {}

ZS.Log.LEVEL_INFO = 1
ZS.Log.LEVEL_WARNING = 2
ZS.Log.LEVEL_ERROR = 3
ZS.Log.LEVEL_DEBUG = 4

ZS.Log.CurrentLevel = ZS.Log.LEVEL_INFO

local COLOR_INFO = Color(100, 200, 255)
local COLOR_WARNING = Color(255, 200, 100)
local COLOR_ERROR = Color(255, 100, 100)
local COLOR_DEBUG = Color(150, 150, 150)
local COLOR_WHITE = Color(255, 255, 255)

-- main function for call function

function ZS.Log:Print(level, module, ...)
	if level < self.CurrentLevel then return end
	
	local prefix = "[ZS"
	local color = COLOR_INFO
	
	if module and module ~= "" then
		prefix = prefix .. ":" .. module
	end
	
	prefix = prefix .. "]"
	
	if level == self.LEVEL_WARNING then
		color = COLOR_WARNING
	elseif level == self.LEVEL_ERROR then
		color = COLOR_ERROR
	elseif level == self.LEVEL_DEBUG then
		color = COLOR_DEBUG
	end
	
	if CLIENT then
		MsgC(color, prefix, COLOR_WHITE, " ", ...)
		MsgN()
	else
		print(prefix, ...)
	end
end

function ZS.Log:Info(module, ...)
	self:Print(self.LEVEL_INFO, module, ...)
end

function ZS.Log:Warning(module, ...)
	self:Print(self.LEVEL_WARNING, module, ...)
end

function ZS.Log:Error(module, ...)
	self:Print(self.LEVEL_ERROR, module, ...)
end

function ZS.Log:Debug(module, ...)
	self:Print(self.LEVEL_DEBUG, module, ...)
end

-- simple functions for ease of use

function ZSLog(...)
	ZS.Log:Info("", ...)
end

function ZSLogModule(module, ...)
	ZS.Log:Info(module, ...)
end

function ZSLogError(module, ...)
	ZS.Log:Error(module, ...)
end

function ZSLogDebug(module, ...)
	ZS.Log:Debug(module, ...)
end

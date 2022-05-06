--!strict

--[=[
	@class ApiDumpRaw

	The raw API dump from [Roblox-Client-Tracker/API-Dump.json](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/API-Dump.json).
]=]

--[=[
	@interface Property
	@within ApiDumpRaw
	.MemberType "Property"
	.Name string
	.Security { [string]: string }
	.Serialization { [string]: string }
	.ThreadSafety string
	.ValueType { Category: string, Name: string }
]=]

export type Property = {
	MemberType: "Property",
	Category: string,
	Name: string,
	Security: { [string]: string },
	Serialization: { [string]: string },
	ThreadSafety: string,
	ValueType: { Category: string, Name: string },
	[string]: any,
}

--[=[
	@interface Method
	@within ApiDumpRaw
	.MemberType "Function"
	.Name string
	.Parameters { { Name: string, Type: { Category: string, Name: string } } }
	.ReturnType: { Category: string, Name: string }
	.Security: string | { [string]: string }
	.ThreadSafety: string
]=]

export type Method = {
	MemberType: "Function",
	Name: string,
	Parameters: { {
		Name: string,
		Type: {
			Category: string,
			Name: string,
		},
	} },
	ReturnType: {
		Category: string,
		Name: string,
	},
	Security: string | { [string]: string },
	ThreadSafety: string,
	[string]: any,
}

--[=[
	@interface Event
	@within ApiDumpRaw
	.MemberType "Event"
	.Name string
	.Parameters { { Name: string, Type: { Category: string, Name: string } } }
	.Security string | { [string]: string }
	.ThreadSafety string
]=]

export type Event = {
	MemberType: "Event",
	Name: string,
	Parameters: { {
		Name: string,
		Type: {
			Category: string,
			Name: string,
		},
	} },
	Security: string | { [string]: string },
	ThreadSafety: string,
}

--[=[
	@interface Callback
	@within ApiDumpRaw
	.MemberType "Callback"
	.Name string
	.Parameters { { Name: string, Type: { Category: string, Name: string } } }
	.ReturnType { Category: string, Name: string }
	.Security string | { [string]: string }
	.ThreadSafety string
]=]

export type Callback = {
	MemberType: "Callback",
	Name: string,
	Parameters: { {
		Name: string,
		Type: {
			Category: string,
			Name: string,
		},
	} },
	ReturnType: {
		Category: string,
		Name: string,
	},
	Security: string | { [string]: string },
	ThreadSafety: string,
}

--[=[
	@type Member Property | Method | Event | Callback
	@within ApiDumpRaw

]=]

export type Member = Property | Method | Event | Callback

--[=[
	@interface RawClass
	@within ApiDumpRaw
	.Name string
	.Members { Member }
	.MemoryCategory string
	.Superclass string
	.Tags { string }?
]=]

export type RawClass = {
	Members: { Member },
	MemoryCategory: string,
	Name: string,
	Superclass: string,
	Tags: { string }?,
}

--[=[
	@interface RawEnum
	@within ApiDumpRaw
	.Name string
	.Items { { Name: string, Value: number } }
]=]

export type RawEnum = {
	Name: string,
	Items: { { Name: string, Value: number } },
}

--[=[
	@prop Classes { RawClass }
	@within ApiDumpRaw
]=]

--[=[
	@prop Enums { RawEnum }
	@within ApiDumpRaw
]=]

--[=[
	@prop Version number
	@within ApiDumpRaw
]=]

type RawDump = {
	Classes: { RawClass },
	Enums: { RawEnum },
	Version: number,
	[string]: any,
}

local dump: RawDump = {
	Classes = {},
	Enums = {},
	Version = 0,
}

for _, child in ipairs(script.Parent.generated:GetChildren()) do
	if child.Name:match("^classes") then
		-- require must be cast to any to avoid unsupported require path warning
		for _, item in ipairs((require :: any)(child).Classes) do
			table.insert(dump.Classes, item)
		end
	elseif child.Name:match("^enums") then
		for _, item in ipairs((require :: any)(child).Enums) do
			table.insert(dump.Enums, item)
		end
	else
		for key, value in pairs((require :: any)(child)) do
			dump[key] = value
		end
	end
end

local function freezeDeep(target: { [any]: any })
	table.freeze(target)

	for key, value in pairs(target) do
		if typeof(key) == "table" and not table.isfrozen(key) then
			freezeDeep(key)
		end
		if typeof(value) == "table" and not table.isfrozen(value) then
			freezeDeep(value)
		end
	end
end

freezeDeep(dump)

return dump

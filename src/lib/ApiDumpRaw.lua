--!strict

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
export type Member = Property | Method | Event | Callback

export type RawClass = {
	Members: { Member },
	MemoryCategory: string,
	Name: string,
	Superclass: string,
	Tags: { string }?,
}

export type RawEnum = {
	Name: string,
	Items: { { Name: string, Value: number } },
}

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

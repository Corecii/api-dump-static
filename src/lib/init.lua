--!strict
local ApiDumpRaw = require(script.ApiDumpRaw)

local ApiDump = {}

local classes: { [string]: Class } = {}
local processedSubclasses = false

local Class = {}
Class.__index = Class

export type Property = ApiDumpRaw.Property
export type Method = ApiDumpRaw.Method
export type Event = ApiDumpRaw.Event
export type Callback = ApiDumpRaw.Callback
export type Member = ApiDumpRaw.Member

type Class = typeof(setmetatable(
	{} :: {
		Name: string,
		SuperName: string,
		Tags: { string },
		MemoryCategory: string,
		_combined: {
			properties: { [string]: Property }?,
			methods: { [string]: Method }?,
			events: { [string]: Event }?,
			callbacks: { [string]: Callback }?,
			members: { [string]: Member }?,
		},
		_my: {
			properties: { [string]: Property },
			methods: { [string]: Method },
			events: { [string]: Event },
			callbacks: { [string]: Callback },
			members: { [string]: Member },
		},
		-- Other internal nilable properties are stored under _other so that we
		-- can freeze the class objects.
		_other: {
			tagsSet: { [string]: boolean }?,
			subclasses: { [string]: Class }?,
			defaultInstance: Instance?,
			defaultProperties: { [string]: any }?,
		},
	},
	Class
))

function Class.new(definition: ApiDumpRaw.RawClass): Class
	local self = {}
	setmetatable(self, Class)

	local properties = {}
	local methods = {}
	local events = {}
	local callbacks = {}
	local members = {}

	for _, member in ipairs(definition.Members) do
		if member.MemberType == "Property" then
			properties[member.Name] = member
		elseif member.MemberType == "Function" then
			methods[member.Name] = member
		elseif member.MemberType == "Event" then
			events[member.Name] = member
		elseif member.MemberType == "Callback" then
			callbacks[member.Name] = member
		end

		members[member.Name] = member
	end

	-- We cannot assert all of the required fields for _combined and _my, so we
	-- must cast them to any.

	self._combined = {} :: any

	self._my = {
		properties = properties,
		methods = methods,
		events = events,
		callbacks = callbacks,
		members = members,
	} :: any

	self._other = {}

	self.Name = definition.Name
	self.SuperName = definition.Superclass
	self.Tags = definition.Tags or table.freeze({})
	self.MemoryCategory = definition.MemoryCategory

	table.freeze(self)
	table.freeze(self._my)

	return self
end

function Class._getCombined(
	self: Class,
	target: "properties" | "methods" | "events" | "callbacks" | "members"
): { [string]: Member }
	if not self._combined[target] then
		local combined = {}
		local super = self:Superclass()
		if super then
			for key, value in pairs(super:_getCombined(target)) do
				combined[key] = value
			end
		end

		for key, value in pairs(self._my[target]) do
			combined[key] = value
		end

		self._combined[target] = combined
	end

	return self._combined[target]
end

-- We must cast the returns of these to any since the Luau typechecker is
-- incapable of knowing that GetCombined returns the wanted type instead of
-- Member.

function Class.Properties(self: Class): { [string]: Property }
	return self:_getCombined("properties") :: any
end

function Class.Methods(self: Class): { [string]: Method }
	return self:_getCombined("methods") :: any
end

function Class.Events(self: Class): { [string]: Event }
	return self:_getCombined("events") :: any
end

function Class.Callbacks(self: Class): { [string]: Callback }
	return self:_getCombined("callbacks") :: any
end

function Class.Members(self: Class): { [string]: Member }
	return self:_getCombined("members") :: any
end

function Class.HasTag(self: Class, tag): boolean
	if not self._other.tagsSet then
		local set = {}
		for _, tagInner in ipairs(self.Tags) do
			set[tagInner] = true
		end
		self._other.tagsSet = set
	end
	assert(self._other.tagsSet, "always") -- typechecker assert

	return self._other.tagsSet[tag] or false
end

function Class.Superclass(self: Class): Class?
	return classes[self.SuperName]
end

function Class.Subclasses(self: Class)
	if not processedSubclasses then
		for className, class in pairs(classes) do
			local super = class:Superclass()
			if super then
				if not super._other.subclasses then
					super._other.subclasses = {}
				end
				assert(super._other.subclasses, "always") -- typechecker assert

				super._other.subclasses[className] = class
			end
		end

		processedSubclasses = true
	end

	return self._other.subclasses or {}
end

function Class.GetPropertyDefault(self: Class, propertyName: string)
	if not self._other.defaultInstance then
		if self:HasTag("NotCreatable") then
			return
		end

		-- Instance.new must be cast to support creation from unknown
		-- strings
		self._other.defaultInstance = (Instance.new :: any)(self.Name)
	end
	assert(self._other.defaultInstance, "always") -- typechecker assert

	if not self._other.defaultProperties then
		self._other.defaultProperties = {}
	end
	assert(self._other.defaultProperties, "always") -- typechecker assert

	if self._other.defaultProperties[propertyName] == nil then
		-- must be cast to support string indexing
		self._other.defaultProperties[propertyName] = (self._other.defaultInstance :: any)[propertyName]
	end

	return self._other.defaultProperties[propertyName]
end

table.freeze(Class)

for _, definition in ipairs(ApiDumpRaw.Classes) do
	classes[definition.Name] = Class.new(definition)
end

table.freeze(classes)

ApiDump.Classes = classes

ApiDump.Raw = ApiDumpRaw

table.freeze(ApiDumpRaw)

return ApiDump

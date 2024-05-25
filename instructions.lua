-- Local references for shorter names and avoiding global lookup on every use
local Get, GetNum, GetId, GetEntity, AreEqual, Set = InstGet, InstGetNum, InstGetId, InstGetEntity, InstAreEqual, InstSet


-- Hook behavior start to initialize arrays - Thanks for the help, Malk!
local c_behavior = data.components["c_behavior"]
local orig_behavior_on_update = c_behavior.on_update
function c_behavior:on_update(comp, cause)
    orig_behavior_on_update(self, comp, cause)
	if cause & CC_ACTIVATED == CC_ACTIVATED then
        Arrays_Init(comp, state)
    end
end

-- Helper func to pull arrays from state.
function Arrays_GetSubarray(comp, state, table_id)

    local ID = tostring(Get(comp, state, table_id))
    --print("ID:", ID)
    --print(tostring(ID))

    
    if comp.extra_data.arrays == nil then
        comp.extra_data.arrays = {}
    end
    if comp.extra_data.arrays[ID] == nil then
        comp.extra_data.arrays[ID] = {}
    end
    
    return comp.extra_data.arrays[ID]
    
end

function Arrays_Init(comp, state)
    comp.extra_data.arrays={}
end




data.instructions.mod_array_push =
{
	func = function(comp, state, cause, value, id)
        local arr = Arrays_GetSubarray(comp, state, id)
        arr[#arr+1] = Tool.NewRegisterObject(Get(comp, state, value))
	end,
	args = {
		{ "in", "Value", nil, "any" },
		{ "in", "ID" , nil, "any"},
	},
	name = "Array Push",
	desc = "Pushes Input to the end of the array",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}

data.instructions.mod_array_set =
{
	func = function(comp, state, cause, value, id, index)
		local ix = GetNum(comp, state, index)
        local arr = Arrays_GetSubarray(comp, state, id)
        arr[ix] = Tool.NewRegisterObject(Get(comp, state, value))
	end,
	args = {
		{ "in", "Value", nil, "any" },
		{ "in", "ID" , nil, "any"},
		{ "in", "index" , nil, "num"},
	},
	name = "Array Set",
	desc = "Set id[index]",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}

data.instructions.mod_array_get =
{
	func = function(comp, state, cause, value, id, index)
		local ix = GetNum(comp, state, index)
        local arr = Arrays_GetSubarray(comp, state, id)
		local val = arr[ix]
        Set(comp, state, value, val)
	end,
	args = {
		{ "out", "Value", nil, "any" },
		{ "in", "ID" , nil, "any"},
		{ "in", "index" , nil, "num"},
	},
	name = "Array Get",
	desc = "returns id[index]",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}

data.instructions.mod_array_pop =
{
	func = function(comp, state, cause, value, id)
        local arr = Arrays_GetSubarray(comp, state, id)
		local max_ix = nil
		for ix in pairs(arr) do
			print(max_ix, ix)
			if max_ix == nil or ix > max_ix then
				max_ix = ix
			end
		end
        if max_ix  then
            local val = arr[max_ix]
			arr[max_ix] = nil
			Set(comp, state, value, val)
		else
			Set(comp, state, nil)
		end
	end,
	args = {
		{ "out", "Value", nil, "any" },
		{ "in", "ID" , nil, "any"},
	},
	name = "Array Pop",
	desc = "Removes and returns the last element in an array",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}

data.instructions.mod_array_length =
{
	func = function(comp, state, cause, value, id)
        local arr = Arrays_GetSubarray(comp, state, id)
        -- nonsparse method
		--local count = #arr

		-- sparse method
		local count = 0
		for _ in pairs(arr) do
			count = count+1
		end

        Set(comp, state, value, { num=count})
	end,
	args = {
		{ "out", "Value", nil, "any" },
		{ "in", "ID" , nil, "any"},
	},
	name = "Array Length",
	desc = "Measures the length of the Array",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}

-- Removes all elements from the array leaving it empty
data.instructions.mod_array_clear =
{
	func = function(comp, state, cause, value, id)
        local arr = Arrays_GetSubarray(comp, state, id)
        local arr = {}

	end,
	args = {
		{ "in", "ID" , nil, "any"},
	},
	name = "Array Clear",
	desc = "Removes all elements from an array, leaving it empty",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}

--[[
data.instructions.dbg =
{
	func = function(comp, state, cause, reg)
        local value = Get(comp, state, reg)
        print(tostring(value))

	end,
	args = {
		{ "in", "value" , nil, "any"},
	},
	name = "DEBUG",
	desc = "GIMME DATA",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}
]]
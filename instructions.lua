-- Local references for shorter names and avoiding global lookup on every use
--local Get, GetNum, GetId, GetEntity, AreEqual, Set = InstGet, InstGetNum, InstGetId, InstGetEntity, InstAreEqual, InstSet
local Get, GetNum, GetCoord, GetId, GetEntity, AreEqual, Set, BeginBlock = InstGet, InstGetNum, InstGetCoord, InstGetId, InstGetEntity, InstAreEqual, InstSet, InstBeginBlock


-- Hook behavior start to initialize arrays - Thanks for the help, swazrgb!
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

-- Helper func to clear a subarray and return a reference.
function Arrays_GetCleanSubarray(comp, state, table_id)

    local ID = tostring(Get(comp, state, table_id))
    --print("ID:", ID)
    --print(tostring(ID))    
    if comp.extra_data.arrays == nil then
        comp.extra_data.arrays = {}
    end

    comp.extra_data.arrays[ID] = {}
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
			if max_ix == nil or ix > max_ix then
				max_ix = ix
			end
		end
        if max_ix  then
            local val = arr[max_ix]
			arr[max_ix] = nil
			Set(comp, state, value, val)
		else
			Set(comp, state, value, nil) -- {num=0})
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

data.instructions.mod_array_for_elements =
{
	func = function(comp, state, cause, id, value, index, exec_done)
		local arr = Arrays_GetSubarray(comp, state, id)
		local it = { 2 }

		local indices = {}
		for ix in pairs(arr) do
			table.insert(indices, ix)
		end
		table.sort(indices)

		for _, index in ipairs(indices) do
		--for index in pairs(arr) do
			it[#it+1] = {index, Tool.NewRegisterObject(arr[index])}
		end
		print(it)

		return BeginBlock(comp, state, it)
	end,

	next = function(comp, state, it, id, value, index, exec_done)
		local i = it[1]
		if i > #it then return true end
		Set(comp, state, index, {num=it[i][1]})
		Set(comp, state, value, it[i][2])
		it[1] = i + 1
	end,

	last = function(comp, state, it, id, value, index, exec_done)
		state.counter = exec_done
	end,

	args = {
		{ "in", "ID", "Signal" },
		{ "out", "Value", "Value from array" , "any"},
		{ "out", "Index", "Current Index in array" , "num"},
		{ "exec", "Done", "Finished looping through all entities with signal" },
	},


	name = "Loop Elements",
	desc = "Performs code for all entities in visibility range of the unit",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Make Order.png",
}

data.instructions.array_recipe_ingredients =
{
	func = function(comp, state, cause, product, id)
        local arr = Arrays_GetCleanSubarray(comp, state, id)

		local item_id = GetId(comp, state, product)
		local product_def, ingredients = item_id and data.all[item_id]
		local ent = not product_def and GetEntity(comp, state, product)

		if product_def then
			local production_recipe = product_def and (product_def.production_recipe or product_def.construction_recipe)
			ingredients = production_recipe and production_recipe.ingredients

			-- is Research (uplink_recipe)
			if not ingredients then
				production_recipe = product_def.uplink_recipe
				ingredients = production_recipe and production_recipe.ingredients

				if (ingredients) then
					local is_unlocked = comp.faction:IsUnlocked(item_id)
					local progress = comp.faction.extra_data.research_progress and comp.faction.extra_data.research_progress[item_id] or 0
					local remain = (product_def.progress_count and product_def.progress_count or progress) - progress

					if not is_unlocked and remain > 0 and ingredients then
						local it = { 2 }
						if ingredients then
							-- return the remainder of the research, not just one stack
							for item,n in pairs(ingredients) do
								it[#it + 1] = { id = item, num = n*remain }
							end

							return BeginBlock(comp, state, it)
						end
					else
						Set(comp, state, out_ingredient)
						return
					end
				end
			else
				-- if not research and unlocked send the product
				if not comp.faction:IsUnlocked(item_id) then
					Set(comp, state, out_ingredient)
					state.counter = exec_done
					return
				end
			end
		elseif ent then
			if ent.def.id == "f_construction" then
				local fd, bd = GetProduction(ent:GetRegisterId(FRAMEREG_GOTO), ent)
				ingredients = GetConstructionIngredients(fd, bd)
			else
				if ent.def.convert_to then
					-- unpacked items return their packaged form recipe instead
					item_id = ent.def.convert_to
				else
					item_id = ent.def.id
				end

				if not comp.faction:IsUnlocked(item_id) then
					Set(comp, state, out_ingredient)
					state.counter = exec_done
					return
				end

				-- from the entity get whether it's a bot or a building from the def.id
				product_def = data.all[item_id]
				local production_recipe = product_def and (product_def.production_recipe or product_def.construction_recipe)
				ingredients = production_recipe and production_recipe.ingredients
			end
		end
		print(ingredients)
		print(out_ingredient)

		if ingredients then
			for item,n in pairs(ingredients) do
				arr[#arr + 1] = Tool.NewRegisterObject({ id = item, num = n })
			end
		else
			arr[#arr + 1] = out_ingredient
		end
	end,

	args = {
		
		{ "in", "Recipe" , nil, "any"},
		{ "in", "ID" , nil, "any"},
	},
	name = "Array Recipe",
	desc = "Fills an Array with a recipe",
	category = "Array",
	icon = "Main/skin/Icons/Special/Commands/Add Numbers.png",
}

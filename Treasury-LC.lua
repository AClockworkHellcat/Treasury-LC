_addon.name = 'Treasury-LC'
_addon.author = 'Ihina (original) - KateFFXI (improvements) - AClockworkHellcat (Lua config conversion)'
_addon.version = '3.1'
_addon.commands = {'treasury', 'tr'}

--These six could be replaced with require('luau'), but anyone who wants to mess with this might like to know exactly which libs are used.
require('logger')
require('strings')
require('tables')
require('lists')
require('sets')
res = require('resources')

files = require('files')
packets = require('packets')
require('pack')
require('chat')


--Putting these in functions isn't strictly necessary, but keeping the code tidy and readable is nice.
function save_settings()
    settings_file:write('return' .. T(settings):tovstring())
end
function initialize()
    player = windower.ffxi.get_player()

    if not windower.dir_exists(windower.addon_path..'data') then
        windower.create_dir(windower.addon_path..'data')
    end

	settings_file = files.new('data/'..player.name..'_data.lua')

	if settings_file:exists() then
		windower.add_to_chat(2,'Treasury: Loading File: '..player.name..'_data.lua')
	else
		windower.add_to_chat(2,'Treasury: New character detected, Creating file: '..player.name..'_data.lua')
        settings = T{}
        settings.Pass = T{}
        settings.Lot = T{}
        settings.Drop = T{}
        settings.AutoDrop = false
        settings.AutoStack = true
        settings.Delay = 0.5
        settings.Verbose = true
		settings_file:write('return ' .. T(settings):tovstring())
	end

	settings = require('data/'..player.name..'_data')

    duplicate_rare = false

    all_ids = T{}
    for item in res.items:it() do
        local name = item.name:lower()
        if not all_ids[name] then
            all_ids[name] = S{}
        end
        local name_log = item.name_log:lower()
        if not all_ids[name_log] then
            all_ids[name_log] = S{}
        end
        all_ids[name]:add(item.id)
        all_ids[name_log]:add(item.id)
    end

    code = {}
    code.pass = S{}
    code.lot = S{}
    code.drop = S{}

    local extract_ids = function(nametable, key)
        local idSet = S{}
        for k,v in pairs(nametable[key]) do
            if all_ids[k] then
                idSet:add(all_ids[k])
            end
        end
        return idSet
    end


    code.pass = extract_ids(settings, 'Pass')
    code.lot = extract_ids(settings, 'Lot')
    code.drop = extract_ids(settings, 'Drop')


    lotpassdrop_commands = T{
        lot = 'Lot',
        l = 'Lot',
        pass = 'Pass',
        p = 'Pass',
        drop = 'Drop',
        d = 'Drop',
    }

    addremove_commands = T{
        add = 'add',
        a = 'add',
        ['+'] = 'add',
        remove = 'remove',
        r = 'remove',
        ['-'] = 'remove',
    }

    bool_values = T{
        ['on'] = true,
        ['1'] = true,
        ['true'] = true,
        ['off'] = false,
        ['0'] = false,
        ['false'] = false,
    }

    inventory_id = res.bags:with('english', 'Inventory').id
end

function lotpassdrop(command1, command2, ids)
    local action = command1:lower()
    --I don't know what this is supposed to do but I don't like it.
    names = ids:map(table.get-{'name'} .. table.get+{res.items})
    if command2 == 'add' then
        log('Adding to ' .. action .. ' list:', names)
        code[action] = code[action] + ids
        for name in names:it() do
            settings[command1][name]=true
        end
    else
        log('Removing from ' .. action .. ' list:', names)
        code[action] = code[action] - ids
        for name in names:it() do
            settings[command1][name]=nil
        end
    end

    save_settings()
    force_check(command1 == 'Drop')
end

--There doesn't seem much point using varargs in a function that gets called repeatedly anyway, and it kept breaking.
function act(action, output, id, index)
    if settings.Verbose then
        log('%s %s':format(output, res.items[id].name:color(258)))
    end

	local name = player.name
	local our_delay = 0
    --I assume this was written just to avoid using math.random(). I've long suspected FFXI uses a similar function for most RNG tasks.
	sum = 0
	for key in name:gmatch"." do
		vari = string.byte(key)
		sum = sum + vari
	end

	local final = (((sum / string.len(name)) + string.len(name)) - (string.len(name) * 0.005))
	if final < 0 then
		final = final * -1
	end
	if final > 26 then
		final = (final / string.len(name)) * 0.057185
	end

	our_delay = (final + settings.Delay)

	if our_delay > 7 then
		our_delay = our_delay - 3.581
	elseif our_delay > 6 and our_delay < 7 then
		our_delay = our_delay - 1.138
	end
    --As far as I can tell, prepare() serves no purpose in these scheduling functions.
	local fn windower.ffxi[action]:schedule(our_delay, index)
end
function pass(eyedee, slott)
    act('pass_item', 'Passing', eyedee, slott)
end
function lot(eyedee, slott)
    act('lot_item', 'Lotting', eyedee, slott)
end
function drop(eyedee, slott)
    act('drop_item', 'Dropping', eyedee, slott)
end
--How was something like pass=act+{'pass_item','Passing'} even supposed to work? Because it didn't. FOH.
--Everything from here on out works, I haven't had to mess with it.
function force_check()
    local items = windower.ffxi.get_items()

    -- Check treasure pool
    for index, item in pairs(items.treasure) do
        check(index, item.item_id)
    end

    -- Check inventory for unwanted items
    if settings.AutoDrop then
        for index, item in pairs(items.inventory) do
            if type(item) == 'table' and code.drop:contains(item.id) and item.status == 0 then
                drop(item.id, index, item.count)
            end
        end
    end
end

function check_lot(slot_index, item_id)
	local inventory = windower.ffxi.get_items(inventory_id)

	bags = {0,1,2,4,5,6,7,9}	-- Non equipment
	equip_bags = {0,1,2,4,5,6,7,8,9,10,11,12,13,14,15,16} -- All inventory

	if IsRare(item_id) then	-- Rare item so do duplicate check if flag is set
		log('Rare item found in pool to lot.')
		duplicate_rare = false

		if IsEquipable(item_id) then -- equippable in pool
			log('Armor or weapon found in pool.')
			for _,bag in ipairs(equip_bags) do
				local storage = windower.ffxi.get_items(bag)
				for _,item in ipairs(storage) do
					if item.id > 0 then
						if item.id == item_id then
							duplicate_rare = true
						end
					end
				end
			end
		else -- non equippable
			for _,bag in ipairs(bags) do
				local storage = windower.ffxi.get_items(bag)
				for _,item in ipairs(storage) do
					if item.id > 0 then
						if item.id == item_id then
							duplicate_rare = true
						end
					end
				end
			end
		end

		if duplicate_rare == true then
			log('Duplicate rare item found, passing.')
			pass(item_id, slot_index)
		else
			log('No duplicate rare item found, lotting.')
			if inventory.max - inventory.count > 1 then
				lot(item_id, slot_index)
			end
		end
	else -- Not rare item, so do regular parse for lotting.
		log('Not rare item, lotting.')
		if inventory.max - inventory.count > 1 then
			 windower.ffxi.lot_item(slot_index)
		end
	end
end

function check(slot_index, item_id)
	coroutine.sleep(1.1)
    if (code.drop:contains(item_id) or code.pass:contains(item_id)) and not code.lot:contains(item_id) then
        pass(item_id, slot_index)
    elseif code.lot:contains(item_id) then
        local inventory = windower.ffxi.get_items(inventory_id)

		--bags = {0,1,2,4,5,6,7,9}	-- Non equipment
		--equip_bags = {0,1,2,4,5,6,7,8,9,10,11,12,13,14,15,16} -- All inventory
		all_bags = res.bags:access(functions.negate(functions.equals('Situational'))):en(functions.negate(functions.equals('Recycle')))
		non_equipment_bags = all_bags:en(functions.negate(string.startswith+{'Wardrobe'}))

		if IsRare(item_id) then	-- Rare item so do duplicate check if flag is set
			log('Rare item found in pool to lot.')
			local bags
			if IsEquipable(item_id) then
				log('Armor or weapon found in pool.')
				bags = all_bags
			else
				bags = non_equipment_bags
			end
			if bags_contain(bags, item_id) then
				log('Duplicate rare item found, passing.')
				pass(item_id, slot_index)
			else
				log('No duplicate rare item found, lotting.')
				if inventory.max - inventory.count > 1 then
					lot(item_id, slot_index)
				end
			end
		else -- Not rare item, so do regular parse for lotting.
			if inventory.max - inventory.count > 1 then
				lot(item_id, slot_index)
			end
		end
    end
end

function bags_contain(bags, item_id)
    for bag in bags:it() do
        local storage = windower.ffxi.get_items(bag.id)
        for _,item in ipairs(storage) do
            if type(item)=='table' and type(item.id)=='number' and item.id == item_id then
                return true
            end
        end
    end
end

function IsRare(id) return S(res.items[id].flags):contains('Rare') end
function IsEquipable(id) return S(res.items[id].flags):contains('Equippable') end

function test(item_id)

end

function find_id(name)
    if name == 'pool' then
        return pool_ids()

    elseif name == 'seals' then
        return S{1126, 1127, 2955, 2956, 2957}

    elseif name == 'currency' then
        return S{1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457}

    elseif name == 'geodes' then
        return S{3297, 3298, 3299, 3300, 3301, 3302, 3303, 3304}

    elseif name == 'avatarites' then
        return S{3520, 3521, 3522, 3523, 3524, 3525, 3526, 3527}

    elseif name == 'crystals' then
        return S{4096, 4097, 4098, 4099, 4100, 4101, 4102, 4103}

    elseif name == 'detritus' then
        return S{9875, 9876}

    elseif name == 'heroism' then
        return S{9877, 9878}

    elseif name == 'moldy' then
        return S{9773, 9830, 9831, 9832, 9833, 9834, 9835, 9836, 9837, 9838, 9839, 9840, 9841, 9843, 9868, 9869, 9870, 9871, 9872, 9873, 9874}

    elseif name == 'dynad' then
        return S{9538, 9539, 9540, 9541, 9542, 9543, 9844, 9845}

    elseif name == 'papers' then
        return S{9544, 9545, 9546, 9547, 9548, 9549, 9550, 9551, 9552, 9553, 9554, 9555, 9556, 9557, 9558, 9559, 9560, 9561, 9562, 9563, 9564, 9565, 9566, 9567, 9568, 9569, 9570, 9571, 9572, 9573, 9574, 9575, 9576, 9577, 9578, 9579, 9580, 9581, 9582, 9583, 9584, 9585, 9586, 9587, 9588, 9589, 9590, 9591, 9592, 9593, 9594, 9595, 9596, 9597, 9598, 9599, 9600, 9601, 9602, 9603, 9604, 9605, 9606, 9607, 9608, 9609, 9610, 9611, 9612, 9613, 9614, 9615, 9616, 9617, 9618, 9619, 9620, 9621, 9622, 9623, 9624, 9625, 9626, 9627, 9628, 9629, 9630, 9631, 9632, 9633, 9634, 9635, 9636, 9637, 9638, 9639, 9640, 9641, 9642, 9643, 9644, 9645, 9646, 9647, 9648, 9649, 9650, 9651, 9652, 9653, 9654, 9655, 9656, 9657, 9658, 9659, 9660, 9661, 9662, 9663, 9664, 9665, 9666, 9667, 9668, 9669, 9670, 9671, 9672, 9673, 9674, 9675, 9676, 9677, 9678, 9679, 9680, 9681, 9682, 9683, 9684, 9685, 9686, 9687, 9688, 9689, 9690, 9691, 9692, 9693, 9694, 9695, 9696, 9697, 9698, 9699, 9700, 9701, 9702, 9703, 9704, 9705, 9706, 9707, 9708, 9709, 9710, 9711, 9712, 9713, 9714, 9715, 9716, 9717, 9718, 9719, 9720, 9721, 9722, 9723, 9724, 9725, 9726, 9727, 9728, 9729, 9730, 9731, 9732, 9733, 9734, 9735, 9736, 9737, 9738, 9739, 9740, 9741, 9742, 9743, 9744, 9745, 9746, 9747, 9748, 9749, 9750, 9751, 9752, 9753, 9754, 9755, 9756, 9757, 9758, 9759, 9760, 9761, 9762, 9763}

    else --There was garbage here. It's gone now.
        return all_ids[name]
    end
end

function pool_ids()
    return S(T(windower.ffxi.get_items().treasure):map(table.get-{'item_id'}))
end

stack = function()
    local wait_time = 0

    return function()
        if os.clock() - last_stack_time > 2 then
            packets.inject(packets.new('outgoing', 0x03A))
            last_stack_time = os.clock()
            wait_time = 0
        elseif os.clock() - last_stack_time > wait_time then
            wait_time = wait_time + 0.45
            stack:schedule(0.5)
        end
    end:cond(function()
        return settings.AutoStack
    end)
end()

stack_ids = S{0x01F, 0x020}
last_stack_time = 0
windower.register_event('incoming chunk', function(id, data)
    if id == 0x0D2 then
			-- small_delay = ((math.random() + 1) / 2 * settings.Delay)
			-- coroutine.sleep(small_delay)
        local treasure = packets.parse('incoming', data)
        check(treasure.Index, treasure.Item)

    elseif stack_ids:contains(id) then
        local chunk = packets.parse('incoming', data)

        -- Ignore items in other bags
        if chunk.Bag ~= inventory_id then
            return
        end

        if id == 0x020 and settings.AutoDrop and code.drop:contains(chunk.Item) and chunk.Status == 0 then
            drop(chunk.Item, chunk.Index, chunk.Count)
        else
            -- Don't need to stack in the other case, as a new inventory packet will come in after the drop anyway
            stack()
        end
    end
end)

windower.register_event('ipc message', function(msg)
    local args = msg:split(' ')
    if args:remove(1) == 'treasury' then
        command1 = args:remove(1)
        command2 = args:remove(1)
        lotpassdrop(command1, command2, S(args):map(tonumber))
    end
end)

windower.register_event('load', force_check:cond(table.get-{'logged_in'} .. windower.ffxi.get_info))

windower.register_event('addon command', function(command1, command2, ...)
    local args = L{...}
    local global = false

    if args[1] == 'global' then
        global = true
        args:remove(1)
    end

    command1 = command1 and command1:lower() or 'help'
    command2 = command2 and command2:lower() or nil

    local name = args:concat(' ')
    if lotpassdrop_commands:containskey(command1) then
        command1 = lotpassdrop_commands[command1]

        if addremove_commands:containskey(command2) then
            command2 = addremove_commands[command2]

            local ids = find_id(name)
            if ids:empty() then
                error('No items found that match: %s':format(name))
                return
            end
            lotpassdrop(command1, command2, ids)

            if global then
                windower.send_ipc_message('treasury %s %s %s':format(command1, command2, ids:concat(' ')))
            end

        elseif command2 == 'clear' then
            code[command1:lower()]:clear()
            settings[command1]:clear()
            save_settings()

        elseif command2 == 'list' then
            log(command1 .. ':')
            for item in settings[command1]:it() do
                log('    ' .. item)
            end

        end

    elseif command1 == 'passall' then
        for slot_index, item_table in pairs(windower.ffxi.get_items().treasure) do
            windower.ffxi.pass_item(slot_index)
        end

    elseif command1 == 'lotall' then
        for slot_index, item_table in pairs(windower.ffxi.get_items().treasure) do
			-- Checks for rare and passes if tries to lot.
			check_lot(slot_index, item_table.item_id)
        end

    elseif command1 == 'clearall' then
        code.pass:clear()
        code.lot:clear()
        code.drop:clear()
        settings.Pass:clear()
        settings.Lot:clear()
        settings.Drop:clear()
        save_settings()

    elseif command1 == 'autodrop' then
        if command2 then
            settings.AutoDrop = bool_values[command2:lower()]
        else
            settings.AutoDrop = not settings.AutoDrop
        end

        save_settings()
        log('AutoDrop %s':format(settings.AutoDrop and 'enabled' or 'disabled'))

    elseif command1 == 'autostack' then
        if command2 then
            settings.AutoStack = bool_values[command2:lower()]
        else
            settings.AutoStack = not settings.AutoStack
        end

        save_settings()
        log('AutoStack %s':format(settings.AutoStack and 'enabled' or 'disabled'))

    elseif command1 == 'delay' then
        if not (command2 and tonumber(command2)) then
            error('Please specify a value in seconds for the new delay')
            return
        end

        settings.Delay = tonumber(command2)
        --If you're changing the delay in the first place, I assume you'd want it saved.
        save_settings()
        log('Delay set to %f seconds':format(settings.Delay))

    elseif command1 == 'verbose' then
        if command2 then
            settings.Verbose = bool_values[command2:lower()]
        else
            settings.Verbose = not settings.Verbose
        end

        save_settings()
        log('Verbose output %s':format(settings.Verbose and 'enabled' or 'disabled'))

    elseif command1 == 'save' then --Redundant, since changing anything saves everything...
        save_settings()

    elseif command1 == 'help' then
        print('%s v%s':format(_addon.name, _addon.version))
        print('    \\cs(255,255,255)lot|pass|drop add|remove <name>\\cr - Adds or removes all items matching <name> to the specified list')
        print('    \\cs(255,255,255)lot|pass|drop clear\\cr - Clears the specified list for the current character')
        print('    \\cs(255,255,255)lot|pass list\\cr - Lists all items on the specified list for the current character')
        print('    \\cs(255,255,255)lotall|passall\\cr - Lots/Passes all items currently in the pool')
        print('    \\cs(255,255,255)clearall\\cr - Removes lotting/passing/dropping settings for this character')
        print('    \\cs(255,255,255)autodrop [on|off]\\cr - Enables/disables (or toggles) the auto-drop setting')
        print('    \\cs(255,255,255)verbose [on|off]\\cr - Enables/disables (or toggles) the verbose setting')
        print('    \\cs(255,255,255)autostack [on|off]\\cr - Enables/disables (or toggles) the autostack feature')
        print('    \\cs(255,255,255)delay <value>\\cr - Allows you to change the delay of actions (default: 0.5)')
	elseif command1 == 'test' then
		test(command2)
    end
end)

initialize()

--[[
Copyright © 2014-2018, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

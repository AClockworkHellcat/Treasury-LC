"Why yet another fork of Treasury?" you may be asking, if indeed you even exist. Well, gentle reader, it's because Config doesn't parse strings from XML files properly. Do you have any idea how many items in this game have apostrophes in their names? Evidently the developers didn't, because adding any of them to Treasury's settings.xml breaks the whole thing because of the godawful HTML escape sequences used. Besides that, it doesn't really behave properly when trying to differentiate between global and character-specific Drop/Lot/Pass lists, so now it only has character-specific ones.

You would be surprised how much of this completely broke just by trying to replace the config file with a format that can actually store strings correctly. Though in the end, Lua can't write strings to files correctly either, and while saving to JSON would solve that issue nicely, Config can only read JSONs, not write to them. Presumably it's because that functionality would be too useful and not sufficiently frustrating.

Current issues:
* You can only add items to lists (or remove them) one at a time, aside from the baked-in wildcards.
* Baked-in wildcards might not actually work. I don't know, I never use them.

Possible future plans:
* save ID sets in the file so the DLP arrays aren't just a bunch of Booleans?
* alternatively, figure out how to get Lua to properly save sets of strings like a real programming language?
* or perhaps be the whole bitch and write a replacement for config that saves to Lua files?



Original readme below.

--------------------------------------------------------------------------------------------------------------------------


# Treasury

An addon that manages the treasure pool for you and keeps your inventory clean of unwanted items. It does three things:
1. It lots/passes on items in the treasure pool based on per-character rules as defined in the settings file
2. It automatically stacks items in your inventory after it changes, if enabled
3. If automatically drops unwanted items from your inventory, if enabled

### Commands

Note:
All commands can be shortened to `//tr`. `lot` and `pass` can be shortened to `l` and `p` respectively. `add` and `remove` can be shortened to `a` or `+` and `r` or `-` respectively.

`//treasuy lot|pass|drop add|remove [global] <name>`

This will add to or remove from the lot list, pass list or drop list all items matching `name`. `name` can contain standard Windower wildcards (`*`, `?`, `|`). It will add those for the current character only, unless `global` is specified, in which case it will add it for all characters.

There are a few special key words for `name`:
* `crystals` matches all crystal items (excluding HQ synthing crystals)
* `geodes` matches all geode items (NQ)
* `avatarites` matches all geode items (HQ)
* `currency` matches all Dynamis currency (all three tiers of all three kinds)
* `seals` matches the standard seals found in the field (BS, KS, KC, HKC, SKC)
* `detritus` matches Swart Astral Detritus and Murky Astral Detritus
* `heroism` matches Heroism Crystal and Heroism Aggregate
* `moldy` matches all Moldy weapons and neck items from Dynamis Divergence
* `dynad` matches all three card types, all three medal types, and the crafting materials from Dynamis Divergence
* `papers` matches all shards and all void items from Dynamis Divergence
* `pool` matches your current treasure pool

'//treasury lot|pass|drop clear|list`

This will either clear the specified list (for the current character only) or list all items on the specified list.

`//treasury lotall|passall`

Lots/passes on all items currently in the pool

`//treasury clearall`

Clears all character-specific settings (it will keep global settings)

`//treasury delay <value>`

Sets the delay that should pass before lotting/passing/dropping items, in seconds. It will lot/pass/drop items in a random time interval between half the value specified and the full value. I.e. if you specify 5 seconds it will lot/pass/drop between 2.5 seconds and 5 seconds randomly.

`//treasury <autodrop|autostack|verbose> [on|off]`

Sets the provided setting to true or false. If neither is provided, it toggles the current setting.

`//treasury save`

Saves the current character's settings for all characters.

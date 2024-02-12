Conceivable questions:
* "Why?": Treasury breaks if you add any item with an apostrophe or period in its name to the lists. Since I did a lot of Dynamis farming for a while, this was unacceptable. JSON has no such problems, but config can't write to them, only read them. Moreover, using a single XML file for both global and character-specific lot/drop/pass lists meant you couldn't have exceptions to the global lot/drop/pass list on any character, and, worse, it just copied the global list into each character-specific list anyway. As such, the global list served no useful purpose, and in fact made the addon less functional.
* "I can do better": That isn't a question, but you probably can.

Current issues:
* Global doesn't work, but to be perfectly honest, it didn't work right in the original either (see above).
* Aside from the built-in keywords (eg. dynad, heroism), you can only add items to lists (or remove them) one at a time. I cannot recall whether this was an issue in the original or not, because I don't think I ever needed to do it.

Possible future plans:
* save ID sets in the file so the DLP arrays aren't just a bunch of Booleans? (Could do, but would it improve anything?)
* alternatively, figure out how to get Lua to properly save sets of strings like a real programming language? (Would require iteration over every item to filter out sets and strings so they're properly delimited.)
* or perhaps be the whole bitch and write an alternative to config that saves to Lua files? (Couldn't do a full drop-in replacement because it would get clobbered anytime Windower updates. However, only having to change one line in an addon to make it save better config files is a tempting prospect. On the other hand, odds are nobody but me would use it anyway.)



Original readme (with necessary corrections) below.

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

This will add to or remove from the lot list, pass list or drop list all items matching `name`. It will add those for the current character only.

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

Lots/passes on all items currently in the pool. Does not alter lot/pass lists.

`//treasury clearall`

Clears all character-specific settings (it will keep global settings)

`//treasury delay <value>`

Sets the minimum amount of time that should pass before lotting/passing/dropping items, in seconds. Originally, this would result in a number of seconds ranging from half of `<delay>` to the full `<delay>` passing between each lot/pass/drop, but it now serves no real purpose and may as well be left at its default setting.

`//treasury <autodrop|autostack|verbose> [on|off]`

Sets the provided setting to true or false. If neither is provided, it toggles the current setting.

`//treasury save`

Saves the current character's settings for all characters.

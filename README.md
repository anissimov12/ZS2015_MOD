# Zombie Survival 2015 Modification

A modified version of the classic **Zombie Survival (2015)** gamemode for **Garry’s Mod**, based on the original project by JetBoom:  
https://github.com/JetBoom/zombiesurvival

## What is this?

**Zombie Survival 2015 Modification** is a community-made fork of the original Zombie Survival gamemode.  
It keeps the core gameplay of Zombie Survival (2015) while introducing balance changes, custom mechanics, and hardcore-oriented ideas.

The main objective remains unchanged:
- **Humans** must survive until the end of the round
- **Zombies** must eliminate all humans

## Concept Credits

Some gameplay concepts and ideas used in this modification were from the server:

**"Русский хардкор ///// N5 /////"**

Examples include (but are not limited to):
- Electrohammer
- Farm mechanics
- Ghosting on air
- And other..

These elements were adapted and reimplemented for this fork.

## How to Run

1. Clone this repository into your `garrysmod/addons` folder:
```bash
git clone https://github.com/anissimov12/ZS2015_MOD.git

2. Launch Garry’s Mod

3. Start the gamemode:
```bash
Zombie Survival
```
or via launch options:
```bash
+gamemode zombiesurvival
```

## Inventory

The gamemode includes a **custom persistent inventory system**.

You can open the inventory in-game by:
- Pressing **F1**
- Selecting the **Inventory** tab

By default, the inventory is **empty**, since there is currently **no shop or market system** implemented.

Items can be added manually using console commands:
- `zs_inv_add <item_id> [player] [count]`
- `zs_inv_del <item_id> [player] [count]`
- `zs_inv_info [player]`

All avalible items from inventory:
```lua
GM.Inventory.ItemsData = GM.Inventory.ItemsData or {
	["electrohammer"] = {
		ID = "electrohammer",
		Name = "Electrohammer",
		Category = "Items",
		DefaultCategory = "Items",
        Model = "models/weapons/w_hammer.mdl",
		GiveClass = "weapon_zs_electrohammer"
	},
	["farm_standard"] = {
		ID = "farm_standard",
		Name = "Farm 'Standard'",
		Category = "Items",
		DefaultCategory = "Items",
        Model = "models/props/cs_office/computer_caseB.mdl",
		GiveClass = "weapon_zs_farm"
	}
}
```
Inventory data is saved per player (by SteamID), persists between sessions, and allows items to be equipped.  
Equipped items are automatically given out at the beginning of the 1st wave to those players who equipped these items.

All data saved in `data/inventory/data.txt`, and loaded too.

## Legal
See the [LICENSE](https://github.com/JetBoom/zombiesurvival/blob/master/LICENSE) file.

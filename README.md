[![](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Ffactorissimo-2-notnotmelon&style=for-the-badge)](https://mods.factorio.com/mod/factorissimo-2-notnotmelon) [![](https://img.shields.io/badge/Discord-Community-blue?style=for-the-badge)](https://discord.gg/SAUq8hcZkq) [![](https://img.shields.io/github/issues/notnotmelon/factorissimo-2-notnotmelon?label=Bug%20Reports&style=for-the-badge)](https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues) [![](https://img.shields.io/github/issues-pr/notnotmelon/factorissimo-2-notnotmelon?label=Pull%20Requests&style=for-the-badge)](https://github.com/notnotmelon/factorissimo-2-notnotmelon/pulls)

## Factorissimo 3

    Factorio is the mind killer. Factorio is the little death that brings total obliteration.
    I will face my Factorio. I will build conveyor belts to let it launch rockets over me and through me.
    And when it has mined everything I will turn the inner eye to see its path.
    Where the Factorio has gone there will be nothing. Only my huge base will remain.
    - Z

Factorissimo is a mod about putting your factory inside buildings, and then putting those buildings inside other buildings.

Help translate this mod on [GitHub](https://github.com/notnotmelon/factorissimo-2-notnotmelon/pulls)  
Also check out the [Space Exploration](https://mods.factorio.com/mod/space-factorissimo-updated) extension for this mod.  
This mod supports [Factorio Maps](https://youtu.be/zDkEtZGG0IQ)  

---

## Features

- **Factory Buildings**: Create dedicated factory buildings where you can place machines, belts, pipes, and more, all inside a compact space.
- **Modular Design**: Need to move? Pack up the building and deploy it somewhere else! The interior will stay intact!
- **Expandable Interiors**: Factorissimo 3 offers multiple building tiers, each with increasing interior space and higher connection count.
- **Recursive Factory Planning**: Design buildings inside of buildings inside of buildings with recursive technology.
- **Space Age**: Factorissimo 3 has 100% compatibility with the Space Age DLC. Every planet has a factory floor that inherits the special mechanics of the parent. How will you design a factory building when all your machines are frozen, puking out spores, or consuming crazy amounts of lava?
- **Multiplayer**: Play with your friends! All scripts are written with multiplayer in mind.
- **Mod Support**: Factorissimo 3 is designed to support all mods. Is a mod misbehaving? Create a bug report on the [GitHub](https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues).

---

## Connections

Place an electric pole near a factory building to connect it to the grid. Once inside a factory building, power is transmitted everywhere without the need for additional electric poles.

![](https://files.catbox.moe/n99rh6.mp4)

Belt, pipe, heat, chest, and circuit connections are formed by placing their respective entity on a factory port. Enable ALT-mode to see the port markers.

![](https://assets-mod.factorio.com/assets/d7e68a857db8c6c98f06db2cd3e5d3ed701918f9.png)

---

## Factory Overlay and Preview Upgrades

This mod contains several quality of life features designed to make expanding the factory as easy as possible.

Hold out any factory building to get a preview camera of what's inside.

![](https://assets-mod.factorio.com/assets/45a9a5801c3beaf17f8b8e334a9d200f64d9a725.png)

Set custom ALT-mode icons using the factory overlay combinator. Pack up the factory building to save all contents inside the item.

![](https://assets-mod.factorio.com/assets/3cfecea1399ba0668a61a64fa6676b76c3960ccd.png)

---

## Recursive Deepcopy

Blueprinting a factory building also clones all of its children. _Infinite production?_

![](https://files.catbox.moe/2lxnxd.mp4)

After researching the factory roboport upgrade, construction bots can enter factory buildings and construct ghosts.

![](https://assets-mod.factorio.com/assets/624cbd5f97d000cba0a10cffd32cd1708de39cd2.png)

**WARNING:** While this feature is extremely powerful, creating a blueprint of a factory that contains copies of itself can lead to unbounded infinite recursion. Factories building factories building factories, consuming the entire universe. Slowly at first, then EXTREMELY quickly as your O(2^N) super exponential growth far exceeds the finite size of reality. Destroy the entire cosmos and convert every remaining particle until there is only...

# FACTORISSIMO

![](https://assets-mod.factorio.com/assets/3f019209ba6a140bc62580cb861643246073f904.png)

...or not. Up to you. Don't forget to set a base case 😉 

---

## Quality

Factorissimo 3 supports quality! Higher quality factory buildings mean more connections that transfer faster.

![](https://assets-mod.factorio.com/assets/d94d181f2f35e65e0bc9df8a6c4dbb510df9178e.png)

---

## Factory floor: Aquilo

The air is frozen. Even inside your shelter the mist and snow are inescapable. Design aquilo production lines inside factory buildings and use factory heat connections to prevent machines from freezing.

![](https://files.catbox.moe/gwrsss.mp4)

---

## Space exploration compatibility
Check out the awesome [space exploration compatibility mod](https://mods.factorio.com/mod/space-factorissimo-lizard) made by Crazy_Editor & Yariazen.

![https://mods.factorio.com/mod/space-factorissimo-lizard](https://assets-mod.factorio.com/assets/7888beb1108a2a7227c95654596b6ef4970f1580.png)

---

## UPS Impact & Optimizations

If you are familiar with Factorissimo 1 or Factorissimo 2, you may also be used to major performance issues while using the mod.  
Good news! Various powerful new modding API features have been added over the years and modern versions of Factorissimo are essentially free for UPS.

- **Linked power poles**: Old versions of the factorio modding API had a bug which allowed power poles to be connected cross-surface. This bug has since been promoted to a feature and is used by Factorissimo 3 to efficiently update the electric network. This technology is also used for factory circuit connections.
- **Linked belts**: Factorio 1.1 added the `linked-belt` prototype. This means belt connections across surfaces no longer are processed `on_tick`.
- **Linked pipes**: Factorio 2.0 added support for linked fluidboxes. This means that factory fluid connections are not updated by script and instead fluid is transferred automatically at the engine level.
- **Item with tags**: Factorio now allows storage of arbitrary metadata on the item stack. This means you are no longer limited to only 99 saved factory buildings.

---

## API

This fork adds an API for better compatibility with other mods. Now you can make mods for a fork of a mod in a game.
For more information see the [FAQ](https://mods.factorio.com/mod/factorissimo-2-notnotmelon/faq)

---

## Credits

- **MagmaMcFry**: Original creator of Factorissimo 1 and Factorissimo 2.
- **TheKingJo**: Upscaled all factory graphics into high-resolution.
- **Crazy_Editor & Yariazen**: Added space exploration compatibility.
- **Calcwizard**: "Packed" factory icon graphic. (MIT)
- **fishbus**: Supplied open-source (MIT) graphics for the borehole pump from the [Factorio+](https://mods.factorio.com/mod/factorioplus) overhaul. Go play it!
- **PlexPt**: Chinese locale.
- **AlexandrPavlovski**: Russian locale.
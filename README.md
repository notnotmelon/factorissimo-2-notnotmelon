[![Release](https://img.shields.io/github/actions/workflow/status/notnotmelon/factorissimo-fork/release.yml?branch=main&style=for-the-badge&label=Release)](https://github.com/notnotmelon/factorissimo-fork) [![](https://img.shields.io/badge/dynamic/json?color=orange&label=Factorio&query=downloads_count&suffix=%20downloads&url=https%3A%2F%2Fmods.factorio.com%2Fapi%2Fmods%2Ffactorissimo-2-notnotmelon&style=for-the-badge)](https://mods.factorio.com/mod/factorissimo-2-notnotmelon) [![](https://img.shields.io/badge/Discord-Community-blue?style=for-the-badge)](https://discord.gg/SAUq8hcZkq) [![](https://img.shields.io/github/issues/notnotmelon/factorissimo-2-notnotmelon?label=Bug%20Reports&style=for-the-badge)](https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues)

### Factorissimo 2

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

#### Electric connections

Electric connections in the original mod were costly for UPS. They were updated every tick for every factory building.
This mod replaces the old system with "cross surface power poles".
This change reduces UPS usage drastically and also makes power connections bi-directional. No more fiddling with power connection settings!

Connecting factory buildings via cross surface poles also makes the power graph look much nicer.

---

#### Belt connections

Factorio update 1.1 added "linked belts" which can connect to each other regardless of distance.
This mod replaces Factorissimo belt connections with these linked belts. This change reduces the mod's UPS usage greatly.
Linked belt connections are roughly equal to chest connections in terms of performance.

![](https://assets-mod.factorio.com/assets/e6f468f778e6efefcb9ad3130ed73ebf3b70ba77.png)

---

#### Fluid connections

This mod reworks fluid connections to be much easier to use. No more "bulk factory input/output" pipes. Instead, all factory fluid connections will have high speed automatically.

![](https://assets-mod.factorio.com/assets/20c5cf177254c32c078313ff8db63f087a501c6a.png)

Additionally, a pipe connection will now only form if there are pipes on both sides of the Factory building.

---

#### Item with tags

In the original mod factories were saved to items by making 99 hidden items, each with a factory save data.
In this fork factories are instead saved directly to the items as item tag data.

This has several advantages
- No more 99 save slot limit. You can have unlimited factory items
- Removed factory requester chests. You can use a normal requester chest now
- The factory overlay config now also shows on the items as a custom item description. No more clicking every factory to see what's inside.

![](https://assets-mod.factorio.com/assets/865bcb203e01f0d14f9dd6bdc804395903bb65eb.png)

---

#### Heat connections

This fork adds heat connections to Factorissimo!

![](https://assets-mod.factorio.com/assets/cd1048268ef2e0ad53a97ccba3543ec8f2f0f8af.png)

---

#### Blueprints

Factory buildings now support blueprints!

![](https://assets-mod.factorio.com/assets/576731baa0392a50702fd3247dc6a1ab674d88a9.png)

NOTE: Factorio blueprints only allow one mod to modify them. If this feature is not working for you, see if anything in your mod list can modify blueprints.

---

#### Spidertrons

You can now enter and exit factory buildings from inside a Spidertron.

![](https://assets-mod.factorio.com/assets/035c890100e2f95671c07aef4e612a645eb5bcf1.png)

---


#### API

This fork adds an API for better compatibility with other mods. Now you can make mods for a fork of a mod in a game.
For more information see the [FAQ](https://mods.factorio.com/mod/factorissimo-2-notnotmelon/faq)

---

#### Installation instructions

If you are making a new save you can install this mod normally from the in-game mod browser.

If you have an existing Factorissimo 2 save from 1.1, follow these steps to migrate
- Backup your save
- Blueprint and deconstruct all your factory building interiors
- Delete Factorissimo2 and install this fork
- Save your game

---

#### Happy Factorissimoing!

![](https://i.redd.it/7mum2yx4lfv71.png)
(Gold star if you can name all the mods in this image)

---

#### Space exploration compatibility
Check out the awesome space exploration compatibility mod made by Crazy_Editor
https://mods.factorio.com/mod/space-factorissimo-lizard
![https://mods.factorio.com/mod/space-factorissimo-lizard](https://assets-mod.factorio.com/assets/7888beb1108a2a7227c95654596b6ef4970f1580.png)
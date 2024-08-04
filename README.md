[![Release](https://github.com/fgardt/factorio-mod-template/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/fgardt/factorio-mod-template/actions/workflows/release.yml)
<!--                           ^======[REPLACE THIS]======^                                                                          ^======[REPLACE THIS]======^  -->

### Fixes several bugs and adds new features to Factorissimo 2

    Factorio is the mind killer. Factorio is the little death that brings total obliteration.
    I will face my Factorio. I will build conveyor belts to let it launch rockets over me and through me.
    And when it has mined everything I will turn the inner eye to see its path.
    Where the Factorio has gone there will be nothing. Only my huge base will remain.
    - Z

Factorissimo is a mod about putting your factory inside buildings, and then putting those buildings inside other buildings.
If you are unfamiliar with the original Factorissimo 2, check out the [Feature Gallery](https://imgur.com/a/eshO8)

I am looking for feedback on this project. Join the [Discord](https://discord.gg/SAUq8hcZkq)
Help translate this mod on [Crowdin](https://crowdin.com/project/factorissimo)
Completed translations: English, Russian, French, Chinese, Spanish

Also check out the [Space Exploration](https://mods.factorio.com/mod/space-factorissimo-updated) extension for this mod.

This mod supports [Factorio Maps](https://youtu.be/zDkEtZGG0IQ)

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Reworked electric connections

Electric connections in the original mod were costly for UPS. They were updated every tick for every factory building.
This mod replaces the old system with "cross surface power poles".
This change reduces UPS usage drastically and also makes power connections bi-directional. No more fiddling with power connection settings!

Connecting factory buildings via cross surface poles also makes the power graph look much nicer.

There was a bug in the original mod that caused accumulators to not function. This issue has been fixed.
![](https://assets-mod.factorio.com/assets/09891726af940e41c39957f607ab072004988d1a.png)

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Reworked belt connections

Factorio update 1.1 added "linked belts" which can connect to each other regardless of distance.
This mod replaces Factorissimo belt connections with these linked belts. This change reduces the mod's UPS usage greatly.
Linked belt connections are roughly equal to chest connections in terms of performance.

![](https://assets-mod.factorio.com/assets/e6f468f778e6efefcb9ad3130ed73ebf3b70ba77.png)

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Reworked fluid connections

This mod reworks fluid connections to be much easier to use. No more "bulk factory input/output" pipes. Instead, all factory fluid connections will have high speed automatically.

![](https://assets-mod.factorio.com/assets/20c5cf177254c32c078313ff8db63f087a501c6a.png)

Additionally, a pipe connection will now only form if there are pipes on both sides of the Factory building.

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Reworked circuit connections

Using the same "cross surface power pole" technology as the electric network, the factory circuit connections will now transfer circuit signals without any delay or UPS cost. They are also bidirectional.
![](https://assets-mod.factorio.com/assets/1779eb8c9bef1dc3d0f6e5a2397e46ee66a0aa3c.png)
![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Item with tags

In the original mod factories were saved to items by making 99 hidden items, each with a factory save data.
In this fork factories are instead saved directly to the items as item tag data.

This has several advantages
- No more 99 save slot limit. You can have unlimited factory items
- Removed factory requester chests. You can use a normal requester chest now
- The factory overlay config now also shows on the items as a custom item description. No more clicking every factory to see what's inside

![](https://assets-mod.factorio.com/assets/865bcb203e01f0d14f9dd6bdc804395903bb65eb.png)
![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Heat connections

This fork adds heat connections to Factorissimo!
![](https://assets-mod.factorio.com/assets/cd1048268ef2e0ad53a97ccba3543ec8f2f0f8af.png)
![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Blueprints

Factory buildings now support blueprints!
![](https://assets-mod.factorio.com/assets/576731baa0392a50702fd3247dc6a1ab674d88a9.png)

NOTE: Factorio blueprints only allow one mod to modify them. If this feature is not working for you, see if anything in your mod list can modify blueprints.

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Map features

This fork changes factory building generation to all spawn on the same surface, separated by some distance. (Can be disabled in mod settings)
You can now see any factory building from the map view. There are hidden radars on every building.
![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Reduced entity count

A single Mk3 Factorissimo in the original mod was made from 97 entities. In this fork, the Mk3 only uses 5 entities.

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Spidertrons

You can now enter and exit factory buildings from inside a Spidertron.
![](https://assets-mod.factorio.com/assets/035c890100e2f95671c07aef4e612a645eb5bcf1.png)
![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Improved pollution mechanics

The original version had a bug that caused factory buildings to never be targeted by biters. This has been fixed
Pollution transfer has been optimized
Factory buildings will now drop themselves on the ground when they die instead of being deleted

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### More connection types

This fork allows you to connect more objects to factory buildings. All newly supported objects:
linked-belt, loader-1x1, loader, pump, infinity-chest, linked-chest, infinity-pipe, offshore-pump, splitter
![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### API

This fork adds an API for better compatibility with other mods. Now you can make mods for a fork of a mod in a game.
For more information see the [FAQ](https://mods.factorio.com/mod/factorissimo-2-notnotmelon/faq)

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Installation instructions

If you are making a new save you can install this mod normally.

If you have an existing Factorissimo 2 save, follow these steps to migrate
- Backup your save
- Blueprint and deconstruct all your factory building interiors
- Delete Factorissimo2 and install this fork
- Save your game

![](https://mods-data.factorio.com/assets/4b89c9d3e7ae1cbb8457f0ae75444976ee64570f.png)
#### Happy Factorissimoing!

![](https://i.redd.it/7mum2yx4lfv71.png)

(Gold star if you can name all the mods in this image)

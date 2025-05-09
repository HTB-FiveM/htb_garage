# A better vehicle garage system for FiveM RP by Harry The Bastard

**Motivation**

We started our Role Play server with a basic garage system which worked nicely but had many issues. The ESX default menu used was limited and once you start acquiring many vehicles there was no sorting or filtering possible. We investigated other options including commercial resources which were mostly disappointing. One company in particular whose garage we purchased had some brilliant features and was visually exactly what I wanted to use, but past experiences with their support team on other of their products was disappointing and given I was having trouble integrating their garage and their system was obfuscated the thought of having to deal with them for support was frustrating enough to decide that writing my own system from the ground up was the only option. I have included features that I've seen in other garages and also implemented some of my own unique ideas. The only code that isn't original is the garage configuration which I lifted from jb eden garage as the configuration was pretty solid and locations were all there and ready to go. I've also integrated some code from ESX for spawning and despawning vehicles so that the resource can run fully stand alone. One interesting metric...in the city we run my character has 248 owned vehicles. When we isntalled a paid garage it took in excess of 5 seconds to list the vehicles and the whole game would lock up during the fetch time. htb_garage on the exact same dataset takes under 1 second and nothing freezes.

**Goals**

I've been developing for FiveM for almost 12 months now. I had never worked with LUA so there was alot of leaning on existing examples to try to learn the syntax and general coding practices for the base language but there's also how to cater for the architecture that FiveM mandates. Using ESX 1.2 Final provided us with a fairly solid starting point but that framework has such a fundamentally flawed architecture that we spent alot of time re-writing many of the supporting addon resources to get a stable system. My key goal with this first public resource is to build something that can be re-used by anyone and integrate with any framework, be clearly written and easy to adapt over time. I am trying to use clean code to demonstrate how people could approach coding to produce better quality work. I would like to think that what I do here triggers clearer thinking, particularly for new developers for whom FiveM is their first coding experience. I have included some original ideas and re-used standard patterns, for example I've included a clean way for people to configure the identifier they wish to use, eg steam, identifier, discord, etc as well as a neat way to configure the framework in use and be able to cleanly switch between them. For sorting a list rather than looping and coming up with the slowest possible pattern in LUA I've used a Binary Tree to add potentially random data into a list sorting efficiently at the time of insert and being able to traverse it efficiently for display. I hope my work can help show a different way of thinking about coding for FiveM.

 **Features**
 
 * Every parking garage has a set number of spawn locations. If the first position is occupied by a vehicle or ped then the next spawn location is checked, looping through until one is free or the player is notified that there a no positions available.
 * Vehicle menu can filter the vehicle list as you type. The text compares the internal model name of the vehicle as well as plate, display and nickname.
 * Set a nickname for the vehicle.
 * If a vehicle is out in the world you can pay for a retrieve.
 * If you prefer not to pay for a retrieve a GPS waypoint can be added to the minimap.
 * If the vehicle is marked as impounded you won't be able to spawn it.
 * Transfer ownership to another player.
 * All players occupying seats of a boat will be spawned on the dock rather than dropped in the water where the boat was prior to despawn.
 * Event handlers provided to allow vehicles instances to be tracked to avoid vehicle duplication. eg, esx_vehicle shop adds an owned_vehicle record but if you don't put the vehicle away first you can get the vehicle out and have a duplicate, at least with some garages. So you can Trigger these events passing the vehicle instance and plate to allow tracking. This could also be useful if using an external vehicle impound system where you want to mark a vehicle as disposed when impounded or to track it again once released from impound.

**Future Direction**

The design isn't perfect as this is only a first rough cut. I intend apply some more design patterns such as Factories and Strategy to provide more pluggable versions of the code to cater for the different frameworks I'd like this to support out of the box. As an example the spawning process currently only handles the ESX 'vehicle' column from owned_vehicles. If a framework provides a different definition then this system needs to customised by the server developers and I'll probably never see a pull request to back integrate...plus it's likely to be a bandaid hack, so I'd rather provide a clean and modular way to provide support for different Role Play frameworks out of the box as well as accomodate custom frameworks allowing the server developers to put their custom code into a dedicated source file without needing to modify the core system.

I plan to be actively maintaining this project and I'm open to suggestions and pull requests to merge back any fixes to issues that people with to contribute.

If you need any assistance feel free to reach out at https://discord.gg/Ngg75byBbB

**Sample Screenshots**

![image](https://user-images.githubusercontent.com/6404476/138875460-cdc771df-56cc-4ef2-bf1e-f810a01df2a4.png)

![image](https://user-images.githubusercontent.com/6404476/138875085-e65c395e-9083-4452-98d9-aee56dc9275e.png)

![image](https://user-images.githubusercontent.com/6404476/138875659-dcb9efa5-065e-463f-aeb8-5d1e1b2db2c9.png)

**Important note regarding MySQL**

The SQL I'm using is using some specific JSON fetch functions which aren't available in MySQL and therefore at this time you must be running MariaDB. I've tested with 10.7 so use that as a minimum. There'll be an update at some point once I work out how to implement a decent factory pattern to make the specific platform plugin code a little better.

**My quasi 'Strategy Pattern'**

I've used an implementation of a 'strategy' design pattern to cater for different implementation of functionality for specific functions that are done differently in typical role play frameworks people are using. If you're not using QBCore or ESX Legay then there's stub files there for you to implement the missing functionality. Just follow the pattern.

**Installation**
* Install ft_libs https://github.com/FivemTools/ft_libs if you don't already have it and add the ensure statement to your server.cfg
* Install VehicleDeformation https://github.com/Kiminaze/VehicleDeformation if you don't already have it and add the ensure statement to you server.cfg
* Install htb_garage and add the ensure statement after ft_libs in the server.cfg
* Run the SQL script according to whether you already have the owned_vehicles table. If you have a stock ESX Legacy setup from the fxserver recipe deployer then run alter owned_vehicles file.
* Rename the appropriate fxmanifest lua file based on the Role Play framework you're running.

**Note regarding ESX-Legacy**

There's been some changes to ESX and they now have a built in garage system that uses a column named *pound* that's a varchar which clashes with mine. I've adjusted the database column name to be pound_htb. If you've been running an old version my this resource please add that column to your database. You can take the update SQL and just comment out the other columns so you only add the pound_htb one.

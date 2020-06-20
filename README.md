# Things to work on

* **Get human gun working**
	* **Use correct GUI**
	* **Make arm appear**
* **Get reload station working**
	* **Support multiple stations**
	* **Make stations give client bullet**
* **Get werewolf working**
	* **Costume appear and disappearing**
	* **Claw swinging animation**
	* **Doing damage**
* **Day / Night Cycle**
	* **Plugging all the other systems into the cycle**
* **Round Starting and Ending**
	* **Plug components together and get round system working**

* Stamina Gui
* Spectate Function
* Round win gui


**Bold** - Done

# Conventions / Style Guide

To keep some sanity there's some basic coding guidelines I keep to. 

Whilst singletons are widely considered a broken design pattern, the Aero Game framework has decided to use them as Controllers and Services. To keep things coherent if the code doesn't suite well an "OOP" style then put it into a Controller/Service. 

Simple style rules:
* Private variables should begin with an _. 
* Private functions for a singleton should begin with a lowercase letter
* Any function used by an outsider should begin with an uppercase letter
* Variables that need to persist that would have to exist in the global scope, ie cannot be trivially passed between functions, should be defined on self
* You're can have one Logger instance in the global scope of each file
# AutoTouchPlus

@lookup README.md


![CI Build](https://img.shields.io/travis/sentrip/AutoTouchPlus.svg)
![Coverage](https://coveralls.io/repos/github/sentrip/AutoTouchPlus/badge.svg)
![GitHub release](https://img.shields.io/github/release/sentrip/AutoTouchPlus/all.svg)


A framework for creating better, faster and shorter AutoTouch scripts


## Introduction

AutoTouchPlus is a framework that was designed to make writing AutoTouch scripts as fast, easy and bug-free as possible, while still allowing for very complicated and dynamic scripts.

## Installation
To install AutoTouchPlus, there are 3 methods. 
For ease of installation and usage, AutoTouchPlus is a single compiled lua file that can be easily imported. 


### Install from device

1. Copy the raw text from [install.lua](https://raw.githubusercontent.com/sentrip/AutoTouchPlus/master/install.lua) and paste it into a new script in AutoTouch. 
2. Save and run the script, and you're done!


### Install from computer (with developer install script)

    PHONE_IP=<YOUR.PHONES.IP.ADDRESS>
    git clone https://github.com/sentrip/AutoTouchPlus.git
    cd AutoTouchPlus
    ./dev.py install -ip $PHONE_IP


### Install with manual file transfer

1. Download AutoTouchPlus.lua and tests.lua from the [latest release](https://github.com/sentrip/AutoTouchPlus/releases/latest).
2. Copy AutoTouchPlus.lua and tests.lua to /var/mobile/Library/AutoTouch/Scripts/



## Getting started

To use AutoTouchPlus in a script, just import it:

    require("AutoTouchPlus")


## Screen interaction


### Basic interaction


### Contexts


### Listeners


### Method chaining
You can chain screen methods together to combine multiple actions into a single chained call. So the following code

    screen.tap(10, 10)
    screen.tap(20, 20)
    screen.tap(30, 30)
    screen.tap(40, 40)

can be reduced to:

    screen.tap(10, 10).tap(20, 20).tap(30, 30).tap(40, 40)







## HTTP requests






## OS & filesystem






## Logging





## Testing


### Writing tests


### Fixtures


### Parametrization




## Developing AutoTouch scripts


### Development script


### Recommendations






## Developing AutoTouchPlus


### Guidelines


### Making a pull request


### Releasing a new version


<!-- ## Buy me a coffee☕
If you think AutoTouchPlus is awesome, feel free to drop a donation!
* PayPal
* Bitcoin
* Ethereum
* Litecoin -->
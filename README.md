Minimum Rubber
==============

Minimum Rubber is a collection of Core Graphics and Core Foundation related functions I've found useful. There are a few sources:

- my own design, eg `MRFontDataCreateWithNameAndPaths`
- code in other languages, eg `MRPathAddQuadToPointWithCurve`
- example answers, eg from Stack Overflow

#### Why does it exist? ####

The main impetus was the creation of custom TrueType fonts. I learned a bit about Core Graphics paths and Core Text writing [The Map](https://itunes.apple.com/gb/app/the-map-world-maps-offline/id349821547?mt=8) (an iOS app) and after seeing a note entitled “[Loading iOS fonts dynamically](http://www.marco.org/2012/12/21/ios-dynamic-font-loading)” by Marco Arment, knew I could connect the two.

In order to achieve this I ended up pulling in a bunch of my private code and code ported from various places around the web. Thus Minimum Rubber came to be.

#### The name ####

I'm not very good at naming things so I now use the [Project Name Generator](http://online-generator.com/name-generator/project-name-generator.php) until I get a name I like. I think this one appealed as I was playing with `CGAffineTranform` which reminded me of “[Rubber sheet geometry](http://en.wikipedia.org/wiki/Topology)”. Make of that what you will.
# Diary Of A Canon
## The learning process...

This document aims to show the progress that I have made so far and the course of development. What was learned at each stage? Why have I made certain design choices? etc.

#### Date: 18th December 2015

Today I have come up against the bane that is program complexity. I *think* I have a working canon generator, but unfortunately, it's not going to terminate any time soon... The durations get resolved pretty quickly (quickly enough anyway) but the pitches do not. I think so far it's been running a good half hour, and this is only a simple example.

Is suspect that the problem is that I am doing a generate and test type paradigm, but what I really need is something a little quicker- the solution space is vast!

##### Current solution:

Broadly this involves setting the options of what each note can be, then adding constraints that they are next to each other, then finally adding the canon constraints on each bar. This turns out to be infeasible (!).

##### Proposed solution:

Randomly set more things at the start. The structure will generate the timings first and then have them set before going into setting the pitches.

Find a better way to check which notes overlap. There are a few ways to do this:

1. We know that if one note comes after the other, none that follow it can overlap either.
2. On the next go round the loop, ones that were before the first one that overlapped with the last note cannot overlap with this one either.

I should also try the method of choosing a few notes at a time to constrain to set intervals from each other. This might make constraints more explicit and therefore faster. It also gets rid of the problem of having all the notes the same, as well as making this easier to specify.

Advantages:
* Hopefully it will be able to run is reasonable time! (Yay!)

Disadvanatges:
* Lose some options in flexibility- we assume we only want one solution back from the function and not multiple ones. I think however, this is a reasonable design choice in this case.

##### Revised plan:

Add constraints to each bar in sequence so that backtracking is not looking at the whole thing at once. i.e.

1. Generate one bar of music
2. Generate the next, based on the previous one
3. Repeat

This could be done durations first, then pitches afterwards, or all at the same time. The former would imply there is no relation between the durations and the pitches, the latter might mean I am able to do more compex things.

##### Change of direction

That approach was bearing no fruit so now I am trying a new one. This is using more music theory to do- from chords rather than anything else.

#### December 24th 2015

The new method of using music theory is working nicely. I've just finished a very rough version, I think from here on in, it's mainly cleaning things up and adding bits which make the canon sound nicer.

##### Currently the software:

* Generates and plays simple canons in 3/4 and 4/4.

##### Things to do to improve:

* Make sure that different bars do not have the same root note in the same place- this sounds bad...
* Make the transforms nicer
* Allow user inputs and transform so that it can work in the chained way (ask Sam)
* Extend to compound time
* Get different octaves to work
* Get Sonic Pi to make the notes the right length

##### Tasks that would be good to start soon:

* Get it exporting to Lilypond and/or notation XML so that I can play it outside of Sonic Pi

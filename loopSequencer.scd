(var launchpadOut, launchpad, banks, record_BUTTON, tapTempoSet_BUTTON, tapTempoToggle_BUTTON, color1, cycleLight_BUTTON, padColorState, ccLights, setLight, cycleLight, isPlaying;

cycleLight_BUTTON = 95;
padColorState = Dictionary.new;
~padColors = padColorState;
ccLights = List.new;
(1..8).do({|i|
    ccLights.add(i);
    ccLights.add(90+i);
    ccLights.add(i*10);
    ccLights.add((i*10)+9);
});

setLight = {|note, color, lightIndexOverride=false|
    if((~lightIndex == lightIndex) || lightIndexOverride, {
        if(ccLights.includes(note),
            {launchpadOut.control(0, note, color)},
            {launchpadOut.noteOn(0, note, color)}
        );
    });
    padColorState[note] = color;
};
(1..98).do({|note|
    if(ccLights.includes(note),
        {launchpadOut.control(0, note, 0)},
        {launchpadOut.noteOn(0, note, 0)}
    );
    padColorState[note] = 0;
});
cycleLight = {
    //TODO: change name of this port to something like SCOSCport
    Task({
        masterClockOSCport.sendMsg("/lightsChange", (~lightIndex+1)%~lightIndexes.size);
        0.01.wait;
        ~lightIndex = (~lightIndex+1)%~lightIndexes.size;
    }).play;
};

//msg[1] is lightIndex
OSCFunc({|msg, time, addr, recvPort|
    if(msg[1].asInt == lightIndex, {
        var colorStateLog = List.new(100);
        (0..99).do({|i| colorStateLog.add(0)});
        padColorState.keys.do({|key| setLight.(key, padColorState[key], true);
            colorStateLog[key]=padColorState[key]});
        ["CHANGING MULTILOOP LIGHTS", msg[1], colorStateLog].postln;
    });

}, "/lightsChange");
lightIndex = if(~lightIndexes.size == 0,
    {
        ~lightIndexes.add(0);
        0
    },
    {
        ~lightIndexes.add(~lightIndexes.maxItem+1);
        ~lightIndexes.maxItem
    }
);
~lightIndex = lightIndex;
["LIGHT INDEX LOOP SEQUENCER", ~lightIndex, lightIndex].postln;

launchpadOut = MIDIOut.new(11);
launchPad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
    && (elem.device == "Launchpad Pro")})[1];
banks = (10,20..80);
isPlaying = List.fill(8, {false});

tapTempoSet_BUTTON = 5;
tapTempoToggle_BUTTON = 6;
record_BUTTON = 7;
scPort = NetAddr("127.0.0.1", 57120);

color1 = [39, 112, 4, 83]; //colorVal


MIDIFunc.cc({|vel, note, chan, port|
    if(banks.includes(note), { scPort.sendMsg("/padHit", (note/10)-1) });
    if(note == record_BUTTON, { scPort.sendMsg("/recordButton", 1) });
}, nil, nil, launchpad.uid);

//msg[1] is bankIndex, msg[4] is bankChan
OSCFunc({|msg, time, addr, recvPort|
    var loopInd = msg[1].asInt;
    var chanInd = msg[4].asInt;
    isPlaying[loopInd] = true;
    setLight((loopInd+1)*10, color1[chanInd]);
    (1..8).do({|i| setLight(((loopInd+1)*10)+i, color1[chanInd])});

} "/saveLoop")

)

//when you record a loop, it will default be looping over all steps (makes things simpler technically)
//when you turn off a loop,

//TODO
/*
- The only thing this module will do is control the sequencing of loops.
- All recording and saving of loops will happen on the secenBuilder pad (into the first column) .
- When you record a loop, THE USER IS RESPONSIBLE for making sure it lines up with the beat count (every 4 or whatever).
- When a loop is saved in sceneBuilder, its color will light up in the corresponding colummn in loopSequencer.
- When a loop column is reached, it will turn off the loop, all notes on the channel, and then turn on the loop (1 ms lag between off/on).
----- Thus, if your initial recording is off the beat count, there will be a "skip", but it won't break.
- algoKeys and sceneBuilder will be on the same launchpad, loopSequencer on another.

*/


MIDIClient.init;

a = MIDIOut.newByName("Launchpad Pro", "Standalone Port")

d = MIDIClient.destinations
d.do({|dest| dest.postln})

a = MIDIClient.destinations[8]
b = MIDIClient.destinations[11]

a = MIDIOut.new(8)
b = MIDIOut.new(11)

a.noteOn(0, 55, 55)
b.noteOn(0, 55, 66)
MIDIClient.destinations[8]

(10,20..80).includes(60)
(var launchpadOut, launchpad, banks, record_BUTTON, tapTempoSet_BUTTON, tapTempoToggle_BUTTON, color1, cycleLight_BUTTON, padColorState, ccLights, setLight, cycleLight, isPlaying, grid, tempoClock, columnInd, chanPerLoop, beatsPerLoop, beatNum, pythonOSCport, playColumn, masterClockOSCport, chanPerInd, lightIndex, colors1, launchpadIndex;

launchpadIndex = [8, 0]; //8,0 if "first launchpad", 11,1 if 2nd
launchpadOut = MIDIOut.new(launchpadIndex[0]);
launchpadOut.latency = 0;

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



(1..99).do({|i| setLight.(i, 0)});

launchpad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
    && (elem.device == "Launchpad Pro")})[launchpadIndex[1]];
["LAUNCHPAD", launchpad, ].postln;
pythonOSCport = NetAddr("localhost", 13371);
masterClockOSCport = NetAddr("127.0.0.1", 57120);



color1 = [39, 112, 4, 83]; //colorVal
grid = Array.fill2D(8, 8, {false});
columnInd = 0;
chanPerLoop = List.fill(8, {nil});
beatsPerLoop = 4;
beatNum = 0;



MIDIFunc.noteOn({|vel, note, chan, port|
    var row = (8-(note/10).floor);
    var col = (note%10) - 1;
    grid[row][col] = grid[row][col].not;
    setLight.(note, colors1[chanPerInd[row]]);

    pythonOSCport.sendMsg("/sendLoopGrid", grid.flat.collect({|el| if(el, 1, 0)}).join(","));
}, nil, nil, launchpad.uid);



MIDIFunc.cc({|vel, note, chan, port|
    if(note > 90, {
        columnInd = note-91;
        setLight.(note, 55);
    });
}, nil, nil, launchpad.uid);



//msg[1] is bankIndex, msg[4] is bankChan
OSCFunc({|msg, time, addr, recvPort|
    var loopInd = msg[1].asInt;
    var chanInd = msg[4].asInt;

    setLight.((loopInd+1)*10, color1[chanInd]);
    chanPerInd[loopInd] = chanInd;

    (0..7).do({|i| grid[loopInd][i] = true});
    (1..8).do({|i| setLight.(((loopInd+1)*10)+i, color1[chanInd])});

}, "/saveLoop");



playColumn = {

    Task({
        (0..7).do({|i| masterClockOSCport.sendMsg("/toggleBank", i, "off")});

        0.001.wait;

        (0..3).do({|i| masterClockOSCport.sendMsg("/turnOffChannel", i)});

        0.001.wait;

        (0..7).do({|i|
            if(grid[i][columnInd],
                {masterClockOSCport.sendMsg("/toggleBank", i, "on")});
        });
        //
    }).play;

};



//msg[1] is a string of 0/1s in row-major order, separated by commas
OSCFunc({|msg, time, addr, recvPort|
    var vals = msg[1].asString.split($,);
    vals.do({|v, i| grid[(i/8).floor*10][i%8] = v.asSymbol == \1});
}, "/setGrid");



//msg[1] is a string of 1/0s separated by commas, msg[2] is column ind
OSCFunc({|msg, time, addr, recvPort|
    var vals = msg[1].asString.split($,);
    vals.do({|v, i| grid[i][msg[2].asInt] = v.asSymbol == \1});
}, "/setColumn");



OSCFunc({|msg, time, addr, recvPort|
    if((beatNum % beatsPerLoop) == 0, {
        playColumn.();
        pythonOSCport.sendMsg("/columnStep", columnInd);
        (0..8).do({|i| setLight.(91+i, 0)});
        setLight.(91+columnInd, 3);
        columnInd = columnInd+1;
    });
    beatNum = beatNum + 1;
    //"LOOP SEQUENCER hit".postln;
}, "/masterClockBeat");


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


note - top row is row "0" and indexes in increasing order down

*/

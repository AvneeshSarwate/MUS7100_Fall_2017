(var launchpadOut, launchpad, banks, record_BUTTON, tapTempoSet_BUTTON, tapTempoToggle_BUTTON, color1, cycleLight_BUTTON, padColorState, ccLights, setLight, cycleLight, isPlaying, grid, tempoClock, columnInd, chanPerLoop, beatsPerLoop, beatNum, pythonOSCport, playColumn, masterClockOSCport, chanPerRow, lightIndex, launchpadIndex, controlHandler, controlHandlerWrapper, useLoopMidi;

useLoopMidi = false;

launchpadIndex = [8, 0, 3]; //8,0 if "first launchpad", 11,1 if 2nd

if(useLoopMidi,
{
	launchpadOut = MIDIOut.new();},
{
	launchpadOut = MIDIOut.new(8);
	/*launchpad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
	&& (elem.device == "Launchpad Pro")})[0];*/
});

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
        ["NEW LIGHT INDEX TRIGGER FROM LOOPSEQUENCER", ~lightIndex].postln;
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
        ["CHANGING TO LOOPSEQUENCER LIGHTS", msg[1], colorStateLog].postln;
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

if(useLoopMidi,
{
		["SETTING LAUNCHPAD"].postln;
	launchpad = MIDIClient.sources.select({|elem| (elem.name == "MIDIIN2 (2- Launchpad Pro)")
	&& (elem.device == "MIDIIN2 (2- Launchpad Pro)")})[0];},
{
	launchpad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
	&& (elem.device == "Launchpad Pro")})[0];
});

["LAUNCHPAD", launchpad ].postln;
pythonOSCport = NetAddr("localhost", 7100);
masterClockOSCport = NetAddr("127.0.0.1", 57120);


//TODO: move variable instations to near the functions that use them
OSCFunc({|msg, time, addr, recvPort|
    //msg[1] is the new BEAT DURATION (not tempo)
    tempoClock = TempoClock.new(1/msg[1], 0, queueSize:2056);
    ~sceneBuilderClock = tempoClock;
    "SCENE BUILDER ONE SHOT".postln;
}, "/masterClockBeat").oneShot;

//msg[1] is the new BEAT DURATION (not tempo)
//msg[2] is whether the beat is being realigned

OSCFunc({|msg, time, addr, recvPort|
    tempoClock.tempo = 1/msg[1].asFloat;
    if(msg[2].asBoolean, {tempoClock.beats = tempoClock.beats.floor + 1});
}, "/masterClockTempo");



color1 = [39, 112, 4, 83]; //colorVal
grid = Array.fill2D(8, 8, {false});
columnInd = 0;
chanPerLoop = List.fill(8, {nil});
beatsPerLoop = 4;
beatNum = 0;
chanPerRow = List.fill(8, {-1});



MIDIFunc.noteOn({|vel, note, chan, port|
    if((chan == 0) && (~lightIndex == lightIndex), {
        var row = (8-(note/10).floor);
        var col = (note%10) - 1;
        ["STEP SEQ PRESS", row, col, chanPerRow[row], color1[chanPerRow[row]]].postln;
        grid[row][col] = grid[row][col].not;
        setLight.(note, if(grid[row][col], color1[chanPerRow[row]], 0));

        if(grid[row].any({|v| v}).not,
            {tempoClock.sched(((4-beatNum%4)-1)%4 + tempoClock.timeToNextBeat,
                {masterClockOSCport.sendMsg("/toggleBank", row, "off")})});

        pythonOSCport.sendMsg("/sendLoopGrid", grid.flat.collect({|el| if(el, 1, 0)}).join(","));
    })
}, nil, nil, launchpad.uid);



controlHandler = {|vel, note, chan, port|
    if(note < 10, {
        columnInd = note-1;
        setLight.(note, 55);
    });
    if((note == cycleLight_BUTTON) && (vel !=0), {
        if(~cycling, {cycleLight.()})
    });
};

controlHandlerWrapper = {|vel, note, chan, port|
    ~lock.wait;
    if((chan == 0) && (~lightIndex == lightIndex) && (vel != 0), {
        //["LIGHT INDEX MULTILOOP", ~lightIndex, lightIndex, SystemClock.beats].postln;
        controlHandler.(vel, note, chan, port)
    });
    ~lock.signal;
};
MIDIFunc.cc(controlHandlerWrapper, nil, nil, launchpad.uid);

//msg[1] is bankIndex (eg buttonNote in sceneBuilder), msg[4] is bankChan
OSCFunc({|msg, time, addr, recvPort|
    if(msg[1].asInt > 40, { //top row in scene builder has bank indexes 41-48
        var loopInd = ((msg[1].asInt)%10) - 1;
        var chanInd = if(msg[4].isNil, -1, msg[4].asInt);

        ["/saveLoop loop seq", loopInd, chanInd].postln;

        setLight.((8-loopInd)*10, if(chanInd < 0, 0, color1[chanInd]));
        chanPerRow[loopInd] = chanInd;

        /*(0..7).do({|i| grid[loopInd][i] = true});
        (1..8).do({|i| setLight.(((8-loopInd)*10)+i, color1[chanInd])});*/
    });

}, "/saveLoop");


playColumn = {|colInd|

    Task({
        (0..7).do({|i|
            if(grid[i][(colInd-1)%8],
                {
                    masterClockOSCport.sendMsg("/toggleBank", i, "off");
            });
        });

        0.0005.wait;

        (0..7).do({|i|
            if(grid[i][colInd],
                {
                    masterClockOSCport.sendMsg("/toggleBank", i, "on");
            });
        });
        //
    }).play;

};


//msg[1] is a string of 0/1s in row-major order, separated by commas
OSCFunc({|msg, time, addr, recvPort|
	var vals;
    vals = msg[1].asString.split($,);
	vals.do({|v, i|
		var col, row;
		col = ((i/8)%8).floor;
		row = i%8;
		grid[((i/8)%8).floor][i%8] = v.asSymbol == \1;
		if(v.asSymbol == \1,
			{setLight.((8-(i/8).floor)*10 + ((row)+1), color1[chanPerRow[col]])},
			{setLight.((8-(i/8).floor)*10 + ((row)+1), 0)});
	});
	"Grid changed!".postln;
}, "/setGrid");


//msg[1] is a string of 1/0s separated by commas, msg[2] is column ind
OSCFunc({|msg, time, addr, recvPort|
    var vals = msg[1].asString.split($,);
    vals.do({|v, i| grid[i][msg[2].asInt] = v.asSymbol == \1});
}, "/setColumn");



OSCFunc({|msg, time, addr, recvPort|
    if((beatNum % beatsPerLoop) == 0, {
        playColumn.(columnInd);
        pythonOSCport.sendMsg("/columnStep", columnInd);
        (0..8).do({|i| setLight.(1+i, 0)});
        setLight.(1+columnInd, 3);
        columnInd = (columnInd+1) % 8;
    });
    beatNum = beatNum + 1;
    //"LOOP SEQUENCER hit".postln;
}, "/masterClockBeat");

OSCFunc({|msg, time, addr, recvPort|
    beatsPerLoop = msg[1].asInt;
}, "/loopLength");

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

(
var grid = Array.fill2D(8, 8, {false});
grid[0]

)

~lightIndex
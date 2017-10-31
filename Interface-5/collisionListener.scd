(var ballToDeviation, gateToNote, ballToChan, noteMidiOut, tempoClock, masterClockTempoHandler;

noteMidiOut = MIDIOut.newByName("IAC Driver", "Bus 2");

gateToNote = [60, 64, 67, 79];
ballToDeviation = [-3, 5, -4, 9];
ballToChan = [0,0,0,0,1,1,1,1];

OSCFunc({|msg, time, addr, recvPort|
    //msg[1] is the new BEAT DURATION (not tempo)
    tempoClock = TempoClock.new(1/msg[1], 0);
}, "/masterClockBeat").oneShot;


//msg[1] is the new BEAT DURATION (not tempo)
//msg[2] is whether the beat is being realigned
masterClockTempoHandler = {|msg, time, addr, recvPort|
    tempoClock.tempo = 1/msg[1].asFloat;
    if(msg[2].asBoolean, {tempoClock.beats = tempoClock.beats.floor + 1});
};
OSCFunc(masterClockTempoHandler, "/masterClockTempo");

~quantizeBallBeats = true;
~ballQuantizeValue = 0.25;

//msg - [addr, ballInd, gateInd]
OSCFunc({|msg, time, addr, rectPort|
    var ball = msg[1].asInt;
    var gate = msg[2].asInt;
    var timeToNextHit = ~ballQuantizeValue - (tempoClock.beats % ~ballQuantizeValue);
    if(ball < ballToDeviation.size, {
        var noteFunc = {noteMidiOut.noteOn(ballToChan[ball], ballToDeviation[ball]+gateToNote[gate], 70)};
        if(~quantizeBallBeats,
            {tempoClock.sched(timeToNextHit,noteFunc)},
            {noteFunc.()}
        );
        [ball, gate, ballToChan[ball], ballToDeviation[ball]+gateToNote[gate]].postln;
    });
}, "/gateCross");


OSCFunc({|msg, time, addr, rectPort|
    var ball = msg[1].asInt;
    var gate = msg[2].asInt;
    if(ball < ballToDeviation.size, {
        noteMidiOut.noteOn(ballToChan[ball], ballToDeviation[ball]+gateToNote[gate], 70);

    });
}, "/changeBallNotes");
)


OSCFunc.trace
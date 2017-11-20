(var ballToDeviation, gateToNote, ballToChan, noteMidiOut, tempoClock, masterClockTempoHandler, pythonOSCport, ballDecay;

noteMidiOut = MIDIOut.newByName("IAC Driver", "Bus 3");
pythonOSCport = NetAddr("127.0.0.1", 7100);

gateToNote = [60, 64, 67, 79, 60, 60, 60, 60, 60];
ballToDeviation = [-3, 5, -4, 9];
ballToChan = [0,0,0,0,1,1,1,1];
ballDecay = [1, 1, 1, 1, 1, 1, 1, 1];

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
        var noteFunc = {
            var chan = ballToChan[ball];
            var note = ballToDeviation[ball]+gateToNote[gate];
            noteMidiOut.noteOn(chan, note, 70);
            tempoClock.sched(ballDecay[ball], {noteMidiOut.noteOff(chan, note, 70)});
        };
        if(~quantizeBallBeats,
            {tempoClock.sched(timeToNextHit,noteFunc)},
            {noteFunc.()}
        );
        [ball, gate, ballToChan[ball], ballToDeviation[ball]+gateToNote[gate]].postln;
    });
}, "/gateCross");


OSCFunc({|msg, time, addr, rectPort|
    var newDev = msg[1..];
    newDev.postln;
    msg[1..].do({|elem, ind| ballToDeviation[ind] = newDev[ind]});
    ["ballDeviations Changed", newDev, ballToDeviation].postln;
}, "/changeBallDeviation");

OSCFunc({|msg, time, addr, rectPort|
    var newChan = msg[1..];
    newChan.postln;
    msg[1..].do({|elem, ind| ballToChan[ind] = newChan[ind]});
    ["ballchan Changed", newChan, ballToChan].postln;
}, "/changeBallChan");

OSCFunc({|msg, time, addr, rectPort|
    var newNotes =  msg[1..];
    newNotes.do({|elem, ind| gateToNote[ind] = newNotes[ind]});
    ["gateNotes Changed", newNotes, gateToNote].postln;
}, "/changeGateNotes");

OSCFunc({|msg, time, addr, rectPort|
    msg.postln;
    tempoClock.sched(msg[1], {pythonOSCport.sendMsg(msg[2].asString, 1)});
}, "/triggerDelayFunc");


//msg - [addr, ballInd, dist]
OSCFunc({|msg, time, addr, recvPort|
    noteMidiOut.control(0, msg[1].asInt, (msg[2]*127).floor);
    msg.postln;
}, "/effectBall");


)




OSCFunc.trace

[1,2,3].do({|elem, ind| [elem, ind].postln})
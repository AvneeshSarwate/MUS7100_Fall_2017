(

var lastNoteOn, triplePlay, midiOut, pedal, quneo, jsPort, brushSpeed, brushAngle, maxBrushSpeed;

triplePlay = ~getMidiIn.("Fishman TriplePlay", "TP Guitar");
pedal = ~getMidiIn.("FBV Express Mk II", "Port 1");
quneo = ~getMidiIn.("QUNEO", "QUNEO");
midiOut = ~getMidiOut.("IAC Driver", "Bus 2");
jsPort = NetAddr("localhost", 5432);

lastNoteOn = [0, 0, 0, 0, 0, 0, 0, 0];
midiOut.latency = 0;

brushSpeed = 0;
brushAngle = 0;
maxBrushSpeed = 10;


~hz = 60;

~noteQueue = List.fill(1, {0});

//attack-decay envelope
~speedEnv = {|attackRatio, time, peak|
    var numSteps = time * ~hz;
    var aRamp = List.fill((attackRatio*numSteps).floor, {peak})/(attackRatio*numSteps).floor;
    var dRamp = List.fill(((1-attackRatio)*numSteps).ceil, {-1*peak})/((1-attackRatio)*numSteps).ceil;
    var pat = Pbind(
        \delta, 1/~hz,
        \increment, Pseq(aRamp++dRamp),
        \play, {brushSpeed = brushSpeed + ~increment}
    );
    pat.play;
    pat
};

~sendSpeedPat = Pbind(
    \delta, Pseq([1/60], inf),
    \play, {jsPort.sendMsg("/brushSpeed", min(max(brushSpeed, -1*maxBrushSpeed), maxBrushSpeed))}
);
~sendSpeedPat.play;

~sendAnglePat = Pbind(
    \delta, Pseq([1/60], inf),
    \play, {jsPort.sendMsg("/brushAngle", brushAngle)}
);
~sendAnglePat.play;

~angleEnv = {|time, maxAngle, maxInterval|
    var interval = ~noteQueue.wrapAt(-1) - ~noteQueue.wrapAt(-2);
    var clippedInterval = min(maxInterval, abs(interval)) * sign(interval);
    var angle = (clippedInterval/maxInterval) * maxAngle;
    var pat = Pbind(
        \delta, 1/~hz,
        \increment, Pseq(List.fill((time*~hz).floor, {angle})/(time*~hz).floor),
        \play, {brushAngle = brushAngle + ~increment; brushAngle.postln}
    );
    pat.play;
    pat
};


MIDIFunc.noteOn({|vel, note, chan, port|
    if(chan < 4, {
        var noteTime = 0.5;
        ~noteQueue.add(note);
        ~speedEnv.(0.1, noteTime, 10);
        ~angleEnv.(0.5/5, pi/2, 5);
        [vel, note, chan, port].postln;

    }, {
        Task({
            ["GUITAR OFF", lastNoteOn[chan], chan].postln;
            midiOut.allNotesOff(chan);
            0.01.wait;
            midiOut.noteOn(chan, note, vel);
            lastNoteOn[chan] = note;
            ["GUITAR ON", note, chan].postln;
        }).play;
    })
}, nil, nil, triplePlay.uid);

MIDIFunc.noteOn({|vel, note, chan, port|
    if([44, 45, 48, 49, 36, 37, 40, 41].includes(note), {

        Task({
            midiOut.noteOn(7, note, vel);
            0.1.wait;
            midiOut.noteOn(7, note, 0);
            ["QUNEO NOTE", note, chan, 5].postln;
        }).play;
    })
}, nil, nil, quneo.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if((note == 16), {
        midiOut.noteOn(0, 1, vel);
        ["loop",1, vel].postln;
    });
    if((note == 17), {
        midiOut.noteOn(0, 2, vel);
        ["loop",2, vel].postln;
    });
    if((note == 18) && (vel == 127), {
        midiOut.allNotesOff(5);
        ["Notes off", 5].postln;
    });
    if((note == 19) && (vel == 127), {
        midiOut.allNotesOff(4);
        ["Notes off", 4].postln;
    });
    if((note == 7), {
        midiOut.control(0, note, vel);
    });

}, nil, nil, pedal.uid);

)
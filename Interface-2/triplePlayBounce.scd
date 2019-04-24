(
var triplePlay, midiOut, pedal, quneo, jsPort, brushSpeeds, brushAngles, maxBrushSpeed, controlChannel, numLoopsPlaying, numLoopsSaved, looperState, undoState, recordingCount, loopCountUndoStack, loopCountRedoStack, noteTap, lastLooperState;

triplePlay = ~getMidiIn.("Fishman TriplePlay", "TP Guitar");
pedal = ~getMidiIn.("FBV Express Mk II", "Port 1");
midiOut = ~getMidiOut.("IAC Driver", "Bus 2");
jsPort = NetAddr("localhost", 5432);

midiOut.latency = 0;
controlChannel = 7;

//TODO: for 4 notes
brushSpeeds = [0, 0, 0, 0];
brushAngles = [0, 0, 0, 0];

maxBrushSpeed = 5;


~hz = 60;

~noteQueue = List.fill(4, {List.fill(1, {0})}); //TODO: for 4 notes

//attack-decay envelope
//TODO: for 4 notes - add index
~speedEnv = {|attackRatio, time, peak, brushInd|
    var numSteps = time * ~hz;
    var aRamp = List.fill((attackRatio*numSteps).floor, {peak})/(attackRatio*numSteps).floor;
    var dRamp = List.fill(((1-attackRatio)*numSteps).ceil, {-1*peak})/((1-attackRatio)*numSteps).ceil;
    var pat = Pbind(
        \delta, 1/~hz,
        \increment, Pseq(aRamp++dRamp),
        \play, {brushSpeeds[brushInd] = brushSpeeds[brushInd] + ~increment} //TODO: for 4 notes - add index
    );
    pat.play;
    pat
};

//TODO: for 4 notes - map speed array through bounding function
~sendSpeedPat = Pbind(
    \delta, Pseq([1/60], inf),
    \play, {jsPort.sendRaw((["/brushSpeeds"]++ brushSpeeds.collect({|speed| min(max(speed, -1*maxBrushSpeed), maxBrushSpeed)})).asArray.asRawOSC)}
);
~sendSpeedPat.play;

//TODO: for 4 notes
~sendAnglePat = Pbind(
    \delta, Pseq([1/60], inf),
    \play, {jsPort.sendRaw( (["/brushAngles"]++brushAngles.flat).asArray.asRawOSC);}
);
~sendAnglePat.play;

//TODO: for 4 notes - add index
~angleEnv = {|time, maxAngle, maxInterval, brushInd|
    var interval = ~noteQueue[brushInd].wrapAt(-1) - ~noteQueue[brushInd].wrapAt(-2);
    var clippedInterval = min(maxInterval, abs(interval)) * sign(interval);
    var angle = (clippedInterval/maxInterval) * maxAngle;
    if(interval == 0, {
        brushAngles[brushInd] = brushAngles[brushInd] + pi;
    },{
        var pat = Pbind(
            \delta, 1/~hz,
            \increment, Pseq(List.fill((time*~hz).floor, {angle/(time*~hz).floor})),
            \play, {brushAngles[brushInd] = brushAngles[brushInd] + ~increment; [brushInd, ~increment, brushAngles].postln; } //TODO: for 4 notes - add index
        );
        // ["THE INCREMENT", List.fill((time*~hz).floor, {angle/(time*~hz).floor}), "angle", angle, "time", time, "numSteps", (time*~hz).floor].postln;
        pat.play;
        pat
    });
};

//TODO - and envelope for fadeout on noteoff


MIDIFunc.noteOn({|vel, note, chan, port|
    if(chan < 4, {
        var noteTime = 0.5;
        var brushInd = chan;
        //TODO: for 4 notes - add index by chan
        ~noteQueue[brushInd].add(note);
        ~speedEnv.(0.1, noteTime, maxBrushSpeed, brushInd);
        ~angleEnv.(0.5/5, pi/2, 5, brushInd);
        [vel, note, chan, port].postln;
        //Todo - send noteOn event and velocity

    }, {
        Task({
            ["GUITAR OFF", chan].postln;
            midiOut.allNotesOff(chan);
            0.01.wait;
            midiOut.noteOn(chan, note, vel);
            ["GUITAR ON", note, chan].postln;
            jsPort.sendMsg("/droneNotes", chan-4, note);
        }).play;
    })
}, nil, nil, triplePlay.uid);


/*MIDIFunc.noteOff({|vel, note, chan, port|
    if(chan < 4, {
        var noteTime = 0.5;
        var brushInd = chan;
        //TODO: for 4 notes - add index by chan
        ~noteQueue[brushInd].add(note);
        ~speedEnv.(0.1, noteTime, 10, brushInd);
        ~angleEnv.(0.5/5, pi/2, 5, brushInd);
        [vel, note, chan, port].postln;
        //Todo - send noteOn event and velocity

    }, {
        Task({
            ["GUITAR OFF", chan].postln;
            midiOut.allNotesOff(chan);
            0.01.wait;
            midiOut.noteOn(chan, note, vel);
            ["GUITAR ON", note, chan].postln;
        }).play;
    })
}, nil, nil, triplePlay.uid);*/


/*MIDIFunc.noteOn({|vel, note, chan, port|
    if([44, 45, 48, 49, 36, 37, 40, 41].includes(note), {
        ["QUNEOP PAD", note].postln;
        Task({
            midiOut.noteOn(controlChannel, note, vel);
            0.1.wait;
            midiOut.noteOff(controlChannel, note, 0);
            ["QUNEO NOTE", note, chan, 5].postln;
        }).play;
    })
}, nil, nil, quneo.uid);*/


numLoopsPlaying = 0;
numLoopsSaved = 0;
looperState = 'newStart'; //vs playing, recording, cleared, 'newStart'
undoState = 'nothing'; //vs undoable or redoable - only 'nothing' at start, after first record, or after undoing a clear
recordingCount = 0;
loopCountUndoStack = List.new;
loopCountRedoStack = List.new;
noteTap = {|chan, note, time|
    Task({
        midiOut.noteOn(chan, note, 127);
        time.wait;
        midiOut.noteOff(chan, note, 0);
    }).play
};
~nnn = noteTap;
MIDIFunc.cc({|vel, note, chan, port|
    /*if((note == 16), {
        midiOut.noteOn(controlChannel, 1, vel);
        ["loop",1, vel].postln;
    });
    if((note == 17), {
        midiOut.noteOn(controlChannel, 2, vel);
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
    });*/

    //TODO - can clear, and then record a loop, but undo brings back cleared loop
    if(vel > 0, {
        lastLooperState = looperState;
        if((note == 16), { //Bot Left
            if(recordingCount > 0, {
                if(looperState == 'stopped', {
                    looperState = 'cleared';
                    loopCountUndoStack.add(numLoopsSaved);
                    numLoopsSaved = 0;
                    // numLoopsPlaying = 0; - should already be the case due to it having to be stopped first
                    //send clear out
                    noteTap.(controlChannel, 1, 0.01);
                });
                if(['recording', 'playing'].includes(looperState), {
                    looperState = 'stopped';
                    numLoopsPlaying = 0;
                    //send stop out
                    noteTap.(controlChannel, 2, 0.01);
                });
            });
            //if recordingCount > 0
            //if !stopped: state = stop, loopsPlaying = 0
            //if stopped: loopCountUndoStack.push, loopsSaved = 0; loopstate = cleared
        });
        if((note == 17), { //Bot Right
            //play button - overdubs when playing, plays when stopped
            //if playing or newStart or cleared: loopCountUndoStack.push, numLoopsSaved++, loopState = recording, recordingCount++,  ifRecordingCount>1: loopState=undoable,
            //if stopped or recording: numLoopsPlaying = numLoopsSaved

            noteTap.(controlChannel, 3, 0.01);

            if(['playing', 'newStart', 'cleared'].includes(looperState), {
                if(lastLooperState != 'cleared', {loopCountUndoStack.add(numLoopsSaved)});
                numLoopsSaved = numLoopsPlaying+1;
                looperState = 'recording';
                recordingCount = recordingCount+1;
                if(recordingCount > 1, {undoState = 'undoable'});
            }, {
                looperState = 'playing';
            });
            // numLoopsPlaying = numLoopsSaved
            numLoopsPlaying = numLoopsSaved
        });
        if((note == 18), { //Top Left

            //undo/redo -
            //if undoable - loopCountRedoStack.push(loopCount), loopCount = loopCountUndoStack.pop, if state!=cleared : undoState = redoable else nothing
            //reverse of ^

            var newUndoState = undoState; //need this bullshit because there's no breaking case statement operators
            noteTap.(controlChannel, 4, 0.01);

            if(undoState == 'undoable', {
                loopCountRedoStack.add(numLoopsSaved);
                numLoopsSaved = loopCountUndoStack.pop;
                if(looperState == 'cleared', {newUndoState = 'nothing'; looperState = 'stopped'}, {newUndoState = 'redoable'});
            });
            if(undoState == 'redoable', {
                loopCountUndoStack.add(numLoopsSaved);
                numLoopsSaved = loopCountRedoStack.pop;
                newUndoState = 'undoable';
            });
            if(looperState == 'playing', {numLoopsPlaying = numLoopsSaved});
            undoState = newUndoState;
        });
        [looperState, undoState, numLoopsSaved, numLoopsPlaying, recordingCount].postln;
        if((note == 19), { //Top Right
            midiOut.allNotesOff(4);
            midiOut.allNotesOff(5);
            jsPort.sendMsg("/droneNotes", 0, -1);
            jsPort.sendMsg("/droneNotes", 1, -1);
            ["Notes off", 4, 5].postln;
            //turn off notes for all drones
        });
        jsPort.sendMsg("/numLoopsPlaying", numLoopsPlaying);
    });
    if((note == 7), {

    });

}, nil, nil, pedal.uid);

)
// ~nnn.(7, 4, 0.01)
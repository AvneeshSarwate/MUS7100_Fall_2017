(

var lastNoteOn, triplePlay, midiOut, pedal;

triplePlay = ~getMidiIn.("Fishman TriplePlay", "TP Guitar");
pedal = ~getMidiIn.("FBV Express Mk II", "Port 1");
midiOut = ~getMidiOut.("IAC Driver", "Bus 2");
lastNoteOn = [0, 0, 0, 0, 0, 0, 0, 0];
midiOut.latency = 0;

MIDIFunc.noteOn({|vel, note, chan, port|
    Task({
        midiOut.noteOff(chan, lastNoteOn[chan]);
        0.01.wait;
        midiOut.noteOn(chan, note, vel);
        ["GUITAR FWD", note, chan].postln;
    }).play;
    lastNoteOn[chan] = note;
}, nil, nil, triplePlay.uid);

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
        midiOut.allNotesOff(4);
        ["Notes off", 5].postln;
    });
    if((note == 19) && (vel == 127), {
        midiOut.allNotesOff(4);
        ["Notes off", 4].postln;
    });

}, nil, nil, pedal.uid);

)
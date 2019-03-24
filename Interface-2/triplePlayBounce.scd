(

var lastNoteOn, triplePlay, midiOut;

triplePlay = ~getMidiIn.("Fishman TriplePlay", "TP Guitar");
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

)





(
var midiOut = MIDIOut.newByName("IAC Driver", "Bus 2");
var xkey = ~getMidiIn.("Xkey  ", "Xkey  ");
var tempo = 120;
var clocks = List.fill(20, {TempoClock.new(tempo/60, 0)});
var onNotes = Dictionary.new;
var notePoly = Dictionary.new;
var noteVel = Dictionary.new;
var generatePattern = {|note, vel|
    var pat = Pbind(
        \play, {
            Task.new({
                midiOut.noteOn(0, note, noteVel[note]);
                ((2.125 - ((notePoly[note]/127) * 2))*0.95).wait;
                midiOut.noteOff(0, note, noteVel[note]);
        }).play},
        \delta, Pfunc({(2.125 - ((notePoly[note]/127) * 2))});
    );
    pat.play(clocks[0]);

};
// ~timePat = Pfunc(((1 - notePoly[note]/127) * 2));
// ~timePat = Pseq([0.75, 1, 1.15], inf);
midiOut.latency = 0;
MIDIFunc.noteOn({|vel, note, chan, port|
    noteVel[note] = vel;
    notePoly[note] = vel;
    onNotes[note] = generatePattern.(note);

}, nil, nil, xkey.uid);

MIDIFunc.noteOff({|vel, note, chan, port|
    onNotes[note].stop;
}, nil, nil, xkey.uid);

MIDIFunc.polytouch({|vel, note, chan, port|
    notePoly[note] = vel;
}, nil, nil, xkey.uid);


)

[1, 1.5].choose
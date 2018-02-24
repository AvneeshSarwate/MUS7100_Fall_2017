(
~maxPort = NetAddr.new("127.0.0.1", 5555);

~midiIn = MIDIClient.sources.select({|elem| (elem.name == "Bus 2")
	&& (elem.device == "IAC Driver")})[0];

~lightSets = [
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
];

~lightVector = [0, 0, 0, 0];

~colorVectors = [
    [1, 0, 0],
    [1, 0, 1],
    [1, 1, 0],
    [0, 1, 1]
];

~midiOn = MIDIFunc.noteOn({|vel, note, chan, port|
    if(note > 11, {
        ~lightVector = ~lightVector + ~lightSets[note-12];
        ~calcDMX.(~lightVector, ~colorVectors);
        ["on", note].postln;
    });

}, nil, nil, ~midiIn.uid);

~midiOff = MIDIFunc.noteOff({|vel, note, chan, port|
    if(note > 11, {
        ~lightVector = ~lightVector - ~lightSets[note-12];
        ~calcDMX.(~lightVector, ~colorVectors);
        ["off", note].postln;
    });

}, nil, nil, ~midiIn.uid);

~midiCC = MIDIFunc.cc({|vel, note, chan, port|

}, nil, nil, ~midiIn.uid);

~calcDMX = {|lightVector, colorVectors|
    var dmxBuf = lightVector.collect({|lightVal, ind| lightVal*colorVectors[ind]}).flat;
    ~maxPort.sendRaw((["/dmxVals"]++dmxBuf).asArray.asRawOSC);
    (["/dmxVals"]++dmxBuf).postln
};

)
~midiIn.uid
a = List.new

~midiOn.free
~midiOff.free

[1, 2].collect({|a, b, c| [a, b, c].postln})
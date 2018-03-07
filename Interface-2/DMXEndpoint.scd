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

~buttons = List.fill(4, {List.new});

~fades = [1, 1, 1, 1];
~blends = [0, 0, 0, 0];

~colors1 = [
    [0, 0, 0],
    [1, 0, 0],
    [0, 1, 0],
    [0, 1, 1]
];

~colors2 = [
    [0, 0, 0],
    [0, 1, 0],
    [0, 1, 0],
    [0, 1, 1]
];

a.wrapAt(-1)
a = []

~midiOn = MIDIFunc.noteOn({|vel, note, chan, port|
    if(note < 16, {
        var col = note%4;
        var row = (note/4).floor;
        ~buttons[col].add(row);
    });

}, nil, nil, ~midiIn.uid);

~midiOff = MIDIFunc.noteOff({|vel, note, chan, port|
    if(note < 16, {
        var col = note%4;
        var row = (note/4).floor;
        ~buttons[col].remove(row);
    });

}, nil, nil, ~midiIn.uid);

~midiCC = MIDIFunc.cc({|vel, note, chan, port|

}, nil, nil, ~midiIn.uid);

~calcDMX = {|lightVector, colorVectors|
    var dmxBuf = List.new;
    (0..3).do({|col|
        var row = a.wrapAt(-1);
        if(row.isNil,
            {
                dmxBuff.add([0, 0, 0]);
            },
            {
                dmxBuf.add(255 * ~fades[col] * ((~blends[row]*~colors1[row]) + ((1-~blends[row])*~colors2[row])))
            }
        );
    });
    ~maxPort.sendRaw((["/dmxVals"]++dmxBuf.flat).asArray.asRawOSC);
    (["/dmxVals"]++dmxBuf).postln
};

)


(var row=1;var col=1;
~fades[col] * ((~blends[row]*~colors1[row]) + ((1-~blends[row])*~colors2[row]))
)
~midiIn.uid
a = List.new

~midiOn.free
~midiOff.free

[1, 2].collect({|a, b, c| [a, b, c].postln})

[1, 1, 0] | [1, 0, 1]
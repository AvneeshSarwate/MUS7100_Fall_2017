(
~deb = true;

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
    [1, 0, 0], //bottom row color
    [0, 1, 0],
    [0, 0, 1],
    [1, 1, 0]  //top row color
];

~colors2 = [
    [0, 1, 0], //bottom row color
    [1, 1, 0],
    [0, 1, 0],
    [0, 0, 1]  //top row color
];

~midiOn = MIDIFunc.noteOn({|vel, note, chan, port|
    if(note < 16, {
        var col = note%4;
        var row = (note/4).floor;
        ~buttons[col].add(row);
        //~buttons.postln;
        ~calcDMX.();
    });

}, nil, nil, ~midiIn.uid);

~midiOff = MIDIFunc.noteOff({|vel, note, chan, port|
    if(note < 16, {
        var col = note%4;
        var row = (note/4).floor;
        ~buttons[col].remove(row);
        //~buttons.postln;
        ~calcDMX.();
    });

}, nil, nil, ~midiIn.uid);

~midiCC = MIDIFunc.cc({|vel, note, chan, port|
    if((0..3).includes(note), {
        [note, 3-(0..3).indexOf(note)].postln;
        ~blends[3-(0..3).indexOf(note)] = 1 - (vel/127);
        ~calcDMX.();
    });
    if((4..7).includes(note), {
        ~fades[(4..7).indexOf(note)] = vel/127;
        ~calcDMX.();
    });
    if(~deb, {"MIDICC".postln});
}, nil, nil, ~midiIn.uid);

~calcDMX = {
    var dmxBuf = List.new;
    (0..3).do({|col|
        var row = ~buttons[col].wrapAt(-1);
        if(~deb, {["ROW COL", row, col].postln});
        if(row.isNil,
            {
                dmxBuf.add([0, 0, 0]);
            },
            {
                if(true, {[~blends[row], ((~blends[row]*~colors1[row]) + ((1-~blends[row])*~colors2[row]))].postln});
                dmxBuf.add(255 * ~fades[col] * ((~blends[row]*~colors1[row]) + ((1-~blends[row])*~colors2[row])))
            }
        );
    });
    dmxBuf = dmxBuf.flat.collect({|elem, ind| [ind+1, elem.asInt]}).flat;
    ~maxPort.sendRaw((["/dmxVals"]++dmxBuf).asArray.asRawOSC);
    if(~deb, {(["/dmxVals"]++dmxBuf).postln})
};

)

// (var row=1;var col=1;
// ~fades[col] * ((~blends[row]*~colors1[row]) + ((1-~blends[row])*~colors2[row]))
// )
// ~midiIn.uid
// a = List.new
//
// ~blends
// ~buttons[0].clear()
// ~calcDMX.()
// ~midiOn.free
// ~midiOff.free
// ~midiCC.free
//
// [1, 2].collect({|a, b, c| [a, b, c].postln})
//
// [1, 1, 0] | [1, 0, 1]
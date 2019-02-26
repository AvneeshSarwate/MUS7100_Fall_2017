(
var ccP, ccX, ccY, padX, padXY, ccToInd, ccToXY, noteToInd, noteToXY, isPadCC, isPadNote, isBankNote, bankToInd, sliderToInd, quneo, midiOut, td_port;

ccP = {|x| (x%3) == 2}; //check if cc is pressure value
ccX = {|x| (x%3) == 0}; //check if cc is x position
ccY = {|x| (x%3) == 1}; //check if cc is y position
noteToInd = {|x| x - 36}; //convert note to pad index
noteToXY = {|x| [noteToInd.(x)%4, floor(noteToInd.(x)/4)]}; //convert note to pad xy (bottom left 0,0)
ccToInd = {|x| floor((x-23)/3)}; //convert cc number to pad index
ccToXY = {|x| [(ccToInd.(x)%4), floor(ccToInd.(x)/4)]}; //convert cc number to pad xy
isPadCC = {|x| (ccToInd.(x) >=0) && (ccToInd.(x) < 16)};
isPadNote = {|x| (noteToInd.(x) >=0) && (noteToInd.(x) < 16)};
isBankNote = {|x| (x > 10) && (x < 19)};
bankToInd = {|x| x-11};
sliderToInd = {|x| [0,1,2,3,6,7,8,9].indexOf(x)};
td_port = NetAddr("localhost", 10000);

quneo = MIDIClient.sources.select({|elem| (elem.name == "QUNEO")
	&& (elem.device == "QUNEO")})[0];
midiOut = MIDIOut.newByName("IAC Driver", "Bus 7");
midiOut.latency = 0;
quneo.postln;
MIDIFunc.noteOn({|vel, note, chan, port|
    midiOut.noteOn(4, noteToInd.(note), vel);
}, nil, nil, quneo.uid);

MIDIFunc.noteOff({|vel, note, chan, port|
    midiOut.noteOn(4, noteToInd.(note), vel);
}, nil, nil, quneo.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if(sliderToInd.(note).isNil.not && (chan == 0), {
        //[chan, note, sliderToInd.(note), vel].postln;
        if(sliderToInd.(note) == 0, {td_port.sendMsg("/cameraMix", vel/127)});
        midiOut.control(chan, sliderToInd.(note), vel);
    });
}, nil, nil, quneo.uid);


)

// (
// var midiIn = MIDIClient.sources.select({|elem| (elem.name == "Bus 7")
// && (elem.device == "IAC Driver")})[0];
//
// MIDIFunc.cc({|vel, note, chan, port|
//     ["cc", chan, note, vel].postln;
// }, nil, nil, midiIn.uid);
//
// )
//
//
// (
// var midiOut = MIDIOut.newByName("IAC Driver", "Bus 7");
//
// midiOut.control(0, 0, 120)
//
// )
//
// OSCFunc.trace
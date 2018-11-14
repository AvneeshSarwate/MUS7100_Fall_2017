(
var masterTempoClock, broadcastOSCport;

MIDIClient.init;
MIDIIn.connectAll;
~lightIndexes = Dictionary.new;
(0..10).do({|i| ~lightIndexes[i] = List.new});
~lightIndex = Dictionary.new;
~numAppsPerPad = Dictionary.new;
~lock = Semaphore(1);
~cycling = true;
~getLaunchpadOut = {|launchpadInd|
    var suffix = if(launchpadInd == 0, "", ""+(launchpadInd+1));
    var index = MIDIClient.destinations.collect({|elem, ind|
        // [elem.device.asSymbol == ("Launchpad Pro"++suffix).asSymbol, (elem.name == "Standalone Port"),  elem.device.asSymbol, ("Launchpad Pro"++suffix).asSymbol].postln;
        if(((elem.name == "Standalone Port") && (elem.device.asSymbol == ("Launchpad Pro"++suffix).asSymbol)), ind, nil)}).select({|elem| elem.isNil.not})[0];
    ["IND", ("Launchpad Pro"++suffix), index].postln;
    MIDIOut.new(index);
};
~getLaunchpadIn = {|launchpadInd|
    var suffix = if(launchpadInd == 0, "", ""+(launchpadInd+1));
    MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
        && (elem.device == ("Launchpad Pro"++suffix))})[0]
};
masterTempoClock = TempoClock.new(2);
broadcastOSCport = NetAddr("localhost", 57120);

masterTempoClock.sched(0, {broadcastOSCport.sendMsg("/masterClockBeat", masterTempoClock.beatDur); 1});

//msg[1] is the new BEAT DURATION (not tempo)
//msg[2] is whether the beat is being realigned
OSCFunc({|msg, time, addr, recvPort|
	masterTempoClock.tempo = 1/msg[1].asFloat;
	broadcastOSCport.sendMsg("/masterClockTempo", msg[1].asFloat, msg[2].asBoolean)
}, "/uploadTempo");



~getMidiIn = {|device, name|
    MIDIClient.sources.select({|elem| (elem.device == device) && (elem.name == name)})[0]
};

~getMidiOut = {|device, name|
    var ind = MIDIClient.destinations.collect({|elem, ind| (device: elem.device, name: elem.name, idx: ind)}).select({|elem| (elem.device == device) && (elem.name == name)})[0].idx;
    ind.postln;
    MIDIOut.new(ind);
};

~bounceMidi = {|midiIn, midiOut|
    var onFunc, offFunc, ccFunc;
    midiOut.latency = 0;

    onFunc = MIDIFunc.noteOn({|vel, note, chan, port|
        midiOut.noteOn(chan, note, vel);
    }, nil, nil, midiIn.uid);

    offFunc = MIDIFunc.noteOff({|vel, note, chan, port|
        midiOut.noteOff(chan, note, vel);
    }, nil, nil, midiIn.uid);

    ccFunc = MIDIFunc.cc({|vel, note, chan, port|
        midiOut.control(chan, note, vel);
    }, nil, nil, midiIn.uid);
    [onFunc, offFunc, ccFunc]
};


~bounceMidi.(~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge"), ~getMidiOut.("IAC Driver", "Bus 2"))

)



// (
// var lp;
// ~getMidiOut = {|device, name|
//     var ind = MIDIClient.destinations.collect({|elem, ind| (device: elem.device, name: elem.name, idx: ind)}).select({|elem| (elem.device == device) && (elem.name == name)})[0].idx;
//     ind.postln;
//     MIDIOut.new(ind);
// };
// lp = ~getMidiOut.("Launchpad Mini", "Launchpad Mini");
// lp.noteOn(0, 8, 3);
// )
//
/*(
var noteToProInd = {|x|
    var row = 7 - (x / 16).asInt + 1;
    var col = (x % 16) + 1;
    var retVal = -1;
    if(col < 9, {retVal = row*10 + col});
    retVal
};
noteToProInd.(88)
)*/
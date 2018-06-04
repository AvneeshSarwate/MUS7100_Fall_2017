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

)

~lightIndex=0

SuperDirt.start

MIDIClient.destinations.collect({|elem, ind| if(((elem.name == "Standalone Port") && (elem.device == ("Launchpad Pro"++" 2"))), ind, nil)}).select({|elem| elem.isNil.not})[0]


~getLaunchpadOut.(1)

"aa" == ("a"++"a")

"Launchpad Pro 2" == "Launchpad Pro 2"

~getMidiIn.("Xkey  ", "Xkey  ")
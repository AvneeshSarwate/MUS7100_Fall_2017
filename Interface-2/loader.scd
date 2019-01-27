
(
~testEnvVar = "SHOULD BE FINE";
Task({
    ~numSliderToggles = 5;
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    // "./algoKeys.scd".loadRelative;
    // 0.01.wait;
    // "./sceneBuilder.scd".loadRelative;
    // 0.01.wait;
    // "./loopSequencer.scd".loadRelative;
    // 0.01.wait;
    // "./chordScenePad.scd".loadRelative;
    // 0.01.wait;
    // "./spatializeKeyboard.scd".loadRelative;
    // 0.01.wait;
    // "./arpeggiator.scd".loadRelative;
    // 0.01.wait;
    "./PydalSC.scd".loadRelative;
    0.01.wait;
    "./LFOFM.scd".loadRelative;
    // 0.01.wait;
    "./sceneBuilderMini.scd".loadRelative;
    // 0.01.wait;
    // "./sliderPad.scd".loadRelative;
    // 0.01.wait;

    ~bounceMidi.(~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge"), ~getMidiOut.("IAC Driver", "Bus 7"));
    // ~bounceMidi.(~getMidiIn.("QuNexus", "Port 1"), ~getMidiOut.("IAC Driver", "Bus 7"));
    ~touchOSCBridge = ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge");
    ~touchOSCBridge.latency = 0;
    ~fwdTouchOSCLights = true;
}).play
)

~bounceMidi.(~getMidiIn.("IAC Driver", "Bus 7"), ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge"));


// ~getMidiIn = {|device, name|
//     MIDIClient.sources.select({|elem| (elem.device == device) && (elem.name == name)})[0]
// };


(
var qunexus, touchOSCBridge, midiOut;


qunexus = ~getMidiIn.("QuNexus", "Port 1");
touchOSCBridge = ~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge");
midiOut = MIDIOut.newByName("IAC Driver", "Bus 7");
midiOut.latency = 0;

MIDIFunc.noteOn({|vel, note, chan, port|
    "ON".postln;
    midiOut.noteOn(chan, note, vel);
}, nil, nil, qunexus.uid);
"ONSET".postln;
MIDIFunc.noteOff({|vel, note, chan, port|
    midiOut.noteOff(chan, note, vel);
}, nil, nil, qunexus.uid);
"OFFSET".postln;
MIDIFunc.cc({|vel, note, chan, port|
    midiOut.control(chan, note, vel);
}, nil, nil, touchOSCBridge.uid);
)

FoxDot.start
OSCFunc.trace
5

n = NetAddr.new("127.0.0.1", 50506)

n.sendMsg("/send/GD", "all", "/networkSyncHit", 1)



~setSliderBanks.([ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [ 63, 63, 63, 66, 68 ], 0, 0, [ 71, 37, 63, 24, 93 ], [ 63, 104, 62, 107, 84 ], 0, [ 74, 90, 53, 90, 74 ], 0, 0, 0, [ 63, 63, 63, 63, 63 ], [ 63, 63, 63, 63, 84 ], [ 63, 47, 63, 47, 84 ], [ 63, 38, 63, 37, 84 ], [ 63, 101, 62, 100, 84 ], [ 79, 101, 62, 100, 79 ], [ 69, 90, 53, 90, 69 ], 0, 0, 0 ])

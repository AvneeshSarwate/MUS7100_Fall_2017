
(
~testEnvVar = "SHOULD BE FINE";
Task({
    ~numSliderToggles = 5;
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    "./algoKeys.scd".loadRelative;
    0.01.wait;
    "./sceneBuilder.scd".loadRelative;
    0.01.wait;
    // "./loopSequencer.scd".loadRelative;
    // 0.01.wait;
    // "./chordScenePad.scd".loadRelative;
    // 0.01.wait;
    // "./spatializeKeyboard.scd".loadRelative;
    // 0.01.wait;
    // "./arpeggiator.scd".loadRelative;
    // 0.01.wait;
    // "./PydalSC.scd".loadRelative;
    // 0.01.wait;
    // "./LFOFM.scd".loadRelative;
    // 0.01.wait;
    // "./sceneBuilderMini.scd".loadRelative;
    0.01.wait;
    "./sliderPad.scd".loadRelative;
    // 0.01.wait;
    // "./QuneoDMX.scd".loadRelative;
    0.01.wait;
    // "./DMXEndpoint.scd".loadRelative;
    0.01.wait;
    // "./triplePlayBounce.scd".loadRelative;
    0.01.wait;


    // ~bounceMidi.(~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge"), ~getMidiOut.("IAC Driver", "Bus 7"));
    // ~bounceMidi.(~getMidiIn.("QUNEO", "QUNEO"), ~getMidiOut.("IAC Driver", "Bus 2"), true);
    // ~touchOSCBridge = ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge");
    // ~touchOSCBridge.latency = 0;
    // ~fwdTouchOSCLights = false;
}).play
)

~bounceMidi.(~getMidiIn.("IAC Driver", "Bus 7"), ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge"));



//basic looper
(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~loadModules.(["algoKeys", "sceneBuilder"]);
    0.1.wait;
    ~setBPM.(160);
}).play)


//mini looper - shader: responsiveVis1, loops- responsivevis1.scenes
(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~miniLooperUseKeyboardChan = true;
    ~loadModules.(["algoKeys", "sceneBuilderMini"]);
    0.1.wait;
    ~setBPM.(160);
}).play)


//chord slider piece - responsiveVis3b
(Task({
    ~numSliderToggles = 5;
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~loadModules.(["algoKeys", "sceneBuilder", "spatializeKeyboard", "sliderPad"]);
    0.01.wait;
    ~bounceMidi.(~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge"), ~getMidiOut.("IAC Driver", "Bus 7"));
    0.1.wait;
    ~setSliderBanks.([ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [ 63, 63, 63, 66, 68 ], 0, 0, [ 71, 37, 63, 24, 93 ], [ 63, 104, 62, 107, 84 ], 0, [ 74, 90, 53, 90, 74 ], 0, 0, 0, [ 63, 63, 63, 63, 63 ], [ 63, 63, 63, 63, 84 ], [ 63, 47, 63, 47, 84 ], [ 63, 38, 63, 37, 84 ], [ 63, 101, 62, 100, 84 ], [ 79, 101, 62, 100, 79 ], [ 69, 90, 53, 90, 69 ], 0, 0, 0 ]);
}).play)



(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~loadModules.(["triplePlayBounce"]);
}).play)




(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~loadModules.(["granularLooper"]);
}).play)





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


OSCFunc.trace
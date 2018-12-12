
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
    "./spatializeKeyboard.scd".loadRelative;
    0.01.wait;
    // "./arpeggiator.scd".loadRelative;
    // 0.01.wait;
    // "./PydalSC.scd".loadRelative;
    // 0.01.wait;
    // "./sceneBuilderMini.scd".loadRelative;
    // 0.01.wait;
    "./sliderPad.scd".loadRelative;
    0.01.wait;

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

5


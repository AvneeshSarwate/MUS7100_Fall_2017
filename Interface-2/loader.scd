
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
    ~bounceMidi.(~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge"), ~getMidiOut.("IAC Driver", "Bus 7"));
    ~fwdTouchOSCLights=true;
    ~touchOSCBridge = ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge");
    ~touchOSCBridge.latency = 0;
    0.01.wait;
    ~loadModules.(["sceneBuilder", "PydalSC", "LFOFM"]);
}).play)




(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~loadModules.(["triplePlayBounce"]);
}).play)




(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~ipadIP = ["169.254.160.226", 9000];
    ~loadModules.(["granularLooper"]);
}).play)



(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    "../../powerPianoRoll/pianoRollPlayer.scd".loadRelative
}).play)


(Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    ~loadModules.(["PydalSC", "LFOFM"]);
}).play)

/*
Todo - bugfix for multi-launchpad app-light changing
when sending light change messages on "/lightsChange" address, include the launchpadInd of the app sending it, and only execute change for apps with the same launchpadInd
*/
(
~testEnvVar = "SHOULD BE FINE";
Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;

    //initialize specific values for env varis AFTER masterTempoClock, because that will set their default values;
    ~numSliderToggles = 5;
    ~miniLooperUseKeyboardChan = true;
    ~fwdTouchOSCLights=true;
    ~touchOSCBridge = ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge");
    ~touchOSCBridge.latency = 0;


    "./algoKeys.scd".loadRelative;
    0.01.wait;
    "./sceneBuilder.scd".loadRelative;
    0.01.wait;

   "./spatializeKeyboard.scd".loadRelative;
    0.01.wait;
    "./sliderPad.scd".loadRelative;
    0.01.wait;
    ~bounceMidi.(~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge"), ~getMidiOut.("IAC Driver", "Bus 7"));
    0.1.wait;
    ~setSliderBanks.([ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [ 63, 63, 63, 66, 68 ], 0, 0, [ 71, 37, 63, 24, 93 ], [ 63, 104, 62, 107, 84 ], 0, [ 74, 90, 53, 90, 74 ], 0, 0, 0, [ 63, 63, 63, 63, 63 ], [ 63, 63, 63, 63, 84 ], [ 63, 47, 63, 47, 84 ], [ 63, 38, 63, 37, 84 ], [ 63, 101, 62, 100, 84 ], [ 79, 101, 62, 100, 79 ], [ 69, 90, 53, 90, 69 ], 0, 0, 0 ]);

    "./PydalSC.scd".loadRelative;
    0.01.wait;
    "./LFOFM.scd".loadRelative;
    0.01.wait;

    "./triplePlayBounce.scd".loadRelative;
    0.01.wait;

    ~ipadIP = ["169.254.113.33", 9000];
    "./granularLooper.scd".loadRelative;
    0.01.wait;
    0.5.wait;
    ~setBPM.(160);

}).play
)

OSCFunc.trace



(
var x, z;
a = 5;
x = switch (a.postln
    {5}, {a = 6},
    {6}, {a = 5}
  );
x.postln;
)

(
"./masterTempoClock.scd".loadRelative;
m = ~getMidiOut.("IAC Driver", "Bus 2");
n = NetAddr("localhost", 57120);
)


(
f = {
    var midiIn = ~getMidiIn.("IAC Driver", "Bus 2");
    MIDIFunc.noteOn({|vel, note, chan, port|
        ["AYY", vel, note, chan].postln;
    }, nil, nil, midiIn.uid);
    OSCFunc({|msg, time, addr, recvPort|
        msg.postln
    }, "/testmsg");
};
f.()
)

OSCFunc.trace



m.noteOn(5, 24, 52)
n.sendMsg("/testmsg", 5)


~ip = NetAddr("127.0.0.1", 8765)
~ip.sendMsg("/message/address")



~pm.keys()

MIDIFunc.reset



this.functionCompileContext



a = Object.readArchive("~/".standardizePath++"SCcl0sure.txt")

c = Dictionary.newFrom(a)

~glData[71].writeArchive("~/".standardizePath ++ "/MUS7100_Fall_2017/Interface-2/defaultPreset.sc")

d = Object.readArchive("~/".standardizePath ++ "/MUS7100_Fall_2017/Interface-2/defaultPreset.sc")

d



~setSliderBanks.([ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [ 63, 63, 63, 66, 68 ], 0, 0, [ 71, 37, 63, 24, 93 ], [ 63, 104, 62, 107, 84 ], 0, [ 74, 90, 53, 90, 74 ], 0, 0, 0, [ 63, 63, 63, 63, 63 ], [ 63, 63, 63, 63, 84 ], [ 63, 47, 63, 47, 84 ], [ 63, 38, 63, 37, 84 ], [ 63, 101, 62, 100, 84 ], [ 79, 101, 62, 100, 79 ], [ 69, 90, 53, 90, 69 ], 0, 0, 0 ])


OSCFunc.trace
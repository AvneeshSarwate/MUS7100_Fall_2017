
(
~testEnvVar = "SHOULD BE FINE";
Task({
    "./masterTempoClock.scd".loadRelative;
    0.01.wait;
    "./algoKeys.scd".loadRelative;
    0.01.wait;
    "./sceneBuilder.scd".loadRelative;
    0.01.wait;
    "./loopSequencer.scd".loadRelative;
    0.01.wait;
    // "./chordScenePad.scd".loadRelative;
    0.01.wait;
    "./spatializeKeyboard.scd".loadRelative;
    0.01.wait;
    "./arpeggiator.scd".loadRelative;
    0.01.wait;
    "./PydalSC.scd".loadRelative;
}).play
)
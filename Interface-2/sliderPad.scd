(

var sliderVals, sliderBanks, record_BUTTON, record_COLOR, bank_COLOR, launchpadIndex, launchpad, slidersIn, slidersOut, launchpadIn, launchpadOut, rampStartValues, rampEndValues, isRecording, rampTask, slideSpeed, touchOSCOut, sliderToggles, sliderLoopIn;

launchpadIndex = 0;
launchpadOut = ~getLaunchpadOut.(launchpadIndex);
launchpadOut.latency = 0;
launchpadIn = ~getLaunchpadIn.(launchpadIndex);

slidersIn = ~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge");
sliderLoopIn = ~getMidiIn.("IAC Driver", "Bus 2");
slidersOut = ~getMidiOut.("IAC Driver", "Bus 7");
slidersOut.latency = 0;

touchOSCOut = ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge");
touchOSCOut.latency = 0;

sliderVals = List.fill(4, {0});
sliderBanks = List.fill(88, {0});
sliderToggles = List.fill(4, {true});

~setSliderBanks = {|vals| sliderBanks = vals};

isRecording = false;
record_BUTTON = 89;
record_COLOR = 5;
bank_COLOR = 3;

rampTask = Task({});
slideSpeed = 0.5;


(0..99).do({|i| launchpadOut.noteOn(0, i, 0)});

MIDIFunc.cc({|vel, note, chan, port|
    if(chan == 0,  {
        if(note < 4, {
            sliderVals[note] = vel;
            // ["manualSlider a", note, vel, chan].postln;
        });
    });
}, nil, nil, slidersIn.uid);


MIDIFunc.cc({|vel, note, chan, port|
    if(chan == 0,  {
        if(note < 4, {
            sliderVals[note] = vel;
            // ["manualSlider b", note, vel, chan].postln;
        });
        if(note == 7, {
            slideSpeed = (127-vel+1)/127;
        });
    });
    if(chan == 1,  {
        sliderToggles[note] = vel == 127;
    });
}, nil, nil, slidersIn.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if(chan == 0,  {
        if(note < 4, {
            sliderVals[note] = vel;
            // ["manualSlider c", note, vel, chan].postln;
        });//posttodo also this for iac 2 - remember loop midiCCs
    });
}, nil, nil, sliderLoopIn.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if((note == record_BUTTON) && (vel == 127), {
        isRecording = isRecording.not;
        launchpadOut.noteOn(0, record_BUTTON, if(isRecording, record_COLOR, 0));
    });
}, nil, nil, launchpadIn.uid);



MIDIFunc.noteOn({|vel, note, chan, port|
    if(isRecording,
        {
            sliderBanks[note] = sliderVals.deepCopy;
            launchpadOut.noteOn(0, note, bank_COLOR);
            sliderBanks.postln;
        },
        {
            if(sliderBanks[note] != 0, {
                ["Play button", note].postln;
                rampStartValues = sliderVals.deepCopy;
                rampEndValues = sliderBanks[note].deepCopy;
                rampTask.stop;
                rampTask.clear;
                rampTask = Task({
                    var elapsedTime = 0;
                    var totalTime = vel/127 * 4;
                    var sliderValsCopy = sliderVals.deepCopy;
                    ["play task started", note, sliderValsCopy].postln;
                    while({elapsedTime < (totalTime * slideSpeed)}, {
                        var a = elapsedTime / (totalTime * slideSpeed);
                        sliderVals = (min(a, 1)*rampEndValues) + (max(1-a, 0)*rampStartValues); //todo - don't interpolate/saved non-toggle melodiesbbb
                        [a, sliderVals].postln;
                        sliderVals.do({|v, i| if(sliderToggles[i],
                            {slidersOut.control(0, i, v)},
                            {sliderVals[i] = sliderValsCopy[i]}
                        )});
                        [sliderVals, sliderValsCopy].postln;
                        sliderVals.do({|v, i| if(sliderToggles[i], touchOSCOut.control(0, i, v))});
                        elapsedTime = elapsedTime + 0.01;
                        0.01.wait;
                    });
                });
                rampTask.play;
            });
        }
    );
}, nil, nil, launchpadIn.uid);


)

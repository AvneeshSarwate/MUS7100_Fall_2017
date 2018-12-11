(

var sliderVals, sliderBanks, record_BUTTON, recordButton_COLOR, bank_COLOR, launchpadIndex, launchpad, slidersIn, slidersOut, launchpadIn, launchpadOut, rampStartValues, rampEndValues, isRecording, rampTask, slideSpeed;

launchpadIndex = 0;
launchpadOut = ~getLaunchpadOut.(launchpadIndex);
launchpadOut.latency = 0;
launchadIn = ~getLaunchpadIn.(launchpadIndex);

slidersIn = ~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge");
slidersOut = ~getMidiOut.("IAC Driver", "Bus 7");
slidersOut.latency = 0;

sliderVals = List.fill(4, {0});
sliderBanks = List.fill(88, {0});

~setSliderBanks = {|vals| sliderBanks = vals};

isRecording = false;
record_BUTTON = 89;
record_COLOR = 5;
bank_COLOR = 3;

rampTask = Task({});
slideSpeed = 0.5;

MIDIFunc.cc({|vel, note, chan, port|
    if(note < 4, {
        sliderVals[note] = vel;
    });
}, nil, nil, slidersIn.uid);


MIDIFunc.cc({|vel, note, chan, port|
    if(note < 4, {
        sliderVals[note] = vel;
    });
    if(note == 7, {
        slideSpeed = (127-vel+1)/127;
    });
}, nil, nil, slidersIn.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if(note == record_BUTTON, {
        isRecording = isRecording.not;
        launcpadOut.noteOn(0, record_BUTTON, if(isRecording, recordButton_COLOR, 0));
    });
}, nil, nil, launchpadIn.uid);



MIDIFunc.noteOn({|vel, note, chan, port|
    if(isRecording,
        {
            sliderBanks[note] = sliderVals.deepCopy;
            launcpadOut.noteOn(0, note, bank_COLOR);
            sliderBanks.postln;
        },
        {
            if(sliderBanks[note] != 0, {
                rampStartValues = sliderVals.deepCopy;
                rampEndValues = sliderBanks[note].deepCopy;
                rampTask.stop;
                rampTask.clear;
                rampTask = new Task({
                    var elapsedTime = 0;
                    var totalTime = vel/127 * 4;
                    while({elapsedTime < totalTime}, {
                        var a = elapsedTime / (totalTime * slideSpeed);
                        sliderVals = (max(a, 1)*rampEndValues) + (min(1-a, 0)*rampStartValues);
                        sliderVals.do({|v, i| slidersOut.control(0, i, v)});
                    });
                });
                rampTask.play;
            });
        }
    );
}, nil, nil, launchpadIn.uid);


)




1 - [1, 2, 3]
(

var sliderVals, sliderBanks, record_BUTTON, record_COLOR, bank_COLOR, launchpadIndex, launchpad, slidersIn, slidersOut, launchpadIn, launchpadOut, rampStartValues, rampEndValues, isRecording, rampTask, slideSpeed, touchOSCOut, sliderToggles, sliderLoopIn, numSliders, graphicsOut, rand, padAutomateIn, noteOnFunc, controlHandler, controlHandlerWrapper, masterClockOSCport;
var setLight, ccLights, padColorState, cycleLight, lightIndex, cycleLight_BUTTON;


launchpadIndex = 1;
launchpadOut = ~getLaunchpadOut.(launchpadIndex);
padAutomateIn = ~getMidiIn.("IAC Driver", "Bus 1");
launchpadOut.latency = 0;
launchpadIn = ~getLaunchpadIn.(launchpadIndex);

slidersIn = ~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge");
sliderLoopIn = ~getMidiIn.("IAC Driver", "Bus 2");
slidersOut = ~getMidiOut.("IAC Driver", "Bus 7");
slidersOut.latency = 0;

touchOSCOut = ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge");
touchOSCOut.latency = 0;

graphicsOut = ~getMidiOut.("IAC Driver", "Bus 2");
graphicsOut.latency = 0;

masterClockOSCport = NetAddr("localhost", 57120);

numSliders = ~numSliderToggles;
sliderVals = List.fill(numSliders, {0});
sliderBanks = List.fill(88, {0});
sliderToggles = List.fill(numSliders, {true});




//----------------------------------------------
//light switching variables
cycleLight_BUTTON = 95;
padColorState = Dictionary.new;
~padColors = padColorState;
ccLights = List.new;
(1..8).do({|i|
    ccLights.add(i);
    ccLights.add(90+i);
    ccLights.add(i*10);
    ccLights.add((i*10)+9);
});

setLight = {|note, color, lightIndexOverride=false|
    if((~lightIndex[launchpadIndex] == lightIndex) || lightIndexOverride, {
        if(ccLights.includes(note),
            {launchpadOut.control(0, note, color)},
            {launchpadOut.noteOn(0, note, color)}
        );
    });
    padColorState[note] = color;
};
(1..98).do({|note|
    if(ccLights.includes(note),
        {launchpadOut.control(0, note, 0)},
        {launchpadOut.noteOn(0, note, 0)}
    );
    padColorState[note] = 0;
});
cycleLight = {
    //TODO: change name of this port to something like SCOSCport
    Task({
        ["NEW LIGHT INDEX TRIGGER FROM SLIDER PAD", ~lightIndex[launchpadIndex]].postln;
        masterClockOSCport.sendMsg("/lightsChange", (~lightIndex[launchpadIndex]+1)%~lightIndexes[launchpadIndex].size, launchpadIndex);
        0.01.wait;
        ~lightIndex[launchpadIndex] = (~lightIndex[launchpadIndex]+1)%~lightIndexes[launchpadIndex].size;
    }).play;
};

//msg[1] is lightIndex
OSCFunc({|msg, time, addr, recvPort|
    if((msg[1].asInt == lightIndex) && (msg[2] == launchpadIndex), {
        var colorStateLog = List.new(100);
        (0..99).do({|i| colorStateLog.add(0)});
        padColorState.keys.do({|key| setLight.(key, padColorState[key], true);
            colorStateLog[key]=padColorState[key]});
        ["CHANGING TO SLIDER PAD LIGHTS", msg[1], colorStateLog].postln;
    });

}, "/lightsChange");
lightIndex = if(~lightIndexes[launchpadIndex].size == 0,
    {
        ~lightIndexes[launchpadIndex].add(0);
        0
    },
    {
        ~lightIndexes[launchpadIndex].add(~lightIndexes[launchpadIndex].maxItem+1);
        ~lightIndexes[launchpadIndex].maxItem
    }
);
~lightIndex[launchpadIndex] = lightIndex;
["LIGHT INDEX SLIDER PAD", ~lightIndex[launchpadIndex], lightIndex].postln;
//TODO - add ~lightIndex[launchpadIndex] == lightIndex condition to all launchpad note/cc hanlders
//----------------------------------------------






~sliderBanks = sliderBanks;
~setSliderBanks = {|vals|
    sliderBanks = vals ++ List.fill(88, {0});
    (0..88).do({|i| if(sliderBanks[i] != 0, {setLight.(i, bank_COLOR)})});
};

isRecording = false;
record_BUTTON = 89;
record_COLOR = 5;
bank_COLOR = 3;


rampTask = Task({});
slideSpeed = 0.5;


(0..99).do({|i| setLight.(i, 0)});

MIDIFunc.cc({|vel, note, chan, port|
    if(chan == 0,  {
        if(note < numSliders, {
            sliderVals[note] = vel;
            // ["manualSlider a", note, vel, chan].postln;
        });
    });
}, nil, nil, slidersIn.uid);


MIDIFunc.cc({|vel, note, chan, port|
    if(chan == 0,  {
        if(note < numSliders, {
            sliderVals[note] = vel;
            // ["manualSlider b", note, vel, chan].postln;
        });
        if(note == 7, {
            slideSpeed = (128-vel)/127;
        });
    });
    if(chan == 1,  {
        sliderToggles[note] = vel == 127;
    });
}, nil, nil, slidersIn.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if(chan == 0,  {
        if(note < numSliders, {
            sliderVals[note] = vel;
            // ["manualSlider c", note, vel, chan].postln;
        });//posttodo also this for iac 2 - remember loop midiCCs
    });
}, nil, nil, sliderLoopIn.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if((note == record_BUTTON) && (vel == 127), {
        isRecording = isRecording.not;
        setLight.(record_BUTTON, if(isRecording, record_COLOR, 0));
    });
}, nil, nil, launchpadIn.uid);


noteOnFunc = {|vel, note, chan, port|
    if(isRecording,
        {
            sliderBanks[note] = sliderVals.deepCopy;
            setLight.(note, bank_COLOR);
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
                    var rampStartPos = rampStartValues.collect({|v| ~rand.(v)});
                    var rampEndPos = rampEndValues.collect({|v| ~rand.(v)});
                    var elapsedTime = 0;
                    var totalTime = (128-vel)/127 * 4;
                    var sliderValsCopy = sliderVals.deepCopy;
                    ["play task started", note, sliderValsCopy].postln;
                    while({elapsedTime < (totalTime * slideSpeed)}, {
                        var a = elapsedTime / (totalTime * slideSpeed);
                        sliderVals = (min(a, 1)*rampEndValues) + (max(1-a, 0)*rampStartValues); //todo - don't interpolate/saved non-toggle melodiesbbb
                        sliderVals.do({|v, i|
                            if(sliderToggles[i],
                                {slidersOut.control(0, i, v)},
                                {sliderVals[i] = sliderValsCopy[i]}
                            );
                            0.001.wait
                        });
                        // [a, sliderVals].postln;
                        sliderVals.do({|v, i| if(sliderToggles[i], touchOSCOut.control(0, i, v)); 0.001.wait});
                        (0..(numSliders-1)).do({|i|
                            var xInterp = (min(a, 1)*rampEndPos) + (max(1-a, 0)*rampStartPos);
                            var yStartPos = rampStartPos.collect({|v| ~rand.(v+5)});
                            var yEndPos = rampEndPos.collect({|v| ~rand.(v+5)});
                            var yInterp = (min(a, 1)*yEndPos) + (max(1-a, 0)*yStartPos);

                            if(sliderToggles[i], {graphicsOut.control(0, 80+i, (xInterp[i]*128).floor)});
                            0.001.wait;
                            if(sliderToggles[i], {graphicsOut.control(0, 80+(i*2)+1, (yInterp[i]*128).floor)});
                            0.001.wait;
                        });
                        elapsedTime = elapsedTime + 0.02;
                        0.01.wait;
                    });
                    rampEndValues.do({|v, i| if(sliderToggles[i],
                        {slidersOut.control(0, i, v); 0.001.wait},
                        {sliderVals[i] = sliderValsCopy[i]; 0.001.wait}
                    )});
                    rampEndValues.do({|v, i| if(sliderToggles[i], {touchOSCOut.control(0, i, v); 0.001.wait})});
                });
                rampTask.play;
            });
        }
    );
};

MIDIFunc.noteOn(noteOnFunc, nil, nil, launchpadIn.uid);
MIDIFunc.noteOn(noteOnFunc, nil, nil, padAutomateIn.uid);


controlHandler = {|vel, note, chan, port|
    if((note == cycleLight_BUTTON) && (vel !=0), {
        // ["MULTILOOP BUTTON CYCLE HIT", ~lightIndex[launchpadIndex], lightIndex].postln;
        if(~cycling, {cycleLight.()})
    });
};
controlHandlerWrapper = {|vel, note, chan, port|
    ~lock.wait;
    if((chan == 0) && (~lightIndex[launchpadIndex] == lightIndex) && (vel != 0), {
        //["LIGHT INDEX MULTILOOP", ~lightIndex[launchpadIndex], lightIndex, SystemClock.beats].postln;
        controlHandler.(vel, note, chan, port)
    });
    ~lock.signal;
};
MIDIFunc.cc(controlHandlerWrapper, nil, nil, launchpadIn.uid);


)


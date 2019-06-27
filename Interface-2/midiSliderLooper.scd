(
var launchpadIn, launchpadOut, maxOscOut, ipadMidiIn, ipadOscOut, ipadMidiOut, loopRecord_BUTTON, recordBuffer, tempRecordingTask, tempLoop_COLOR, loopRecordingState, oscHandler, oscAddrs, isRecording, recording_COLOR, notRecording_COLOR, tempRecord_COLOR, loopToPadMap, paramMap, createLoopPattern, tempoClock, recordStartTime, recordEndTime, loopSaved_COLOR, padPlaying_COLOR, saveLoopToBank, recordingStateColors, interpolateParamMaps, saveParams, sendParamMap, sendMSG, savePreset_BUTTON, presetVoice1_BUTTON, presetVoice2_BUTTON, paramStart, paramEnd, interpolationSpeed, interpSpeed_BUTTONS, savingParams, startPresetInterpolation, interpolationTask, paramSaved_COLOR, syncTempo_BUTTON, syncPhase_BUTTON, dspOn, dsp_BUTTON, visalsOscOut, midiOut, numLoopsRecorded;
var setLight, ccLights, padColorState, cycleLight, lightIndex, cycleLight_BUTTON, launchpadIndex, controlHandler, controlHandlerWrapper, masterClockOSCport;

launchpadIndex = 0;
ipadMidiIn = ~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge");
ipadMidiOut = ~getMidiOut.("TouchOSC Bridge", "TouchOSC Bridge");

midiOut = ~getMidiOut.("IAC Driver", "Bus 2");
launchpadIn = ~getLaunchpadIn.(launchpadIndex);
launchpadOut = ~getLaunchpadOut.(launchpadIndex);

maxOscOut = NetAddr("127.0.0.1", 8000);
visalsOscOut = NetAddr("127.0.0.1", 5432);
masterClockOSCport = NetAddr("localhost", 57120);

launchpadOut.latency = 0;
ipadMidiOut.latency = 0;
midiOut.latency = 0;




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
    // "PADCOLORSTATE CHECK".postln;
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
        ["NEW LIGHT INDEX TRIGGER FROM GRANULAR LOOPER", ~lightIndex[launchpadIndex]].postln;
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
        ["CHANGING TO GRANULAR LOOPER LIGHTS", msg[1], colorStateLog].postln;
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
["LIGHT INDEX GRANULAR LOOPER", ~lightIndex[launchpadIndex], lightIndex].postln;
//TODO - add ~lightIndex[launchpadIndex] == lightIndex condition to all launchpad note/cc hanlders
//----------------------------------------------




numLoopsRecorded = 0;
loopRecord_BUTTON = 89;
savePreset_BUTTON = 79;
presetVoice1_BUTTON = 69;
presetVoice2_BUTTON = 59;
interpSpeed_BUTTONS = (1..8);
syncTempo_BUTTON = 29;
syncPhase_BUTTON = 19;
dsp_BUTTON = 10;
recordBuffer = List.new;
tempRecordingTask = nil;
loopRecordingState = 0; //0, 1, 2 for notRecording, recording, recordedButNotSaved
loopToPadMap = Dictionary.new; //[padInd, 'loop'/'preset', pattern/preset-array]
~glData = loopToPadMap;
paramMap = Dictionary.new;
(0..127).do({|i| paramMap[i] = 0});
tempoClock = TempoClock.new;
~loadGranularLooperPreset = {|filename|
    loopToPadMap = Object.readArchive("~/".standardizePath ++ "/MUS7100_Fall_2017/Interface-2/" ++ filename);
};

recordStartTime = nil;
recordEndTime = nil;
isRecording = false;
savingParams = false;
interpolationSpeed = 1/8;
dspOn = false;


recording_COLOR = 5;
notRecording_COLOR = 17;
tempRecord_COLOR = 9;
loopSaved_COLOR = 3;
padPlaying_COLOR = 18;
paramSaved_COLOR = 119;
recordingStateColors = [notRecording_COLOR, recording_COLOR, tempRecord_COLOR];



//TODO - find default for params and their corresponding midi values? + blast these out at start of program
// - or set default params to both ipad and max from here

//TODO - add option to only interpolate/pull up params for voice 1/2
interpolateParamMaps = {|map1, map2, interp|
    var interpMap = Dictionary.new;
    map1.keys().do({|key|
        if(key.asSymbol != '/senselDraw', {
            var val = ((1-interp)*map1[key]) + (interp*map2[key]) ;
            interpMap[key] = val;
        });
    });
    interpMap
};

sendParamMap = {|params|
    Task({
        params.keys().do({|key|
            if(key.asSymbol != '/senselDraw', {
                ipadMidiOut.control(0, key, params[key]);
                midiOut.control(0, key, params[key]);
                0.001.wait;
            })
        });
    }).play
};

saveParams = {|msg|
    var key = msg[0];
    if(key.asString.contains("playrate") || key.asString.contains("pitch"), { // store adress as as "/i/param", with value being the 1-16 range index
        var val;
        var splits = key.asString.split($/);
        key = "/"++splits[1]++"/"++splits[2];
        val = splits[4].asFloat;
        paramMap[key] = val;
    }, {
        paramMap[key] = msg[1..];             //remember that /volres will be list - use .flatten when re-sending interpolated params
    });
};

//TODO - this does not cleanly handle multiple interpolations running at once - they will cross-cut eachother
startPresetInterpolation = {|targetParams, padNote|
    var hz = 20;
    var maxTime = 4;
    var numSteps = (interpolationSpeed*maxTime*hz).round;
    if(interpolationTask.isNil.not,
        {interpolationTask.stop});
    paramStart = paramMap.deepCopy;
    paramEnd = targetParams.deepCopy;
    setLight.(padNote, padPlaying_COLOR);
    interpolationTask = Pbind(
        \delta, 1/hz,
        \frac, Pseq((0..numSteps)/numSteps),
        \lightIndex, ~lightIndex,
        \play, {
            sendParamMap.(interpolateParamMaps.(paramStart, paramEnd, ~frac));
            if(~frac == 1, {
                ["FINISHED INTERPOLATION", padNote, paramSaved_COLOR].postln;
                setLight.(padNote, paramSaved_COLOR);
                paramMap = paramEnd.deepCopy;
            })
        }
    ).play;
};

(0..99).do({|i| setLight.(i, 0)});


setLight.(loopRecord_BUTTON, notRecording_COLOR);
setLight.(savePreset_BUTTON, notRecording_COLOR);
setLight.(presetVoice1_BUTTON, loopSaved_COLOR);
setLight.(presetVoice2_BUTTON, loopSaved_COLOR);
setLight.(interpSpeed_BUTTONS[0], loopSaved_COLOR);


oscHandler = {|msg, time, addr, recvPort|
    if(isRecording, {
        recordBuffer.add([tempoClock.beats - recordStartTime, msg]); //recording timestamps relative to recoring start
    });
    saveParams.(msg);
    maxOscOut.sendRaw(msg.asArray.asRawOSC);
    visalsOscOut.sendRaw(msg.asArray.asRawOSC);
};

oscAddrs = ['/senselDraw'];

//todo

oscAddrs.do({|addr|
    OSCFunc.new(oscHandler, addr);
});

sendMSG = {|msgArray, loopNumber|
    ["Loop Number", loopNumber].postln;
    if(msgArray[0].asSymbol == 'midi', {
            ipadMidiOut.control(msgArray[1], msgArray[2], msgArray[3]);
            midiOut.control(msgArray[1], msgArray[2], msgArray[3]);
    },{
        var msgCopy = msgArray.deepCopy;
        msgCopy[1] = (loopNumber*16) + msgCopy[1];
        visalsOscOut.sendRaw(msgCopy.asArray.asRawOSC);
    });
};

createLoopPattern = {|recordBuf, loopNumber|
    var playBuff, rb, pat, timeList, msgList;

    //all timestamps are relative to recording start - first event is always at 0
    rb = recordBuf.deepCopy;
    rb.insert(0, [0, ["/recordingStartMessage"]]);
    rb.add([recordEndTime-recordStartTime, ["recordingEndMessage"]]);

    //convert from timeStamp list to deltaTime list - first event - in pattern, first event plays immediately and delta is the wait afterwards
    playBuff = (0..(rb.size-2)).collect({|i| rb[i+1][0]-rb[i][0]}).collect({|it, i| [it, rb[i][1]]});

    timeList = playBuff.collect({|it| it[0]});
    msgList = playBuff.collect({|it| it[1]});

    ["TIME LIST", timeList].postln;
    ["MSG LIST", msgList].postln;

    pat = Pbind(
        \delta, Pseq(timeList, inf),
        \loopMsg, Pseq(msgList, inf),
        \play, {sendMSG.(~loopMsg, loopNumber)}
    ).play(tempoClock);

    pat
};

MIDIFunc.cc({|vel, note, chan, port|
    /*var stepVal = if(vel == 0, 0, 1);
    maxOscOut.sendMsg("/"++(chan+1)++ "/sequencer/1/"++(note+1), stepVal);*/
    paramMap[note] = vel;
    if(isRecording, {
        recordBuffer.add([tempoClock.beats - recordStartTime, ['midi', chan, note, vel]]); //recording timestamps relative to recoring start
    });

}, nil, nil, ipadMidiIn.uid);


controlHandler = {|vel, note, chan, port|
    if((note == loopRecord_BUTTON) && (vel == 127), {
        loopRecordingState = (loopRecordingState + 1) % 3;
        setLight.(loopRecord_BUTTON, recordingStateColors[loopRecordingState]);
        if(loopRecordingState == 0, {
            tempRecordingTask.stop;
            tempRecordingTask.free;
            tempRecordingTask = nil;
            recordBuffer = List.new;
        });
        if(loopRecordingState == 1, {
            isRecording = true;
            recordStartTime = tempoClock.beats;

        });
        if(loopRecordingState == 2, {
            isRecording = false;
            recordEndTime = tempoClock.beats;
            numLoopsRecorded = numLoopsRecorded + 1;
            tempRecordingTask = createLoopPattern.(recordBuffer, numLoopsRecorded);
            recordBuffer = List.new;
        });
    });
    if(interpSpeed_BUTTONS.includes(note) && (vel == 127), {
        interpolationSpeed = note/8;
        interpSpeed_BUTTONS.do({|i| setLight.(i, 0)});
        setLight.(note, loopSaved_COLOR);
    });
    if(note == savePreset_BUTTON, {
        if(vel == 127, {
            savingParams = true;
            setLight.(note, recording_COLOR);
        }, {
            savingParams = false;
            setLight.(note, notRecording_COLOR);
        });
    });
    if((note == syncTempo_BUTTON) && (vel == 127), {
        maxOscOut.sendMsg("/syncTempo", 1);
        ["1 SPEED", paramMap['/1/speed']].postln;
        ipadOscOut.sendMsg("/2/speed", paramMap['/1/speed'][0]); //TODO - all param values are lists - need a clean abstraction for sending to ipad to resolve multival, multislect, normal vals?
    });
    if((note == syncPhase_BUTTON) && (vel == 127), {
        maxOscOut.sendMsg("/syncPhase", 1);
    });
    if((note == dsp_BUTTON) && (vel == 127), {
        dspOn = dspOn.not;
        setLight.(dsp_BUTTON, if(dspOn, loopSaved_COLOR, 0));
        maxOscOut.sendMsg("/dspStatus", if(dspOn, 1, 0));
    });
    if((note == cycleLight_BUTTON) && (vel !=0), {
        // ["MULTILOOP BUTTON CYCLE HIT", ~lightIndex[launchpadIndex], lightIndex].postln;
        if(~cycling, {cycleLight.()})
        // if(~truncateLoop, {setLight.(cycleLight_BUTTON, 45)}, {setLight.(cycleLight_BUTTON, 0)});
        // ~truncateLoop = ~truncateLoop.not; //light on means NOT TRUNCATING
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

saveLoopToBank = {|bankNote|
    loopToPadMap[bankNote] = [bankNote, 'loop', tempRecordingTask];
    tempRecordingTask = nil;
    setLight.(bankNote, padPlaying_COLOR);
    loopRecordingState = 0;
    setLight.(loopRecord_BUTTON, recordingStateColors[loopRecordingState]);
};

MIDIFunc.noteOn({|vel, note, chan, port|
    if(vel != 0,{
        var bank = loopToPadMap[note];
        if(bank.isNil.not, {
            if(loopRecordingState == 2, { //can't save preset if there is a tempRecording
                if(bank[1] == 'loop', {
                    bank[2].stop;
                    bank[2].free;
                });
                saveLoopToBank.(note);
            },{
                "NO TEMP LOOP, NOT NIL".postln;
                if(bank[1] == 'loop', {
                    "LOOP PLAY/STOP".postln;
                    if(bank[2].isPlaying, {bank[2].stop; bank[2].reset},
                        {bank[2].play});
                    setLight.(note, if(bank[2].isPlaying, padPlaying_COLOR, loopSaved_COLOR));
                });

                if(bank[1] == 'preset', {
                    if(savingParams, {
                        "SAVE PARAMS".postln;
                        loopToPadMap[note] = [note, 'preset', paramMap.deepCopy];
                    }, {
                        "LOAD PARAMS".postln;
                        startPresetInterpolation.(bank[2], note);
                    });
                });
            })
        },{
            if(loopRecordingState == 2, {//can't save preset if there is a tempRecording
                saveLoopToBank.(note);
            }, {
                if(savingParams, {
                    "SAVING PARAM TO BLANK BANK".postln;
                    loopToPadMap[note] = [note, 'preset', paramMap.deepCopy];
                    setLight.(note, paramSaved_COLOR);
                    savingParams = false;
                    setLight.(savePreset_BUTTON, notRecording_COLOR);
                });
            });
        });
    });
}, nil, nil, launchpadIn.uid);


paramMap.postln;
~pm = paramMap;
sendParamMap.(paramMap);

)

//save/load data
// ~glData.writeArchive("~/".standardizePath ++ "/paramdict.txt")
// g = Object.readArchive("~/".standardizePath++"paramdict.txt")
// s = ~glData.asCompileString
// s.interpret








// (
//
// var hits = [[1, 1], [3, 2], [4.4, 3]].asList;
// var recordStartTime = 0;
// var recordEndTime = 5;
// var createLoopPattern = {|recordBuf|
//     var playBuff, rb;
//
//     rb = recordBuf.deepCopy;
//     rb.insert(0, [recordStartTime, ["/recordingStartMessage"]]); //todo - test things
//     rb.add([recordEndTime, ["recordingEndMessage"]]);
//     rb.postln;
//     //convert from timeStamp list to deltaTime list - first event - in pattern, first event plays immediately and delta is the wait afterwards
//     playBuff = (0..(rb.size-2)).collect({|i| rb[i+1][0]-rb[i][0]}).collect({|it, i| [it, rb[i][1]]});
//
// };
// createLoopPattern.(hits);
//
// )
//
//
// n = NetAddr("127.0.0.1", 57120)
//
// n.sendMsg("/ad", 10)
//
//
//
//
// [1, 2, 3, 4].unzip
// a = [1, 2, 3,4]
// (0..(a.size-2)).collect({|i| a[i+1]-a[i]}).collect({|it, i| [it, a[i]]})
// a[(0,2..(a.size - a.size.mod(2)))]
// (0,2..(a.size - a.size.mod(2)))
//
// a.select({|item, ind|
//
//     a = Dictionary.new
//     a[5] = 10
//     a.keys.includes(5)
//
//     if(a.isNil.not && {a.asInt != 0}, {7})

(
var launchpad, launchpadOut, maxOscOut, ipadMidiIn, ipadOscOut, loopRecord_BUTTON, presetRecord_BUTTON, recordBuffer, tempRecordingTask, tempLoopColor, loopRecordingState, oscHandler, oscAddrs, isRecording, recordingColor, notRecordingColor, tempRecordColor, loopToPadMap, paramMap, createLoopPattern, tempoClock, recordStartTime, recordEndTime, padSavedColor, padPlayingColor;


ipadMidiIn = ~getMidiIn.("TouchOSC Bridge", "TouchOSC Bridge");
launchpad = ~getLaunchpadIn.(0);
launchpadOut = ~getLaunchpadOut.(1);
launchpadOut.latency = 0;
maxOscOut = NetAddr("127.0.0.1", 8000);
ipadOscOut = NetAddr("10.0.0.17", 9000);


loopRecord_BUTTON = 89;
presetRecord_BUTTON = 79;
recordBuffer = List.new;
tempRecordingTask = nil;
loopRecordingState = 0;
loopToPadMap = Dictionary.new; //[padInd, 'loop'/'preset', pattern/preset-array]
paramMap = Dictionary.new;
tempoClock = TempoClock.new;

recordStartTime = nil;
recordEndTime = nil;
isRecording = false;

recordingColor = 5;
notRecordingColor = 17;
tempRecordColor = 9;
padSavedColor = 3;
padPlayingColor = 18;


(0..100).do({|i| launchpadOut.noteOff(0, i, 0)});


launchpadOut.noteOn(0, loopRecord_BUTTON, notRecordingColor);

oscHandler = {|msg, time, addr, recvPort|
    if(isRecording, {
        recordBuffer.add([tempoClock.beats - recordStartTime, msg]);
    });
    maxOscOut.sendRaw(msg.asArray.asRawOSC);
};

oscAddrs = ["/pos", "/width", "/duration", "/playrate", "/pitch", "/volres", "/q"];

[1, 2].do({|num|
    oscAddrs.do({|addr|
        OSCFunc.new(oscHandler, "/"++num++addr);
        if(["/playrate", "/pitch"].includes(addr), {
            (1..16).do({|i| OSCFunc.new(oscHandler, "/"++num++addr ++ "/1/" ++i);
            });
        });
    });
});

createLoopPattern = {|recordBuf|
    var playBuff, rb, pat, sendOSC, timeList, msgList;

    rb = recordBuf.deepCopy;
    rb.insert(0, [recordStartTime, ["/recordingStartMessage"]]);
    rb.add([recordEndTime, ["recordingEndMessage"]]);

    //convert from timeStamp list to deltaTime list - first event - in pattern, first event plays immediately and delta is the wait afterwards
    playBuff = (0..(rb.size-2)).collect({|i| rb[i+1][0]-rb[i][0]}).collect({|it, i| [it, rb[i][1]]});

    sendOSC = {|oscArray|
        // ["OSC ARRAY", oscArray].postln;
        maxOscOut.sendRaw(oscArray.asArray.asRawOSC);
        ipadOscOut.sendRaw(oscArray.asArray.asRawOSC);
    };

    timeList = playBuff.collect({|it| it[0]});
    msgList = playBuff.collect({|it| it[1]});

    ["TIME LIST", timeList].postln;
    ["MSG LIST", msgList].postln;

    pat = Pbind(
        \delta, Pseq(timeList, inf),
        \oscMsg, Pseq(msgList, inf),
        \play, {sendOSC.(~oscMsg)}
    ).play(tempoClock);

    pat
};

MIDIFunc.cc({|vel, note, chan, port|
    var stepVal = if(vel == 0, 0, 1);
    maxOscOut.sendMsg("/"++(chan+1)++ "/sequencer/1/"++(note+1), stepVal);

}, ipadMidiIn.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if((note == loopRecord_BUTTON) && (vel == 127), {
        var stateColors = [notRecordingColor, recordingColor, tempRecordColor];
        loopRecordingState = (loopRecordingState + 1) % 3;
        launchpadOut.noteOn(0, loopRecord_BUTTON, stateColors[loopRecordingState]);
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
            tempRecordingTask = createLoopPattern.(recordBuffer);
            recordBuffer = List.new;
        });
    })
});

MIDIFunc.noteOn({|vel, note, chan, port|
    if(vel != 0,{
        var bank = loopToPadMap[note];
        if(bank.isNil.not, {
            if(loopRecordingState == 3, { //can't save preset if there is a tempRecording
                if(bank[2] == 'loop', {
                    bank[3].stop;
                    bank[3].free;
                });
                loopToPadMap[note] = [note, 'loop', tempRecordingTask];
                tempRecordingTask = nil;
                launchpadOut.noteOn(0, note, padPlayingColor);
            },{
                if(bank[2] == 'loop', {
                    if(bank[3].isPlaying, {bank[3].stop; bank[3].reset},
                        {bank[3].play});
                    launchpadOut.noteOn(0, note, if(bank[3].isPlaying, padPlayingColor, padSavedColor));
                });
            })
        },{

        });
    });
});


)


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

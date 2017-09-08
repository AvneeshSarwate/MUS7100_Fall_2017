(
var recordBuffer, launchpad, tempoClock, hitListToString, eventListenerTask, eventDetectors, eventDetectionEndpoints, eventSourceExtractors, pythonPort, stringToHitList, midiOut, noteCounter, delayDetector, holdDetector, delayExtractor, holdExtractor, delayDetectorState, lastSilence;

recordBuffer = List.new;
launchPad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
    && (elem.device == "Launchpad Pro")})[0];
tempoClock = TempoClock.new(2);
pythonPort = NetAddr("127.0.0.1", 7100);
midiOut = MIDIOut.newByName("IAC Driver", "Bus 2");


//event detection related variables and parameters
noteCounter = Dictionary.new; //note -> [numDown, initialDownTimestamp]
lastSilence = -1; //the timestamp of the latest noteOff message that resulted in no notes being on
holdType = \note; //either \note or \silence
holdLength = 4; //number of seconds to hold note



holdDetector = {
    var noteHold = tempoClock.beats - noteCounter.values.collect({|val| val[1]}).minItem;
    var silenceTime = tempoClock.beats - lastSilence;
    var hitDetected = false;
    switch(holdType,
        \note, {if(noteHold > holdLength, {hitDetected = true})},
        \silence, {if(silenceTime > holdLength, {hitDetected = true})}
    );
    hitDetected;
}

holdExtractor = {|historyBuf|
    var currentTime = tempoClock.beats;
    var totalHistorySize = historyBuf.size;
    var foundNotes = Set.newFrom(noteCounter.keys);
    var extractedHits = List.new;

}

//Listen to MIDI coming in, record it to a buffer
MIDIFunc.noteOn({|vel, note, chan, port|
    recordBuffer.add([tempoClock.beats, , note, vel, chan, "on"]);

    if(noteCounter.keys.includes(note),
        {noteCounter[note][0] = noteCounter[note][0]+1},
        {noteCounter[note] = [1, tempoClock.beats]}
    );
}, nil, nil, launchpad.uid);

MIDIFunc.noteOff({|vel, note, chan, port|
    recordBuffer.add([tempoClock.beats, , note, vel, chan, "off"]);

    if(noteCounter.keys.includes[note], {
        if(noteCounter[note][0] == 1,
            {noteCounter.removeAt(note)},
            {noteCounter[note][0] = noteCounter[note][0] - 1;}
        );
    });
    if(noteCounter.size == 0, {lastSilence =
}, nil, nil, launchpad.uid);


//helper functions for serializing strings
hitListToString = {|hitBuf|
    var startTime = hitBuf[0][0];
    hitBuf = hitBuf.collect({|hit| [hit[0] - startTime] ++ hit[1..];});
    hitBuf.collect({|item| item.join(",")}).join("-");
};

stringToBuf = {|melString|
    var buf = melString.split($-).collect({|hitString|
        var sp = hitString.split($,);
        [sp[0].asFloat, sp[1].asInt, sp[2].asInt, sp[3].asInt, sp[4]]
    });
    buf
};





//Poll and detect "events" and send relevant musical history to specified event endpoint
eventListenerTask = Task({
    {
        eventDetectors.do({|detector, ind|
            if(detector.(recordBuffer), {
                pythonPort.sendOSC(eventDetectionEndpoints[ind], hitListToString.(eventSourceExtractors[ind].(recordBuffer)));
                //TODO: eventSourceExtractors will be responsible for removing "hanging notes" from extracted history
            })
        });
        0.02.wait;
    }.loop;
});






cleanBuffer = {|oldRecBuf, startBeat, endBeat|

    var hangingNotes = Set.new();
    var recBuf = List.newFrom(oldRecBuf);
    var timeAfterLastHit;


    recBuf.do({|hit| if(hit[0] < startBeat, {hit[0] = startBeat}) });
    recBuf.do({|elem|
        if(elem[4] == "on",
            {hangingNotes.add([elem[1], elem[3]])},
            {hangingNotes.remove([elem[1], elem[3]])})
    });

    hangingNotes.do({|elem| recBuf.add([endBeat-0.01, elem[0], 0, elem[1], "off"])});


    timeAfterLastHit = (recBuf[recBuf.size-1][0].ceil - recBuf[recBuf.size-1][0])

    (recBuf.size-1..1).do({|i| recBuf[i][0] = recBuf[i][0] - recBuf[i-1][0]});
    recBuf[0][0] = recBuf[0][0] - startBeat;

    recBuf;
};

createRecordedTask = {|oldRecBuf|
    var recBuf, newTask;

    recBuf = List.newFrom(oldRecBuf);

    newTask = Task({
        var ind = 0;
        var hit;
        while({ind < recBuf.size}, {
            hit = recBuf[ind];

            hit[0].wait;

            if(hit[4] == "on", {midiOut.noteOn(hit[3], hit[1], hit[2]);});
            if(hit[4] == "off", {midiOut.noteOff(hit[3], hit[1], hit[2])});

            ind = ind+1;
        });
    }, tempoClock);

    newTask;
};

//msg[1] is response melody string
OSCFunc.new({|msg, time, addr, recvPort|
    var hitList = stringToHitList.(msg[1].asString);
    var responseTask = createRecordedTask.(cleanBuffer.(hitList, 0, hitList.wrapAt(-1)[0].ceil));
    responseTask.play;

}, "/playResponse");


)











(

var dic = Dictionary.new;
dic[5] = "yo";
dic.keys.includes(5)
)



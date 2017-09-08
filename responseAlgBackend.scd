(

var recordBuffer, launchpad, tempoClock, hitListToString, eventListenerTask, eventDetectors, eventDetectionEndpoints, eventSourceExtractors, pythonPort, stringToHitList, midiOut;

recordBuffer = List.new;
launchPad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
    && (elem.device == "Launchpad Pro")})[0];
tempoClock = TempoClock.new(2);
pythonPort = NetAddr("127.0.0.1", 7100);
midiOut = MIDIOut.newByName("IAC Driver", "Bus 2");





//Listen to MIDI coming in, record it to a buffer
MIDIFunc.noteOn({|vel, note, chan, port|
    recordBuffer.add([tempoClock.beats, , note, vel, chan, "on"]);
}, nil, nil, launchpad.uid);

MIDIFunc.noteOff({|vel, note, chan, port|
    recordBuffer.add([tempoClock.beats, , note, vel, chan, "off"]);
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
        0.05.wait;
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

    a = [1, 2, 3,4,5]
    a[1..4]++[7]


(1..10).do({|a1, a2, a3| [a1, a2, a3].postln})
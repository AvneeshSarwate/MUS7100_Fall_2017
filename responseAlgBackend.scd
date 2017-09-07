(

var recordBuffer, launchpad, tempoClock, hitListToString, eventListenerTask, eventDetectors, eventDetectionEndpoints, eventSourceExtractors, pythonPort;

recordBuffer = List.new;
launchPad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
    && (elem.device == "Launchpad Pro")})[0];
tempoClock = TempoClock.new(2);
pythonPort = NetAddr("127.0.0.1", 7100);

MIDIFunc.noteOn({|vel, note, chan, port|
    recordBuffer.add([tempoClock.beats, , note, vel, chan, "on"]);
}, nil, nil, launchpad.uid);

MIDIFunc.noteOff({|vel, note, chan, port|
    recordBuffer.add([tempoClock.beats, , note, vel, chan, "off"]);
}, nil, nil, launchpad.uid);

hitListToString = {|hitBuf|
    var startTime = hitBuf[0][0];
    hitBuf = hitBuf.collect({|hit| [hit[0] - startTime] ++ hit[1..];});
    hitBuf.collect({|item| item.join(",")}).join("-");
};

//Listen to MIDI coming in, record it to a buffer
eventListenerTask = Task({

   {
        eventDetectors.do({|detector, ind|
           if(detector.(recordBuffer, {
                pythonPort.sendOSC(eventDetectionEndpoints[ind], hitListToString.(eventSourceExtractors[ind].(recordBuffer)));
            }
        });
        0.05.wait;
    }.loop;

});



)

    a = [1, 2, 3,4,5]
    a[1..4]++[7]


(1..10).do({|a1, a2, a3| [a1, a2, a3].postln})
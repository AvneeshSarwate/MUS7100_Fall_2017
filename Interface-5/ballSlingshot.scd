(
var launchPad, launchpadOut, pythonOSCport, controlHandler, ballSelector, numPadsDown, ballPosition;


//light switching variables
var setLight, ccLights, padColorState, cycleLight, lightIndex, cycleLight_BUTTON, controlHandlerWrapper, masterClockOSCport;

masterClockOSCport = NetAddr("localhost", 57120);
launchpadOut = MIDIOut.new(8); //MIDIOut.newByName("Launchpad Pro", "Standalone Port");
launchpadOut.latency = 0;
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
    if((~lightIndex == lightIndex) || lightIndexOverride, {
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
        ["NEW LIGHT INDEX TRIGGER FROM BALL SLINGSHOT", ~lightIndex].postln;
        masterClockOSCport.sendMsg("/lightsChange", (~lightIndex+1)%~lightIndexes.size);
        0.01.wait;
        ~lightIndex = (~lightIndex+1)%~lightIndexes.size;
    }).play;
};

//msg[1] is lightIndex
OSCFunc({|msg, time, addr, recvPort|
    if(msg[1].asInt == lightIndex, {
        var colorStateLog = List.new(100);
        (0..99).do({|i| colorStateLog.add(0)});
        padColorState.keys.do({|key| setLight.(key, padColorState[key], true);
            colorStateLog[key]=padColorState[key]});
        ["CHANGING TO BALL SLINGSHOT LIGHTS", msg[1], colorStateLog].postln;
    });

}, "/lightsChange");
lightIndex = if(~lightIndexes.size == 0,
    {
        ~lightIndexes.add(0);
        0
    },
    {
        ~lightIndexes.add(~lightIndexes.maxItem+1);
        ~lightIndexes.maxItem
    }
);
~lightIndex = lightIndex;
["LIGHT INDEX SCENEBUILDER", ~lightIndex, lightIndex].postln;
//TODO - add ~lightIndex == lightIndex condition to all launchpad note/cc hanlders
//----------------------------------------------



launchPad = MIDIClient.sources.select({|elem| (elem.name == "Standalone Port")
    && (elem.device == "Launchpad Pro")})[0];

pythonOSCport = NetAddr("localhost", 7400);
masterClockOSCport = NetAddr("localhost", 57120);

ballSelector = List.fill(8, {false});
numPadsDown = 0;
ballPosition = [0, 0];


controlHandler = {|vel, note, chan, port|
    if((1..8).includes(note) && (vel != 0), {
        ballSelector[note-1] = ballSelector[note-1].not;
        if(ballSelector[note-1] ,
            {setLight.(note, 10)},
            {setLight.(note, 0)}
        );
    });
    "NOT BALL".postln;
    if((note == cycleLight_BUTTON) && (vel !=0), {
        ["BALL SLINGSHOT CYCLE HIT", ~lightIndex, lightIndex].postln;
        if(~cycling, {cycleLight.()})
        // if(~truncateLoop, {setLight.(cycleLight_BUTTON, 45)}, {setLight.(cycleLight_BUTTON, 0)});
        // ~truncateLoop = ~truncateLoop.not; //light on means NOT TRUNCATING*/
    });
    "NOT LIGHT CHANGE".postln;
};


MIDIFunc.noteOn({|vel, note, chan, port|
    numPadsDown = numPadsDown + 1;
    if(numPadsDown == 1, {
        ballPosition = [((note%10)-1), (8-(note/10).floor)];
    });
    if(numPadsDown == 2, {
        var velocity = vel/127;
        var ballPos2 = [((note%10)-1), (8-(note/10).floor)];
        var messageData = [ballPosition[0], ballPosition[1], ballPos2[0], ballPos2[1], vel];
        //messageData = messageData ++ (0..7).filter;
        pythonOSCport.sendMsg("/slingshot", ballPosition[0], ballPosition[1], ballPos2[0], ballPos2[1]);
    });

}, nil, nil, launchPad.uid);

MIDIFunc.noteOn({|vel, note, chan, port|
    numPadsDown = numPadsDown - 1;

}, nil, nil, launchPad.uid);

controlHandlerWrapper = {|vel, note, chan, port|
    ~lock.wait;
    if((chan == 0) && (~lightIndex == lightIndex) && (vel != 0), {
        //["LIGHT INDEX MULTILOOP", ~lightIndex, lightIndex, SystemClock.beats].postln;
        controlHandler.(vel, note, chan, port)
    });
    ~lock.signal;
};
MIDIFunc.cc(controlHandlerWrapper, nil, nil, launchPad.uid);

)
(
var launchPad, launchpadOut, nodeOSCport, controlHandler, ballSelector, numPadsDown, ballPosition;

//quneo variables
var ccX, ccY, ccP, ccToInd, isPadCC, quneoCCMap, isPadNote, noteToInd, quneo;

//light switching variables
var setLight, ccLights, padColorState, cycleLight, lightIndex, cycleLight_BUTTON, controlHandlerWrapper, masterClockOSCport;

masterClockOSCport = NetAddr("localhost", 57120);
launchpadOut = ~getLaunchpad.(0); //MIDIOut.newByName("Launchpad Pro", "Standalone Port");
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


nodeOSCport = NetAddr("localhost", 7400);
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
        ["BALL", note, ballSelector[note-1]].postln;
    });
    if((note == cycleLight_BUTTON) && (vel !=0), {
        ["BALL SLINGSHOT CYCLE HIT", ~lightIndex, lightIndex].postln;
        if(~cycling, {cycleLight.()})
        // if(~truncateLoop, {setLight.(cycleLight_BUTTON, 45)}, {setLight.(cycleLight_BUTTON, 0)});
        // ~truncateLoop = ~truncateLoop.not; //light on means NOT TRUNCATING*/
    });
    ["NOT LIGHT CHANGE", note].postln;
};


MIDIFunc.noteOn({|vel, note, chan, port|
    if((chan == 0) && (~lightIndex == lightIndex), {
        numPadsDown = numPadsDown + 1;
        ["NOTE ON lp", numPadsDown, note, vel].postln;
        if(numPadsDown == 1, {
            ballPosition = [((note%10)-1), (8-(note/10).floor)];
        });
        if(numPadsDown == 2, {
            var velocity = vel/127;
            var ballPos2 = [((note%10)-1), (8-(note/10).floor)];
            var messageData = [ballPosition[0], ballPosition[1], ballPos2[0], ballPos2[1], vel];
            messageData = messageData ++ ballSelector.collect({|val, ind| if(val, ind, nil)}).select({|val| val.isNil.not});
            messageData.postln;
            nodeOSCport.sendRaw((["/slingshot"] ++ messageData).asArray.asRawOSC);
        });
    });

}, nil, nil, launchPad.uid);


MIDIFunc.noteOff({|vel, note, chan, port|
    if((chan == 0) && (~lightIndex == lightIndex), {
        numPadsDown = numPadsDown - 1;
        ["NOTE OFF lp", numPadsDown, note, vel].postln;
    });
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





/*
output messages

the launchpad controller sends the following messages
/slingshot
-    arg 0,1,2,3,4,5 - int,int,int,int,float - x1, y1, x2, y2, speed, balls
-          args 0-3 are [0-7], arg[4] is [0,1]


the quneo controller sends the following messages
/gravity
-     arg 0 - 'on'/'off'/'update'
-     arg 1 - int - the index [0-15] of which pad is pressed, basically a gravityWellID
-     arg 2,3,4 (only if arg[0]=='update' - int,int,int the x/y/pressure in range [0-127[


*/







//QUNEO STUFF
quneo = MIDIClient.sources.select({|elem| (elem.name == "QUNEO")
    && (elem.device == "QUNEO")})[0];

ccP = {|x| (x%3) == 2}; //check if cc is pressure value
ccX = {|x| (x%3) == 0}; //check if cc is x position
ccY = {|x| (x%3) == 1}; //check if cc is y position
noteToInd = {|x| x - 36}; //convert note to pad index
//noteToXY = {|x| [noteToInd.(x)%4, floor(noteToInd.(x)/4)]}; //convert note to pad xy (bottom left 0,0)
ccToInd = {|x| floor((x-23)/3)}; //convert cc number to pad index
//ccToXY = {|x| [(ccToInd.(x)%4), floor(ccToInd.(x)/4)]}; //convert cc number to pad xy
isPadCC = {|x| (ccToInd.(x) >=0) && (ccToInd.(x) < 16)};
isPadNote = {|x| (noteToInd.(x) >=0) && (noteToInd.(x) < 16)};
//isBankNote = {|x| (x > 10) && (x < 19)};
//bankToInd = {|x| x-11};
quneoCCMap = Dictionary.new;

~map = quneoCCMap;
p = ccP;
x = ccX;
y = ccY;
~ind = ccToInd;
~printCC = {

};


MIDIFunc.noteOn({|vel, note, chan, port|
    if(isPadNote.(note), {
        nodeOSCport.sendMsg("/gravity", "on", noteToInd.(note));
    });
}, nil, nil, quneo.uid);

MIDIFunc.noteOff({|vel, note, chan, port|
    if(isPadNote.(note), {
        nodeOSCport.sendMsg("/gravity", "off", noteToInd.(note));
    });
}, nil, nil, quneo.uid);

MIDIFunc.cc({|vel, note, chan, port|
    if(isPadCC.(note), {
        var arr;
        if(quneoCCMap[ccToInd.(note)].isNil, {
           quneoCCMap[ccToInd.(note)] = [0, 0, 0];
        });
        arr = quneoCCMap[ccToInd.(note)];
        if(ccX.(note), {arr[0] = vel});
        if(ccY.(note), {arr[1] = vel});
        if(ccP.(note), {arr[2] = vel});
        nodeOSCport.sendMsg("/gravity", "update", ccToInd.(note), arr[0], arr[1], arr[2]);
        ["GRAV", ccToInd.(note), arr].postln;
    });

},nil, nil, quneo.uid);



)
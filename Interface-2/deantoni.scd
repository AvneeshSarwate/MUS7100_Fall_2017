(
var midiOut = MIDIOut.newByName("IAC Driver", "Bus 7");


var offColor = 53;
var onColor = 27;

var launchpadIndex = 1;
var launchpadOut = ~getLaunchpadOut.(launchpadIndex);
var launchPad = ~getLaunchpadIn.(launchpadIndex);
var controlHandler, controlHandlerWrapper;
//light switching variables
var setLight, ccLights, padColorState, cycleLight, lightIndex, cycleLight_BUTTON;

var drumNotes = List.new;
var masterClockOSCport = NetAddr("localhost", 57120);
var velAndCCParamCoordinator = Dictionary.new;
var buttonForwardingButton = 96;
var buttonForwarding = false;
var pythonOSCport = NetAddr("localhost", 13371);

(0..127).do({|i|
    velAndCCParamCoordinator[i] = [false, 0];
});

midiOut.latency = 0;
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
        ["NEW LIGHT INDEX TRIGGER FROM DEANTONI", ~lightIndex[launchpadIndex]].postln;
        masterClockOSCport.sendMsg("/lightsChange", (~lightIndex[launchpadIndex]+1)%~lightIndexes[launchpadIndex].size);
        0.01.wait;
        ~lightIndex[launchpadIndex] = (~lightIndex[launchpadIndex]+1)%~lightIndexes[launchpadIndex].size;
    }).play;
};

//msg[1] is lightIndex
OSCFunc({|msg, time, addr, recvPort|
    if(msg[1].asInt == lightIndex, {
        var colorStateLog = List.new(100);
        (0..99).do({|i| colorStateLog.add(0)});
        padColorState.keys.do({|key| setLight.(key, padColorState[key], true);
            colorStateLog[key]=padColorState[key]});
        ["CHANGING TO DEANTONI LIGHTS", msg[1], colorStateLog].postln;
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
["LIGHT INDEX SCENEBUILDER", ~lightIndex[launchpadIndex], lightIndex].postln;
//TODO - add ~lightIndex[launchpadIndex] == lightIndex condition to all launchpad note/cc hanlders
//----------------------------------------------




(4..8).do({|i| (1..4).do({|j| drumNotes.add((i*10)+j)})});

drumNotes.do({|i| setLight.(i, offColor)});

~ccVelLearn = false;
~ccPressureLearn = false;

a = {|vel, note, chan, port|
    if(drumNotes.includes(note), {
        setLight.(note, onColor);
        if(buttonForwarding,
            {pythonOSCport.sendMsg("/buttonForwarding", 5, 48+drumNotes.indexOf(note), vel, "on", note)},
            {
                if(~ccPressureLearn.not, {


                    var pressureNote = (note/10).floor;
                    var ccId = if(pressureNote == 4, pressureNote, 48+drumNotes.indexOf(note));
                    var ccChan = if(pressureNote == 4, 3, 2);
                    velAndCCParamCoordinator[ccId] = [false, vel];
                    midiOut.control(ccChan, ccId, vel);
                });
                if(~ccVelLearn.not && ~ccPressureLearn.not, {
                    midiOut.noteOn(5, 48+drumNotes.indexOf(note), vel);

                });
            }
        );
    });
};
MIDIFunc.noteOn(a, nil, nil, launchPad.uid);


b = {|vel, note, chan, port|
    // midiOut.control(chan, 1, vel);
    if(drumNotes.includes(note), {
        setLight.(note, offColor);
        if(buttonForwarding,
            {pythonOSCport.sendMsg("/buttonForwarding", 5, 48+drumNotes.indexOf(note), vel, "off", note)},
            {if(~ccVelLearn.not && ~ccPressureLearn.not, {midiOut.noteOff(5, 48+drumNotes.indexOf(note), vel)})}
        );
    });
};
MIDIFunc.noteOff(b, nil, nil, launchPad.uid);


d = {|vel, note, chan, port|
    if(drumNotes.includes(note), {
        var pressureNote = (note/10).floor;
        if(~ccVelLearn.not, {
            if(pressureNote == 4,
                {
                    if(((vel - velAndCCParamCoordinator[pressureNote][1]).abs < 5) || (velAndCCParamCoordinator[pressureNote][0] == true),
                        {velAndCCParamCoordinator[pressureNote][0] = true});
                    if(velAndCCParamCoordinator[pressureNote][0] == true, {midiOut.control(3, pressureNote, vel)});
                },
                {
                    midiOut.control(3, pressureNote, vel);
                }
            );

        });
    });
};
MIDIFunc.polytouch(d, nil, nil, launchPad.uid);








controlHandler = {|vel, note, chan, port|
    if((note == cycleLight_BUTTON) && (vel !=0), {
        // ["MULTILOOP BUTTON CYCLE HIT", ~lightIndex[launchpadIndex], lightIndex].postln;
        if(~cycling, {cycleLight.()})
    });
    if((note == buttonForwardingButton) && (vel == 127), {
		buttonForwarding = buttonForwarding.not;
		if(buttonForwarding,
			{setLight.(buttonForwardingButton, 81)},
			{setLight.(buttonForwardingButton, 0)}
		);
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
MIDIFunc.cc(controlHandlerWrapper, nil, nil, launchPad.uid);



)


(
var midiOut = MIDIOut.newByName("IAC Driver", "Bus 2");
midiOut.control(2, 2, 10);
)

[1, 2, 3].indexOf(3)
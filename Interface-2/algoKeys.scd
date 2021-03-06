//env vars for control
/*(
~truncateLoop = false;
~vjQuadPad = true;
)
~vjQuadPad.isNil.not &&  ~vjQuadPad
if(~vjQuadPad.isNil.not &&  ~vjQuadPad , 5, 6)*/
//ACTIVE TODO TAGS: sceneBuilderInterop
//

(
var launchpadOut, padTL, padBL, padTR, padBR, colorBL1, colorBR1, colorTL1, colorTR1, colorBL2, colorBR2, colorTL2, colorTR2, colorON, pads, padMap, madePadList, scales, roots, padOn, padOff, setPadLights, transposes, makePadList, indToNote_, indToNote, midiOut, launchPad, tempoClock, interruptLoopButtons, controlChanInd, tapTempoSetButton, tapTempoToggle, recordButton, lastTap, playMetronome, recordingMetronome, metronomeFunc, preRecordCount, preRecordLength, recordBuffer, color1, tlBanks, trBanks, blBanks, brBanks, banks, bankMap, recordingState, bankSet, bankToSaveTo, bankToRecording, recordColor, tempLoopTask, tempLoopString, createRecordedTask, playingBanks, metronomeFlashTask, recordingInterim, resetRecordingState, interruptLooping, controlChanButton, arrowButtons, color2, up, down, left, right, padsByChannel, recordingStartBeat, recordingEndBeat, truncateLoop, quantize, algOrderList, pythonOSCport, algResponseHandler, algButtons, quantizationLevels, algBanks, liveCodeHandler, newKeyButton, masterClockOSCport, masterClockTempoHandler, onDeckBuffers, algChannelsInfo, recieveBuffer, startChannel, stringToBuf, stopChannel, rootScaleHandler, newKeysTransposes, newKeysPadIndToNote, newKeysSetPadLights, playingNewKeys, newKeysChan, hitListToNoteList, noteListToHitList, quantizeButton, quantizeColor, quantized, controlHandler, masterClockBeatHandler, setBankMelody, receiveScene, tempoalignTempoButton, alignTempo, buttonForwarding, buttonForwardingButton, metronomeOut, padIndToColor, moduleLights, controlHandlerWrapper, processPort;
var launchpadIndex = 0;
//light switching variables
var setLight, ccLights, padColorState, cycleLight, lightIndex, cycleLight_BUTTON;

launchpadOut = ~getLaunchpadOut.(launchpadIndex);
["GOT LAUNCHPAD", launchpadOut].postln;
launchpadOut.latency = 0;
midiOut = MIDIOut.newByName("IAC Driver", "Bus 7");
metronomeOut = MIDIOut.newByName("IAC Driver", "Bus 3");
midiOut.latency = 0;
metronomeOut.latency = 0;
pythonOSCport = NetAddr("localhost", 13371);
masterClockOSCport = NetAddr("localhost", 57120);
processPort = NetAddr("localhost", 12345);


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
        ["NEW LIGHT INDEX TRIGGER FROM ALGKEYS", ~lightIndex[launchpadIndex]].postln;
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
        ["CHANGING TO ALGOKEYS LIGHTS", msg[1], colorStateLog].postln;
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
["LIGHT INDEX ALGOKEYS", ~lightIndex[launchpadIndex], lightIndex].postln;
//TODO - add ~lightIndex[launchpadIndex] == lightIndex condition to all launchpad note/cc hanlders
//----------------------------------------------





//OPTIONS
preRecordLength = 0;
~truncateLoop = true;
quantizationLevels = [3,4];




a = [1, 2, 3, 4];
b = [5, 6, 7, 8];

pads = Set.new();
padMap = Dictionary.new(); //launchpad-midiNote -> (padInd, channelInd)

makePadList = {|n1, n2, chan|
	var lis = List.new();
	k = 0;
	n1.do({|i| n2.do({|j|
		lis.add((i*10)+j);
		pads.add((i*10)+j);
		padMap.put((i*10)+j, [k, chan]);
		k = k+1;
	})});
	lis
};

algOrderList = List.new();

recordBuffer = List.new(200);

padTL = makePadList.(b, a, 0);
padTR = makePadList.(b, b, 1);
padBL = makePadList.(a, a, 2);
padBR = makePadList.(a, b, 3);
padsByChannel = [padTL, padTR, padBL, padBR];

(pads - padMap.keys()).postln;

colorTL1 = 39;
colorTR1 = 112;
colorBL1 = 4;
colorBR1 = 83;
color1 = [colorTL1, colorTR1, colorBL1, colorBR1];
l = color1;

colorTL2 = 25;
colorTR2 = 45;
colorBL2 = 72;
colorBR2 = 13;
color2 = [colorTL2, colorTR2, colorBL2, colorBR2];

padIndToColor = Dictionary.new();

colorON = 13;

tlBanks = [50, 60, 70, 80];
trBanks = [59, 69, 79, 89];
blBanks = [10, 20, 30, 40];
brBanks = [19, 29, 39, 49];
banks = [tlBanks, trBanks, blBanks, brBanks];
k = banks;
bankSet = Set.new();
bankSet.addAll(banks.flatten(1));
//midiNote -> [bankInd, bankChan, isOn, loopTask/nil, loopString, algMelodyTask, algMelodyString]
bankMap = Dictionary.new();
(0..3).do({|i| (0..3).do({|j|
	//setLight.(j, color1[i]);
	bankMap.put(banks[i][j], [j, i, false, nil, nil, nil, nil]); //TODO: reverse i,j here and everywhere else
})});
z = bankMap;
bankSet.do({|i| setLight.(i, 0)});
playingBanks = Set.new();
algBanks = List.new();

//chanInd -> [isOn, task, loopString]
(0..3).do({|i|
	algBanks.add([false, nil, nil]);
});


//define scales and roots
scales = [
	[0, 2, 3, 5, 7, 8, 10], //TL
	[0, 2, 3, 5, 7, 8, 10], //TR
	[0, 2, 3, 5, 7, 8, 10], //BL
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], //BR
];
roots = [60, 60, 48, 36];

indToNote_ = {|ind, scale, root, trans|
	root + scale[(ind+trans)%scale.size()] + (((ind+trans) / scale.size).floor * 12);
};

indToNote = {|ind, chan| indToNote_.(ind, scales[chan], roots[chan], transposes[chan])};

transposes = [-1, 4, -12, 0 ]; //+- 4 corresponds to up/down a row, +-1 corresponds to left/right a column

quantizeButton = 97;
quantizeColor = 8;
quantized = false;

buttonForwardingButton = 96;
buttonForwarding = false;

//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
//newKeyboard stuff
newKeysTransposes = [-12, -12, -12, -12];  //+- 5 for vertical, +- 1 for horizontal

newKeyButton = 98;

playingNewKeys = false;

newKeysChan = 0;
//TODO - rename ctrlChanInd variable - it is actually newKeysChan
newKeysPadIndToNote = {|padInd, ctrlChanInd|
	var ind = padInd - 11;
	var noteInd, note;
	if(padInd >  18,
		{noteInd = (ind-(((ind/10).floor)*5))},
		{noteInd = ind}
	);
	note = roots[ctrlChanInd] + noteInd + newKeysTransposes[ctrlChanInd];
	//["NOTE-IND", ind,noteInd, note].postln;
	note;
};

newKeysSetPadLights = {|ctrlChanInd|
	var root = roots[ctrlChanInd];
	var scale = scales[ctrlChanInd];
	(1..8).do({|i|
		(1..8).do({|j|
			var ind = i*10 + j;
			var note = newKeysPadIndToNote.(ind, ctrlChanInd);
			var isRoot = (note%12) == (root%12);
			var floorRoot = note - (((note%12) - (root%12)) % 12);
			var isInScale = scale.collect({|n| floorRoot + n}).includes(note);
            var moduleLight;
			//["LIGHT", note, isInScale, isRoot, scale.collect({|n| floorRoot + n}).includes(note), scale.collect({|n| floorRoot + n})].postln;
			if(isInScale && isRoot.not, {
				setLight.(ind, color1[ctrlChanInd]);
				padIndToColor[ind] = color1[ctrlChanInd];
			});
			if(isRoot, {
				setLight.(ind, color2[ctrlChanInd]);
				padIndToColor[ind] = color2[ctrlChanInd];
			});
			if(isInScale.not, {
				setLight.(ind, 0);
				padIndToColor[ind] = 0;
			});
            moduleLight = ~moduleLightsPerChannel[ctrlChanInd][ind];
            if(moduleLight.isNil.not, {setLight.(ind, moduleLight)});
		});
	});
};
//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------

//(note%12 - root%12)%12

//TODO: this feature isn't triggerable
tempoalignTempoButton = 100;
alignTempo = false;

arrowButtons = [91, 92, 93, 94];
up = 91;
down = 92;
right = 93;
left = 94;

interruptLoopButtons = [1, 2, 3, 4];
interruptLooping = [false, false, false, false, false];
setLight.(1, colorTL1);
setLight.(2, colorTR1);
setLight.(3, colorBL1);
setLight.(4, colorBR1);

controlChanInd = 0;
controlChanButton = 8;
setLight.(controlChanButton, color1[controlChanInd]);

onDeckBuffers = List.fill(16, {nil;});

//[task, midiChanInd]
algChannelsInfo = List.fill(16, {[nil, nil];});


//define setPadLights method
setPadLights = {|padMIDIs, c1, c2, padInd|
	(0..15).do({|i|
		var col;
		if(((i+transposes[padInd]) % scales[padInd].size) == 0, {col = c2}, {col = c1});
		setLight.(padMIDIs[i], col);
		padIndToColor[padMIDIs[i]] = col;
	});
};

setPadLights.(padTL, colorTL1, colorTL2, 0);
setPadLights.(padTR, colorTR1, colorTR2, 1);
setPadLights.(padBL, colorBL1, colorBL2, 2);
setPadLights.(padBR, colorBR1, colorBR2, 3);

launchPad = ~getLaunchpadIn.(launchpadIndex);
[launchPad, MIDIClient.sources[2]].postln;
a = {|vel, note, chan, port|
    if((chan == 0) && (~lightIndex[launchpadIndex] == lightIndex), {
        //["LIGHT INDEX MULTILOOP", ~lightIndex[launchpadIndex], lightIndex].postln;
		if(pads.includes(note), {
			var chan, newNote;
			if(playingNewKeys,
				{
					newNote = newKeysPadIndToNote.(note, newKeysChan);
					chan = newKeysChan;
				},
				{
					var padInfo = padMap[note];
					newNote = indToNote.(padInfo[0], padInfo[1]);
					chan = padInfo[1];
				}
			);
			if(buttonForwarding && (controlChanInd == chan),
				{pythonOSCport.sendMsg("/buttonForwarding", chan, newNote, vel, "on", note)},
				{
                    if(~vjQuadPad.isNil.not &&  ~vjQuadPad, {midiOut.noteOn(chan, padMap[note][0], vel)}, {midiOut.noteOn(chan, newNote, vel)})

                }
			);
			if(recordingMetronome, {recordBuffer.add([tempoClock.beats, newNote, vel, chan, "on"])});
		});
	});
};
padOn = MIDIFunc.noteOn(a, nil, nil, launchPad.uid);

b = {|vel, note, chan, port|
	if((chan == 0) && (~lightIndex[launchpadIndex] == lightIndex), {
        //["LIGHT INDEX MULTILOOP", ~lightIndex[launchpadIndex], lightIndex].postln;
		if(pads.includes(note), {
			var chan, newNote;
			if(playingNewKeys,
				{
					newNote = newKeysPadIndToNote.(note, newKeysChan);
					chan = newKeysChan;
				},
				{
					var padInfo = padMap[note];
					newNote = indToNote.(padInfo[0], padInfo[1]);
					chan = padInfo[1];
				}
			);

			if(buttonForwarding && (controlChanInd == chan),
				{pythonOSCport.sendMsg("/buttonForwarding", chan, newNote, vel, "off", note)},
				{
                    if(~vjQuadPad.isNil.not &&  ~vjQuadPad, {midiOut.noteOff(chan, padMap[note][0], vel)}, {midiOut.noteOff(chan, newNote, vel)})
                }
			);
			if(recordingMetronome, {recordBuffer.add([tempoClock.beats, newNote, vel, chan, "off"])});
		});
	});
};
padOff = MIDIFunc.noteOff(b, nil, nil, launchPad.uid);
x = 0;
tempLoopTask = nil; //this var is only not nil when you have a recorded and unsaved loop
tempLoopString = nil;


//TODO: move variable instations to near the functions that use them
OSCFunc({|msg, time, addr, recvPort|
	//msg[1] is the new BEAT DURATION (not tempo)
	tempoClock = TempoClock.new(1/msg[1], 0);
	//t = tempoClock;
	tempoClock.schedAbs(1, metronomeFunc);
	"MULTILOOP ONE SHOT".postln;
}, "/masterClockBeat").oneShot;
masterClockBeatHandler = {|msg, time, addr, recvPort|
	//["MULTILOOP BEAT", tempoClock.beats].postln;
};

//msg[1] is the new tempoIn BEATS PER SECOND
//msg[2] is the phase
OSCFunc({|msg, time, addr, recvPort|
	tempoClock.tempo = msg[1].asFloat;
    tempoClock.beats = tempoClock.beats.floor + msg[2].asFloat;
}, "/masterClockLinkUpdate");

OSCFunc(masterClockBeatHandler, "/masterClockBeat");
tapTempoSetButton = 5;
tapTempoToggle = 6;
recordButton = 7;
recordColor = 5;
setLight.(recordButton, recordColor);
setLight.(quantizeButton, 0);
lastTap = TempoClock.beats;
playMetronome = false;
recordingMetronome = false;
recordingInterim = false;
preRecordCount = 0;
//0: not recording, 1: pre record metronome, 2: recording notes 3:stopped recording and tempBuffer full
recordingState = 0;
bankToSaveTo = 0;
bankToRecording = Dictionary.new();
controlHandler = {|vel, note, chan, port|
	if(interruptLoopButtons.includes(note), {
		var chan = note - interruptLoopButtons[0];
		if((vel == 127), {midiOut.allNotesOff(chan)});
		interruptLooping[chan] = vel == 127;
	});
	if((note == tapTempoSetButton) && (vel == 127), {
		var now = TempoClock.beats;
		if((now - lastTap) < 2, {masterClockOSCport.sendMsg("/uploadTempo", now - lastTap, alignTempo)});
		lastTap = now;
	});
	if((note == tempoalignTempoButton) && (vel == 127), {
		alignTempo = alignTempo.not;
		if(alignTempo,
			{setLight.(tempoalignTempoButton, 81)},
			{setLight.(tempoalignTempoButton, 0)}
		);
	});
	if((note == buttonForwardingButton) && (vel == 127), {
		buttonForwarding = buttonForwarding.not;
		if(buttonForwarding,
			{setLight.(buttonForwardingButton, 81)},
			{setLight.(buttonForwardingButton, 0)}
		);
        ["MULTI LOOP 96", ~lightIndex[launchpadIndex]].postln;
	});
	if((note == tapTempoToggle) && (vel == 127), {playMetronome = playMetronome.not});
	if((note == recordButton) && (vel == 127), {
        midiOut.control(chan, 89, vel); //This is the record button in sceneBuilder
        if(recordingState == 0, {
            recordingState = 1;
            recordingMetronome = true;
			preRecordCount = 0;
            "RECORD TRANSITION 0->1".postln;
        });
        if(recordingState == 3, {resetRecordingState.()});
        if(recordingState == 2, {recordingState = 3; "RECORD TRANSITION 2->3".postln;});
	});

	if((note == controlChanButton) && (vel == 127), {
		controlChanInd = (controlChanInd+1) % 4;
		setLight.(controlChanButton, color1[controlChanInd]);
		newKeysChan = controlChanInd;
		if(playingNewKeys, {newKeysSetPadLights.(controlChanInd)});
		//todo - turn off note if swapping between different channels on newKeys or to/from newKeys to old
	});
	if((note == newKeyButton) && (vel == 127), {
		//Todo newKeys - activate lighting wrt to the chan specified by controlChanButton
        ["NEW KEY SWAP"].postln;
		if(playingNewKeys,
			{
				playingNewKeys = false;
				(0..3).do({|i|
					setPadLights.(padsByChannel[i], color1[i], color2[i], i);
				});
			},
			{
				playingNewKeys = true;
				newKeysChan = controlChanInd;
				newKeysSetPadLights.(controlChanInd);
			}
		);
	});
	if(arrowButtons.includes(note) && (vel == 127), {
		//todo: note off all for that instrument
		//Todo newKeys - lighting shift
		if(playingNewKeys,
			{
				var ind = newKeysChan;
				if(note == up, {newKeysTransposes[ind] = newKeysTransposes[ind] - 5});
				if(note == down, {newKeysTransposes[ind] = newKeysTransposes[ind] + 5});
				if(note == right, {newKeysTransposes[ind] = newKeysTransposes[ind] + 1});
				if(note == left, {newKeysTransposes[ind] = newKeysTransposes[ind] - 1});
				newKeysSetPadLights.(ind);
			},
			{
				var ind = controlChanInd;
				if(note == up, {transposes[ind] = transposes[ind] - 4});
				if(note == down, {transposes[ind] = transposes[ind] + 4});
				if(note == right, {transposes[ind] = transposes[ind] + 1});
				if(note == left, {transposes[ind] = transposes[ind] - 1});
				setPadLights.(padsByChannel[ind], color1[ind], color2[ind], ind);
			}
		);
	});
	//MULTIPLE ALG BUTTONS CAN BE HELD DOWN
	//THEIR ORDER WILL SPECIFY A "pipeline" of transformations
	//if alg button, add/remove from list depending on button up/down
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
MIDIFunc.cc(controlHandlerWrapper, nil, nil, launchPad.uid);


OSCFunc({|msg, time, addr, recvPort|
    resetRecordingState.();
}, "/resetRecordingState_algKeys");


OSCFunc({|msg, time, addr, recvPort|
    pythonOSCport.sendMsg("/saveMetaInfo", "quadKeyboard", roots.join(","), scales.collect({|scale| scale.join(",")}).join(".")) ;
}, "/metaInfoSaveRequest");

///msg[1, 2, 3] is [root:int, scale:, joined Str of Ints, chan:int]
rootScaleHandler = {|msg, time, addr, recvPort|
	msg[2].postln;
	roots[msg[3].asInt] = msg[1].asInt;
	scales[msg[3].asInt] = msg[2].asString.split($,).collect({|str| str.asInt});
	//TODO - add changing pad coloring upon reciept of scale
	if(playingNewKeys,
		{newKeysSetPadLights.(controlChanInd)},
		{(0..3).do({|i| setPadLights.(padsByChannel[i], color1[i], color2[i], i)})}
	);
	["root-Scale Change", msg[1].asInt, scales[msg[3].asInt]].postln;
};
OSCFunc(rootScaleHandler, "/rootScale");


resetRecordingState = {
    recordingMetronome = false;
    recordingState = 0;
    setLight.(recordButton, recordColor);
    recordBuffer.clear();
    tempLoopTask = nil;
    tempLoopString = nil;
};

metronomeFlashTask = Task({
	if(recordingMetronome || (tempLoopTask != nil),
		{setLight.(recordButton, (recordingState==2).if(17,recordColor))});
	playingBanks.do({|bNote| setLight.(bNote, color1[bankMap[bNote][1]])});
	(tempoClock.beatDur/2).wait;
	if(recordingMetronome || (tempLoopTask != nil), {setLight.(recordButton, 0)});
	playingBanks.do({|bNote| setLight.(bNote, 0)});
});

metronomeFunc = {
	//"PAD METRONOME FUNC".postln;
	metronomeFlashTask.start;
	if(recordingMetronome, {
		if((preRecordCount < preRecordLength),
			{
				recordingInterim = true;
				preRecordCount = preRecordCount + 1;
				["prerecordMetronome", preRecordCount].postln;
			},
			{//TODO: clean up and write comments for recroding state handling
				if(recordingState == 1, {
					recordingState = 2;
					recordingStartBeat = tempoClock.beats.round;
                    "RECORD TRANSITION 1->2".postln;
				});
				recordingInterim = false;
				"RECORDING ALGO KEYS".postln;
			}

		);
	});
	//["beat", tempoClock.beats, tempoClock.beatDur].postln;
	1;
};


/*
general idea - multiPadLooper can expose info about basic pad color state (eg, padToColorMap and
padToNote/ChanMap),but module is responsible for managing its own color state. pad could push events
(eg, keyboard scrolling, switching btw quad/extended keyboards, switching inst on extended)
to let module recolor as necessary. Upon event occuring, keyboard will recolor first
(thus updating padToColorMap), and then module will update lights afterwards.
TODO - add event broadcasting for multiPadLooper color state change.
*/
// msg [addr, padInd, color(-1 if revert to old), repeated]
~basePadColors = padIndToColor;

//best practice is to only have 1 hyperkeyboard that changes pad-lighting at a time
//nil value means no special module lighting for that key
~moduleLightsPerChannel = Dictionary.new;
(0..3).do({|i|
    ~moduleLightsPerChannel[i] = Dictionary.new;
});
//msg = [addr, key, color, chanInd]
moduleLights = {|msg, time, addr, recvPort|
	//["MODULE LIGHTS", msg].postln;
	(1,3..(msg.size-2)).do({|i|
		if(msg[i+1] > 0,
			{
                if(playingNewKeys && (controlChanInd == msg[3].asInt), {setLight.(msg[i], msg[i+1])});
                ~moduleLightsPerChannel[msg[3].asInt][msg[i]] = msg[i+1];
            },
			{
                if(playingNewKeys && (controlChanInd == msg[3].asInt), {setLight.(msg[i], padIndToColor[msg[i]])});
                ~moduleLightsPerChannel[msg[3].asInt][msg[i]] = nil;
            }
		);
	})
};
OSCFunc(moduleLights, "/moduleLights");

)
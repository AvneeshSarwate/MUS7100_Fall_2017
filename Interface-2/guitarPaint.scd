(
//todo - replace these with local variables so that play-functions on send__Pat patterns are closures
var brushSpeed = 0;
var brushAngle = 0;
var maxBrushSpeed = 10;
var jsPort = NetAddr("localhost", 5432);
var midiIn = ~getMidiIn.("QuNexus", "Port 1");

~hz = 60;

~noteQueue = List.fill(1, {0});

//attack-decay envelope
~speedEnv = {|attackRatio, time, peak|
    var numSteps = time * ~hz;
    var aRamp = List.fill((attackRatio*numSteps).floor, {peak})/(attackRatio*numSteps).floor;
    var dRamp = List.fill(((1-attackRatio)*numSteps).ceil, {-1*peak})/((1-attackRatio)*numSteps).ceil;
    var pat = Pbind(
        \delta, 1/~hz,
        \increment, Pseq(aRamp++dRamp),
        \play, {brushSpeed = brushSpeed + ~increment}
    );
    pat.play;
    pat
};

~sendSpeedPat = Pbind(
    \delta, Pseq([1/60], inf),
    \play, {jsPort.sendMsg("/brushSpeed", min(max(brushSpeed, -1*maxBrushSpeed), maxBrushSpeed))}
);
~sendSpeedPat.play;

~sendAnglePat = Pbind(
    \delta, Pseq([1/60], inf),
    \play, {jsPort.sendMsg("/brushAngle", brushAngle)}
);
~sendAnglePat.play;

~angleEnv = {|time, maxAngle, maxInterval|
    var interval = ~noteQueue.wrapAt(-1) - ~noteQueue.wrapAt(-2);
    var clippedInterval = min(maxInterval, abs(interval)) * sign(interval);
    var angle = (clippedInterval/maxInterval) * maxAngle;
    var pat = Pbind(
        \delta, 1/~hz,
        \increment, Pseq(List.fill((time*~hz).floor, {angle})/(time*~hz).floor),
        \play, {brushAngle = brushAngle + ~increment; brushAngle.postln}
    );
    pat.play;
    pat
};

MIDIFunc.noteOn({|vel, note, chan, port|
    var noteTime = 0.5;
    ~noteQueue.add(note);
    ~speedEnv.(0.1, noteTime, 10);
    ~angleEnv.(0.5/5, pi/2, 5);
    [vel, note, chan, port].postln;
}, nil, nil, midiIn.uid);

)
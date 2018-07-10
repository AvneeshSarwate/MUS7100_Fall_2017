(
var loopTouchDict = Dictionary.new;
var liveTouchDict = Dictionary.new;
var theForcePort = NetAddr("localhost", 7501);
var lock = Semaphore.new(1);

var pat = Pbind(
    \delta, 1/150,

    \play, {
        var combinedTouchDict = loopTouchDict ++ liveTouchDict;
        var numTouches = combinedTouchDict.size;
        // loopTouchDict.postln;
        // numTouches.postln;
        lock.wait;
        if(numTouches == 0,
            {
                theForcePort.sendMsg("/senselDraw", 0);
            },
            {
                var touchList = List.new;
                combinedTouchDict.keys.do({|key|
                    touchList.addAll([key]++combinedTouchDict[key]);
                });
                // touchList.postln;
                // combinedTouchDict.keys.postln;
                theForcePort.sendRaw((["/senselDraw", numTouches]++touchList).asArray.asRawOSC);
            }
        );
        lock.signal;
    }
);
pat.play;
OSCFunc({|msg, time, addr, recvPort|
    var senselData = msg[3..];
    var dictToUse;
    var numTouches = msg[2];
    lock.wait;
    if(msg[1].asSymbol == \loop, {
        dictToUse = loopTouchDict;
        // ["loop sensel", msg].postln;
    });
    if(msg[1].asSymbol == \live, {
        dictToUse = liveTouchDict;
        // "live sensel".postln;
    });
    dictToUse.clear;
    if(numTouches > 0, {
        (0..(numTouches-1)).do({|i|
            var touchDataInd = i*4;
            dictToUse[senselData[touchDataInd]] = senselData[(touchDataInd+1)..(touchDataInd+3)];
        });
    });
    lock.signal;
}, "/senselDrawFwd");

)

//p is now an EventStream that you can start/stop on the fly
p.stop
p.pause //from what i can tell, pause and stop don't do anything different - stop doesn't reset the pattern
p.play
p.reset

a.clear
a.keys

(
a = Dictionary.new;
b = Dictionary.new;
a[3] = 1;
b[7] = 5;
(a++b).keys
)
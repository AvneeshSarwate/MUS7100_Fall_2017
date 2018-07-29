(

Sim


)


n = NetAddr.new("localhost", 7500);

n.sendMsg("/in1", 1, 0, 1, 0)

t = TempoClock.new(1)

~step = 0.02;
~task = Task({
    {
    ~step.wait;
        n.sendMsg("/in1", (t.beats+ t.beats.cos+1/2).sin+1/2, t.beats.cos+1/2, 1, 0);
    n.sendMsg("/in2", (t.beats+1).sin+1/2, (t.beats+1).cos+1/2, 1, 0);
    n.sendMsg("/in3", (t.beats+2).sin+1/2, (t.beats+3).cos+1/2, 1, 0);
    }.loop;
});

~task.play





(
var chan = 2;
MIDIClient.init;
m = MIDIOut.new(2);
// (0..127).do({|i| m.noteOn(chan, i, 127);});
// (0..127).do({|i| m.noteOn(chan, i, 0);});
// (0..127).do({|i| m.control(chan, i, 127);});
// (0..127).do({|i| m.control(chan, i, 0);});
)

m.noteOn(1, 10, 127)
m.control(2, 120, 127)


(
t = TempoClock.new;
f = Routine.new({(0..).do({|ind| ind.yield})});
p = Pbind(
    /*arbitrary pattern to specify the rhythm - can make it a Pfunc that references external variables
    so that the rhythm can be generatively controlled by external data (eg midi or osc or whatever)
    */
    \delta, Pfunc({1}),

    /*arbitrary play function to execute each pattern event */
    \play, {m.noteOn(1, 127.rand, 127.rand)},
).play(t)
)

//p is now an EventStream that you can start/stop on the fly
p.stop
p.pause //from what i can tell, pause and stop don't do anything different - stop doesn't reset the pattern
p.play
p.reset

10.rand
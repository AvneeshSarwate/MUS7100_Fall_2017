(




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
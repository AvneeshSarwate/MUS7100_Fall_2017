import OSC
import threading

TIME = 0
MIDI_NOTE = 1
ON_VEL = 2
MIDI_CHAN = 3
DUR = 4


class LoopSequencer:
    def __init__(self):
        self.superColliderServer = OSC.OSCServer(('127.0.0.1', 7100))
        self.serverThread = threading.Thread(target=self.superColliderServer.serve_forever)
        self.serverThread.daemon = False
        self.serverThread.start()

        self.superColliderClient = OSC.OSCClient()
        self.superColliderClient.connect(('127.0.0.1', 57120))

        self.paramValues = {
            'LOOP_LENGTH': 4,
            'TEMPO': 60
        }

        self.paramSetters = {
            'LOOP_LENGTH': self.setLoopLength,
            'TEMPO': self.setTempo
        }

        self.grid = []

        # Initiailize empty grid
        for i in range(8):
            self.grid.append([0, 0, 0, 0, 0, 0, 0, 0])

        print2d(self.grid)

        self.superColliderServer.addMsgHandler("/gridEventResponder", self.gridEventResponder)

    def sendOSCMessage(self, addr, *msgArgs):
        msg = OSC.OSCMessage()
        msg.setAddress(addr)
        msg.append(*msgArgs)
        self.superColliderClient.send(msg)

    def gridEventResponder(self, addr, tags, stuff, source):
        self.grid = stuff[0]
        print2d(self.grid)


# Pretty-print 2D grid
def print2d(matrix):
    s = [[str(e) for e in row] for row in matrix]
    lens = [max(map(len, col)) for col in zip(*s)]
    fmt = '\t'.join('{{:{}}}'.format(x) for x in lens)
    table = [fmt.format(*row) for row in s]
    print '\n'.join(table)


def stringToHitList(loopString):
    def splitHit(hitString):
        s = hitString.split(",")
        return [float(s[0]), int(s[1]), int(s[2]), int(s[3]), s[4]]

    recBuf = map(splitHit, loopString.split("-"))
    return recBuf


# hitlist is of form [[timestamp, midiNote, velocity, channel on/off]]
def hitListToString(hitList):
    hitToStringList = lambda h: ['%f' % h[0]] + map(str, h[1:])
    return "-".join(map(lambda h: ",".join(hitToStringList(h)), hitList))


# converts hitList to a list of (timeStamp, midiNote, velocity, channel, duration)
# TODO: fix assumtion that we start with note on, and that
# there is strict alternation of note on/off per midiNote
def hitListToNoteList(hitList):
    noteToStartStop = {}
    timeSoFar = 0
    numHits = len(hitList) - 1 if hitList[-1][4] == 'timeAfterLastHit' else len(hitList)
    for h in hitList[:numHits]:
        timeSoFar += h[0]
        if h[1] not in noteToStartStop:
            if h[4] == 'on':
                noteToStartStop[h[1]] = [(h[0], h[2], h[3], h[4])]
        else:
            noteEvents = noteToStartStop[h[1]]
            if noteEvents[-1][3] == h[4]:
                if h[4] == 'on':
                    noteEvents.append((h[0], h[2], h[3], 'off'))
                    noteEvents.append((h[0], h[2], h[3], h[4]))
                if h[4] == 'off':
                    continue
            else:
                noteEvents.append((h[0], h[2], h[3], h[4]))

    noteList = []
    # for n in noteToStartStop:
    # 	print n, noteToStartStop[n]
    for midiNote in noteToStartStop:
        startStop = noteToStartStop[midiNote]
        for i in range(0, len(startStop), 2):
            if len(startStop) == i + 1:
                noteList.append([startStop[i][0], midiNote, startStop[i][1], startStop[i][2],
                                 int(timeSoFar) + 0.95 - startStop[i][0]])
            else:
                # time, midiNote, onVelocity, midiChan, duration
                noteList.append([startStop[i][0], midiNote, startStop[i][1], startStop[i][2],
                                 startStop[i + 1][0] - startStop[i][0]])

    noteList.sort()
    return noteList


def noteListToHitList(noteList):
    intermediateHitList = []
    for n in noteList:
        intermediateHitList.append([n[0], n[1], n[2], n[3], 'on'])
        intermediateHitList.append([n[0] + n[4], n[1], n[2], n[3], 'off'])

    intermediateHitList.sort()
    timeAfterLastHit = int(intermediateHitList[-1][0]) + 1 - intermediateHitList[-1][0]
    # print intermediateHitList
    for i in range(len(intermediateHitList) - 1, 0, -1):
        intermediateHitList[i][0] -= intermediateHitList[i - 1][0]

    intermediateHitList.append([timeAfterLastHit, 0, 0, 0, 'timeAfterLastHit'])

    return intermediateHitList

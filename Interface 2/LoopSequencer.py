import OSC
import threading

TIME = 0
MIDI_NOTE = 1
ON_VEL = 2
MIDI_CHAN = 3
DUR = 4


class LoopSequencer:
    def __init__(self, fh2):
        self.fh2 = fh2
        self.superColliderServer = OSC.OSCServer(('127.0.0.1', 7100))
        self.SCServerThread = threading.Thread(target=self.superColliderServer.serve_forever)
        self.SCServerThread.daemon = False
        self.SCServerThread.start()

        self.superColliderClient = OSC.OSCClient()
        self.superColliderClient.connect(('127.0.0.1', 57120))

        self.superColliderServer.addMsgHandler("/sendLoopGrid", self.gridEventResponder)
        self.superColliderServer.addMsgHandler("/columnStep", self.columnStep)
        self.superColliderServer.addMsgHandler("/loopChanged", self.loopChangedResponder)

        self.intervalToSemitones = {
            'm2': 1,
            'M2': 2,
            'm3': 3,
            'M3': 4,
            'P4': 5,
            'A4': 6,
            'd5': 6,
            'P5': 7,
            'm6': 8,
            'M6': 9,
            'm7': 10,
            'M7': 11,
            'P8': 12
        }

        self.paramValues = {
            'LOOP_LENGTH': 4,
            'TEMPO': 60
        }

        self.paramSetters = {
            'LOOP_LENGTH': self.setLoopLength,
            'TEMPO': self.setTempo
        }

        self.loopTransformations = {
            41: [],
            42: [],
            43: [],
            44: [],
            45: [],
            46: [],
            47: [],
            48: []
        }

        self.grid = []

        # Initiailize empty grid
        for i in range(8):
            self.grid.append([0 for i in range(8)])

    def sendOSCMessage(self, addr, *msgArgs):
        msg = OSC.OSCMessage()
        msg.setAddress(addr)
        msg.append(*msgArgs)
        self.superColliderClient.send(msg)

    '''
        SC handlers
    '''

    def gridEventResponder(self, addr, tags, stuff, source):
        self.grid = stringToGrid(stuff[0])

    def loopChangedResponder(self, addr, tags, stuff, source):
        print "got new loop message"
        loopIndexChanged = stuff[0]
        self.runTransformations(loopIndexChanged)

    def columnStep(self, addr, tags, stuff, source):
        return
        # print "caught col step"

    '''
        Grid manipulation functions
    '''

    def replaceCol(self, index, array):
        for i, row in enumerate(self.grid):
            row[index] = array[i]
        self.sendGrid()
        print2d(self.grid)

    def replaceRow(self, index, array):
        self.grid[index] = array
        self.sendGrid()
        print2d(self.grid)

    def revCol(self, index):
        col = []

        for row in self.grid:
            col.append(row[index])

        col = col[::-1]

        self.replaceCol(index, col)

    def revRow(self, index):
        row = self.grid[index]
        row = row[::-1]

        self.replaceRow(index, row)

    def shiftGrid(self, dir, steps):
        if dir == "up":
            self.grid = self.grid[-(8 - steps):] + self.grid[:steps]

        if dir == "down":
            self.grid = self.grid[-steps:] + self.grid[:(8 - steps)]

        if dir == "right":
            newGrid = []
            for row in self.grid:
                newRow = row[-steps:] + row[:(8 - steps)]
                newGrid.append(newRow)
            self.grid = newGrid

        if dir == "left":
            newGrid = []
            for row in self.grid:
                newRow = row[-(8 - steps):] + row[:steps]
                newGrid.append(newRow)
            self.grid = newGrid

        self.sendGrid()
        print2d(self.grid)

    '''
        Parameter setting
    '''

    def setParam(self, name, value):
        if self.paramSetters.has_key(name):
            self.paramSetters[name](value)
        else:
            print("Parameter " + str(name) + " not found.")

    '''
        Setters
    '''

    def setLoopLength(self, value):
        self.paramValues['LOOP_LENGTH'] = value
        self.sendOSCMessage("/loopLength", self.paramValues['LOOP_LENGTH'])

        print "Loop length in beats: " + str(self.paramValues['LOOP_LENGTH'])

    def setTempo(self, value):
        self.paramValues['TEMPO'] = value
        self.sendOSCMessage("/uploadTempo", 1 / float(self.paramValues['TEMPO']), 0)

        print "Tempo: " + str(self.paramValues['TEMPO'])

    '''
        Loop transformation
    '''

    def getLoopNoteList(self, loopIndex):
        hitlist = self.fh2.loops[loopIndex]
        prevTime = 0
        for hit in hitlist:
            hit[0] = hit[0] + prevTime
            prevTime = hit[0]
        return hitListToNoteList(hitlist)

    def transformLoop(self, loopIndex, transform, send=True, noteListIn=[], **kwargs):
        if not noteListIn:
            if (kwargs.has_key('additive')):
                if kwargs['additive']:
                    if kwargs['additive']:
                        noteList = self.runTransformations(loopIndex, send=False)
                    else:
                        noteList = self.getLoopNoteList(loopIndex)
                else:
                    noteList = self.getLoopNoteList(loopIndex)
            else:
                noteList = self.getLoopNoteList(loopIndex)
        else:
            noteList = noteListIn

        '''
            rev transform
        '''
        if transform.lower() == 'rev':
            endTime = noteList[-1][TIME]
            newNoteList = [[endTime - note[TIME]] + note[1:5] for note in noteList]

            # self.transformedLoops[loopIndex] = sorted(newNoteList, key=lambda x: x[TIME])

        '''
            transpose transform
        '''
        if transform.lower() == 'transpose':
            direction = kwargs['direction']
            if (direction == "up"):
                dir = 1
            else:
                dir = -1
            interval = self.intervalToSemitones[kwargs['interval']]
            if (kwargs.has_key('octaves')):
                oct = kwargs['octaves']
            else:
                oct = 0
            newNoteList = [note[:1] + [note[MIDI_NOTE] + (dir * interval) + (dir * oct * 8)] + note[2:5] for note in
                           noteList]
            # self.transformedLoops[loopIndex] = newNoteList

        '''
            invert transform
        '''
        if transform.lower() == 'invert':
            if (kwargs.has_key('inversionPoint')):
                inversionPoint = kwargs['inversionPoint']
            else:
                inversionPoint = 'beg'

            if inversionPoint == 'beg':
                newNoteList = noteList[:]
                i = 1
                while i < len(noteList):
                    newNoteList[i] = [noteList[i][TIME]] + [
                        newNoteList[i - 1][MIDI_NOTE] + (noteList[i - 1][MIDI_NOTE] - noteList[i][MIDI_NOTE])] + \
                                     noteList[i][2:5]
                    i += 1

            if inversionPoint == 'end':
                newNoteList = noteList[:]
                i = len(noteList) - 2
                while i > -1:
                    newNoteList[i] = [noteList[i][TIME]] + [
                        newNoteList[i + 1][MIDI_NOTE] + (noteList[i + 1][MIDI_NOTE] - noteList[i][MIDI_NOTE])] + \
                                     noteList[i][2:5]
                    i -= 1
            newNoteList = sorted(newNoteList, key=lambda x: x[TIME])

        if send:
            print "sent"
            print newNoteList
            print loopIndex + 40
            print hitListToString(noteListToHitList(newNoteList))
            self.sendOSCMessage('/setBankMelody', [loopIndex + 40, hitListToString(noteListToHitList(newNoteList))])

        self.loopTransformations[loopIndex].append({
            'transform': transform,
            'kwargs': kwargs
        })

        return newNoteList

    def runTransformations(self, loopIndex, send=True):
        noteList = self.getLoopNoteList(loopIndex)

        for i, transform in enumerate(self.loopTransformations[loopIndex]):
            if i != len(self.loopTransformations[loopIndex]) - 1:
                noteList = self.transformLoop(loopIndex, transform['transform'], send=False, notelist=noteList,
                                              kwargs=transform['kwargs'])
            else:
                noteList = self.transformLoop(loopIndex, transform['transform'], send=send, notelist=noteList,
                                              kwargs=transform['kwargs'])

        return noteList

    def clearTransformations(self, loopIndex, indexes=[]):
        transforms = self.loopTransformations[loopIndex]

        if not indexes:
            self.loopTransformations[loopIndex] = []
        else:
            toDel = sorted(indexes, key=int, reverse=True)
            for i in toDel:
                del (self.loopTransformations[loopIndex][i])

    def sendGrid(self):
        self.sendOSCMessage('/sendGrid', gridToString(self.grid))


# Pretty-print 2D grid
def print2d(matrix):
    s = [[str(e) for e in row] for row in matrix]
    lens = [max(map(len, col)) for col in zip(*s)]
    fmt = '\t'.join('{{:{}}}'.format(x) for x in lens)
    table = [fmt.format(*row) for row in s]
    print '\n'.join(table)


def stringToGrid(string):
    newGrid = []
    split = string.split(',')

    for i in range(0, 8):
        newRow = []

        for j in range(0, 8):
            newRow = newRow + [int(split[i * 8 + j])]

        newGrid.append(newRow)

    return newGrid


def gridToString(grid):
    out = ""

    for row in grid:
        stringifyedRow = []

        for val in row:
            stringifyedRow.append(str(val))

        out += ",".join(stringifyedRow)
        out += ","

    return out[:-1]


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

import OSC
import threading

TIME = 0
MIDI_NOTE = 1
ON_VEL = 2
MIDI_CHAN = 3
DUR = 4


class Responder:
    def __init__(self):
        self.superColliderServer = OSC.OSCServer(('127.0.0.1', 7100))
        self.serverThread = threading.Thread(target=self.superColliderServer.serve_forever)
        self.serverThread.daemon = False
        self.serverThread.start()

        self.superColliderClient = OSC.OSCClient()
        self.superColliderClient.connect(('127.0.0.1', 57120))

        self.superColliderServer.addMsgHandler("/delayResponder", self.delayResponder)
        self.superColliderServer.addMsgHandler("/bufferShufflerResponder", self.bufferShufflerResponder)
        self.superColliderServer.addMsgHandler("/counterpointTransformationResponder",
                                               self.counterpointTransformationResponder)

        self.paramValues = {
            'NUM_SLICES': 1,
            'SHUFFLE_STR': "",
            'HOLD_TYPE' : "silence",
            'EXTRACT_LENGTH' : 2.0,
            'HOLD_LENGTH' : 0.5
        }

        self.paramSetters = {
            'NUM_SLICES': self.setNumSlices,
            'SHUFFLE_STR': self.setShuffleStr,
            'HOLD_TYPE' : self.setHoldType,
            'EXTRACT_LENGTH' : self.setExtractLength,
            'HOLD_LENGTH' : self.setHoldLength
        }

    def sendOSCMessage(self, addr, *msgArgs):
        msg = OSC.OSCMessage()
        msg.setAddress(addr)
        msg.append(*msgArgs)
        self.superColliderClient.send(msg)

    # stuff[0] is the serialized string of the melodic input to be transformed.
    def delayResponder(self, addr, tags, stuff, source):
        # calculate the musical material to send back

        self.sendOSCMessage("/playResponse", stuff[0])
        print stuff[0]
        hitList = stringToHitList(stuff[0])
        noteList = hitListToNoteList(hitList)

    # msg[0] is the serialized string of the melodic input to be transformed.
    def bufferShufflerResponder(self, addr, tags, stuff, source):
        hitList = stringToHitList(stuff[0])
        noteList = hitListToNoteList(hitList)

        print noteList
        # calculate the musical material to send back
        newNoteList = shuffleBufferSlices(self.paramValues['SHUFFLE_STR'], self.paramValues['NUM_SLICES'], noteList)
        print newNoteList

        self.sendOSCMessage("/playResponse", hitListToString(noteListToHitList(newNoteList)))

    # msg[0] is the serialized string of the melodic input to be transformed.
    def counterpointTransformationResponder(self, addr, tags, stuff, source):
        hitList = stringToHitList(stuff[0])
        noteList = hitListToNoteList(hitList)

        # calculate the musical material to send back

        self.sendOSCMessage("/playResponse", hitListToString(noteListToHitList(noteList)))

    # Sets a live coded parameter
    def setParam(self, name, value):
        if self.paramSetters.has_key(name):
            self.paramSetters[name](value)
        else:
            print("Parameter " + str(name) + " not found.")

    '''
        Setter functions for live coded parameters
    '''

    def setNumSlices(self, value):
        if isinstance(value, (int, long)):
            if value < 27 and value > 0:
                self.paramValues['NUM_SLICES'] = value
            else:
                print("NUM_SLICES must be an integer between 1-26.")
        else:
            print("NUM_SLICES must be an integer between 1-26.")

        print("NUM_SLICES = " + str(self.paramValues['NUM_SLICES']))

        self.sendOSCMessage("/numSlices", self.paramValues['NUM_SLICES'])

    def setShuffleStr(self, value):
        if isinstance(value, basestring):
            if validateShuffleStr(value, self.paramValues['NUM_SLICES']):
                self.paramValues['SHUFFLE_STR'] = value
        else:
            print("SHUFFLE_STR must be a string.")

        print("SHUFFLE_STR = " + self.paramValues['SHUFFLE_STR'])

        self.sendOSCMessage("/shuffleStr", self.paramValues['SHUFFLE_STR'])

    def setHoldType(self, value):
        if not (value == "silence" or value == "hold"):
            print("HOLD_TYPE must be either 'hold' or 'silence.")
        else:
            self.paramValues['HOLD_TYPE'] = value

        print("HOLD_TYPE = " + self.paramValues['HOLD_TYPE'])

        self.sendOSCMessage("/holdType", self.paramValues['HOLD_TYPE'])

    def setExtractLength(self, value):
        self.paramValues['EXTRACT_LENGTH'] = value

        print("EXTRACT_LENGTH = " + self.paramValues['EXTRACT_LENGTH'])

        self.sendOSCMessage("/extractLength", self.paramValues['EXTRACT_LENGTH'])

    def setHoldLength(self, value):
        self.paramValues['HOLD_LENGTH'] = value

        print("HOLD_LENGTH = " + self.paramValues['HOLD_LENGTH'])

        self.sendOSCMessage("/holdLength", self.paramValues['HOLD_LENGTH'])


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
    numHits = len(hitList)-1 if hitList[-1][4] == 'timeAfterLastHit' else len(hitList)
    for h in hitList[:numHits]:
        timeSoFar += h[0]
        if h[1] not in noteToStartStop:
            if h[4] == 'on':
                noteToStartStop[h[1]] = [(h[0], h[2], h[3], h[4])] 
        else:
            noteEvents = noteToStartStop[h[1]]
            if noteEvents[-1][3] == h[4]:
                if h[4] == 'on':
                    noteEvents.append((h[0], h[2], h[3],'off'))
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


'''
    shuffleBufferSlices
    inputs:
        shuffleString (string): pattern for rearrangement of buffer slices
        noteList (list of list[time, midiNote, onVelocity, midiChan, duration]): notes to be manipulated
    output:
        newNoteList = shuffled note list
'''


def shuffleBufferSlices(shuffleString, numSlices, noteList):
    loweredString = shuffleString.lower()

    # Form slices (edit durations)
    sliceResponse = formSlices(numSlices, noteList)
    slices = sliceResponse['slices']
    sliceLength = sliceResponse['sliceLength']

    # Rearrange slices to shuffleString (edit timestamps (and possibly durations))
    newNoteList = rearrangeSlices(loweredString, sliceLength, slices)
    return newNoteList


'''
    validateShuffleStr
    inputs:
        shuffleStr (string): pattern for rearrangement of buffer slices
        
        A letter corresponds to a slice (e.g. 'A' is the first, 'B' the second...).
        "+" extends the previously specified slice for the length of a slice. 
        "-" rests (i.e. creates silence) for the length of a slice. 
    output:
        valid (boolean)
'''


def validateShuffleStr(shuffleStr, numSlices):
    for i, c in enumerate(shuffleStr):
        if not c == '-':

            # If +, check behind for letter
            if c == '+':
                if not validatePlusOrigin(i, shuffleStr):
                    print("A '+' must have a slice somewhere before it.")
                    return False

            # Check if outside a - z
            elif ord(c) > 122 or ord(c) < 97:
                print(c + " is an invalid slice string character.")
                return False

            # Check for too many letters
            elif (ord(c) - 96) > numSlices:
                print(
                    c + " is an invalid buffer slice character for the number of slices you have.\nYou can currently use letters a - " + chr(
                        numSlices + 96) + ".")
                return False

    return True


def validatePlusOrigin(i, shuffleStr):
    try:

        if shuffleStr[0] == '+':
            raise Exception('String starts with +.')

        if i < 0:
            raise Exception('Index "out of bounds".')

        prev_char = shuffleStr[i - 1]

        if isLowercaseLetter(prev_char):
            return True
        elif (prev_char == '+' or prev_char == '-'):
            return validatePlusOrigin(i - 1, shuffleStr)

    except Exception as e:
        print(e)
        return False


'''
    formSlices
    inputs:
        numSlices (integer): number of slices to divide noteList into
        noteList (list of list[time, midiNote, onVelocity, midiChan, duration]): notes to be manipulated
    outputs:
        slices (list of noteLists): slices of notes
        sliceLength (float): sliceLength for rearranging
'''


def formSlices(numSlices, noteList):
    slices = []
    for i in range(0, numSlices):
        slices.append([])

    startTime = noteList[0][TIME]
    endTime = 0

    # Determine the end time of the final note duration
    for note in noteList:
        noteEnd = note[TIME] + note[DUR]
        if noteEnd > endTime:
            endTime = noteEnd

    print("Length of input: " + str(endTime - startTime))

    # Divide total time into equal slices
    sliceLength = (endTime - startTime) / numSlices

    print("Length of slice: " + str(sliceLength))

    if sliceLength == 0:
        slices[0] = noteList
        return slices

    # Divide every note across appropriate slice with time being set to time after start of the slice
    for note in noteList:
        startOfNote = note[TIME] - startTime
        noteDur = note[DUR]
        endOfNote = startOfNote + noteDur

        sliceIndex = int(startOfNote / sliceLength)
        startOfSlice = sliceIndex * sliceLength
        endOfSlice = (sliceIndex * sliceLength) + sliceLength
        posInSlice = startOfNote - startOfSlice

        while (endOfNote > endOfSlice):
            # Append as much as possible into current slice
            slices[sliceIndex].append(
                [posInSlice, note[MIDI_NOTE], note[ON_VEL], note[MIDI_CHAN], (sliceLength - posInSlice)])

            # Shift slice
            sliceIndex += 1

            # Reset slice vals
            startOfSlice = sliceIndex * sliceLength
            endOfSlice = (sliceIndex * sliceLength) + sliceLength

            # Use what's remaining of the note
            startOfNote += (sliceLength - posInSlice)
            noteDur -= (sliceLength - posInSlice)
            endOfNote = startOfNote + noteDur
            posInSlice = startOfNote - startOfSlice

        # Add note to slice
        slices[sliceIndex].append([posInSlice, note[MIDI_NOTE], note[ON_VEL], note[MIDI_CHAN], noteDur])

    # Sort slices by timestamp
    for i, slice in enumerate(slices):
        slices[i] = sorted(slice, key=lambda x: x[TIME])

    return {'slices': slices, 'sliceLength': sliceLength}


'''
    rearrangeSlices
    inputs:
        shuffleStr (string): pattern for rearrangement of slices
        sliceLength: time in seconds of a slice
        slices (list of noteLists): slices of notes
    output:
        newNoteList (noteList): shuffled notes to send to SC
'''


def rearrangeSlices(shuffleStr, sliceLength, slices):
    newNoteList = []
    i = 0
    posInSlices = 0

    while i < len(shuffleStr):
        if shuffleStr[i] == '-':
            posInSlices += 1
            i += 1

        elif isLowercaseLetter(shuffleStr[i]):
            nextLetterIndex = getNextLetterIndex(i, shuffleStr)
            if nextLetterIndex < 0:
                nextLetterIndex = len(shuffleStr)

            stretch = nextLetterIndex - i
            slice = slices[sliceIndexFromLetter(shuffleStr[i])]
            stretched = [[(note[TIME] * stretch) + (sliceLength * posInSlices)] + note[1:4] + [note[DUR] * stretch]
                         for note in slice]
            for note in stretched:
                newNoteList.append(note)

            posInSlices += 1

            j = i + 1
            while j < nextLetterIndex:
                if shuffleStr[j] == '+':
                    posInSlices += 1
                    j += 1

                else:
                    startRestTime = sliceLength * posInSlices
                    endRestTime = startRestTime + sliceLength

                    startIntersect = getIntersectingNotes(newNoteList, startRestTime)
                    startEdits = [note[:4] + [startRestTime - note[TIME]] for note in startIntersect]

                    endIntersect = getIntersectingNotes(newNoteList, endRestTime)
                    endEdits = [[endRestTime] + note[1:4] + [(note[TIME] + note[DUR]) - endRestTime] for note in
                                startIntersect]

                    nonAffectedNotes = getNotIntersectingNotes(newNoteList, startRestTime, endRestTime)

                    for note in startEdits:
                        nonAffectedNotes.append(note)

                    for note in endEdits:
                        nonAffectedNotes.append(note)

                    newNoteList = nonAffectedNotes

                    posInSlices += 1
                    j += 1

            i = j

    return newNoteList


def getIntersectingNotes(noteList, intersectTime):
    def pullNotes(note):
        noteStart = note[TIME]
        noteEnd = note[TIME] + note[DUR]
        if intersectTime > noteStart and intersectTime < noteEnd:
            return note

    return filter(pullNotes, noteList)


def getNotIntersectingNotes(noteList, startRestTime, endRestTime):
    def pullNotes(note):
        noteStart = note[TIME]
        noteEnd = note[TIME] + note[DUR]
        if noteEnd < startRestTime or noteStart > endRestTime:
            return note

    return filter(pullNotes, noteList)


def getPlusOrigin(i, shuffleStr):
    if isLowercaseLetter(shuffleStr[i]):
        return i
    else:
        return getPlusOrigin(i - 1, shuffleStr)


def isLowercaseLetter(ascii_val):
    if (ord(ascii_val) < 123 and ord(ascii_val) > 96):
        return True
    else:
        return False


def getNextLetterIndex(i, shuffleStr):
    if i == len(shuffleStr) - 1:
        return -1
    elif isLowercaseLetter(shuffleStr[i + 1]):
        return i + 1
    else:
        return getNextLetterIndex(i + 1, shuffleStr)


def sliceIndexFromLetter(c):
    return ord(c) - 97

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
            'NUM_BUF': 1,
            'BUF_STRING': "",
        }

        self.paramSetters = {
            'NUM_BUF': self.setNumBuf,
            'BUF_STRING': self.setBufString,
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
        print "response sent"
        hitList = stringToHitList(stuff[0])
        noteList = noteListToHitList(hitList)

    # msg[0] is the serialized string of the melodic input to be transformed.
    def bufferShufflerResponder(self, addr, tags, stuff, source):
        hitList = stringToHitList(stuff[0])
        noteList = noteListToHitList(hitList)

        # calculate the musical material to send back
        newNoteList = shuffleBuffers(self.paramValues['BUF_STRING'], self.paramValues['NUM_BUF'], noteList)

        self.sendOSCMessage("/playResponse", hitListToString(noteListToHitList(noteList)))

    # msg[0] is the serialized string of the melodic input to be transformed.
    def counterpointTransformationResponder(self, addr, tags, stuff, source):
        hitList = stringToHitList(stuff[0])
        noteList = noteListToHitList(hitList)

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

    def setNumBuf(self, value):
        if isinstance(value, (int, long)):
            if value < 27 and value > 0:
                self.paramValues['NUM_BUF'] = value
            else:
                print("NUM_BUF must be an integer between 1-26.")
        else:
            print("NUM_BUF must be an integer between 1-26.")

        print("NUM_BUF = " + str(self.paramValues['NUM_BUF']))

        self.sendOSCMessage("/numBuf", self.paramValues['NUM_BUF'])

    def setBufString(self, value):
        if isinstance(value, basestring):
            if validateBufferString(value, self.paramValues['NUM_BUF']):
                self.paramValues['BUF_STRING'] = value
        else:
            print("BUF_STRING must be a string.")

        print("BUF_STRING = " + self.paramValues['BUF_STRING'])

        self.sendOSCMessage("/bufString", self.paramValues['BUF_STRING'])


def stringToHitList(loopString):
    def splitHit(hitString):
        s = hitString.split(",")
        return [float(s[0]), int(s[1]), int(s[2]), int(s[3]), s[4]]

    recBuf = map(splitHit, loopString.split("-"))
    return recBuf


# hitlist is of form [[timestamp, midiNote, velocity, channel on/off]]
def hitListToString(hitList, button, startBeat, playing=0):
    hitToStringList = lambda h: ['%f' % h[0]] + map(str, h[1:])
    return str(button) + " " + "-".join(map(lambda h: ",".join(hitToStringList(h)), hitList)) + " " + str(playing)


# converts hitList to a list of (timeStamp, midiNote, velocity, channel, duration)
# TODO: fix assumtion that we start with note on, and that
# there is strict alternation of note on/off per midiNote
def hitListToNoteList(hitList):
    noteToStartStop = {}
    timeSoFar = 0
    for h in hitList[:len(hitList) - 1]:
        timeSoFar += h[0]
        if h[1] not in noteToStartStop:
            noteToStartStop[h[1]] = [(timeSoFar, h[2], h[3], h[4])]  # time, velocity, midiChan, on/off
        else:
            noteToStartStop[h[1]].append((timeSoFar, h[2], h[3], h[4]))

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
    shuffleBuffers
    inputs:
        bufferString (string): pattern for rearrangement of buffers
        noteList (list of list[time, midiNote, onVelocity, midiChan, duration]): notes to be manipulated
    output:
        newNoteList = buffer shuffled note list
'''


def shuffleBuffers(bufferString, numBuffers, noteList):
    loweredString = bufferString.lower()

    # Form buffers (edit durations)
    buffers = formBuffers(numBuffers, noteList)

    # Rearrange buffers to bufferString (edit timestamps (and possibly durations))
    newNoteList = rearrangeBuffers(loweredString, buffers)
    return newNoteList


'''
    validateBufferString
    inputs:
        bufferString (string): pattern for rearrangement of buffers
        
        A letter corresponds to a buffer (e.g. 'A' is the first, 'B' the second...).
        "+" extends the previously specified buffer for the length of a buffer. 
        "-" rests (i.e. creates silence) for the length of a buffer. 
    output:
        valid (boolean)
'''


def validateBufferString(bufferString, numBuffers):
    for i, c in enumerate(bufferString):
        if not c == '-':

            # If +, check behind for letter
            if c == '+':
                if not validatePlusOrigin(i, bufferString):
                    print("A '+' must have a buffer somewhere before it.")
                    return False

            # Check if a - c
            elif ord(c) > 122 or ord(c) < 97:
                print(c + " is an invalid buffer string character.")
                return False

            # Check for too many letters
            elif (ord(c) - 96) > numBuffers:
                print(
                    c + " is an invalid buffer character for the number of buffers you have.\nYou can currently use letters a - " + chr(
                        numBuffers + 96) + ".")
                return False

    return True


def validatePlusOrigin(i, bufferString):
    try:

        if bufferString[0] == '+':
            raise Exception('String starts with +.')

        if i < 0:
            raise Exception('Index "out of bounds".')

        prev_char = bufferString[i - 1]

        if (ord(prev_char) < 123 and ord(prev_char) > 96):
            return True
        elif (prev_char == '+' or prev_char == '-'):
            return validatePlusOrigin(i - 1, bufferString)

    except Exception as e:
        print(e)
        return False


'''
    formBuffers
    inputs:
        numBuffers (integer): number of buffers to divide noteList into
        noteList (list of list[time, midiNote, onVelocity, midiChan, duration]): notes to be manipulated
    outputs:
        buffers (list of noteLists): buffers of notes
'''


def formBuffers(numBuffers, noteList):
    buffers = []
    for i in range(0, numBuffers):
        buffers.append([])

    start_time = noteList[0][TIME]
    end_time = 0

    # Determine the end time of the final note duration
    for note in noteList:
        note_end = note[TIME] + note[DUR]
        if note_end > end_time:
            end_time = note_end

    print("Length of input: " + str(end_time - start_time))

    # Divide total time into equal buffers
    bufferLength = (end_time - start_time) / numBuffers

    print("Length of buffer: " + str(bufferLength))

    if bufferLength == 0:
        buffers[0] = noteList
        return buffers

    # Divide every note across appropriate buffer with time being set to time after start of the buffer
    for note in noteList:
        start_of_note = note[TIME] - start_time
        note_dur = note[DUR]
        end_of_note = start_of_note + note_dur

        buffer_index = int(start_of_note / bufferLength)
        start_of_buffer = buffer_index * bufferLength
        end_of_buffer = (buffer_index * bufferLength) + bufferLength
        pos_in_buffer = start_of_note - start_of_buffer

        while (end_of_note > end_of_buffer):
            # Append as much as possible into current buffer
            buffers[buffer_index].append(
                [pos_in_buffer, note[MIDI_NOTE], note[ON_VEL], note[MIDI_CHAN], (bufferLength - pos_in_buffer)])

            # Shift buffer
            buffer_index += 1

            # Reset buffer vals
            start_of_buffer = buffer_index * bufferLength
            end_of_buffer = (buffer_index * bufferLength) + bufferLength

            # Use what's remaining of the note
            start_of_note += (bufferLength - pos_in_buffer)
            note_dur -= (bufferLength - pos_in_buffer)
            end_of_note = start_of_note + note_dur
            pos_in_buffer = start_of_note - start_of_buffer

        # Add note to buffer
        buffers[buffer_index].append([pos_in_buffer, note[MIDI_NOTE], note[ON_VEL], note[MIDI_CHAN], note_dur])

    return buffers


'''
    rearrangeBuffers
    inputs:
        bufferString (string): pattern for rearrangement of buffers
        buffers (list of noteLists): buffers of notes
    output:
        newNoteList (noteList): shuffled notes to send to SC
'''


def rearrangeBuffers(bufferString, buffers):
    newNoteList = []

    # for c in bufferString:

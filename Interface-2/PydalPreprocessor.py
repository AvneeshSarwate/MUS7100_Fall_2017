import OSC
import copy
import json


class PydalPreprocessor:

    def __init__(self, oscServer):
        self.oscServer = oscServer
        self.oscServer.addMsgHandler("/pianoRollNotes", self.recievePianoRoll)
        self.pianoRollNotes = {}


    def preprocess(self, inputString):
        return inputString

    # stuff[0] is pianoRoll key, stuff[1] is noteState
    def recievePianoRoll(self, addr, tags, stuff, source):
        self.pianoRollNotes = json.loadS(stuff[1])


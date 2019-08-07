import OSC
import copy
import json
import re


class PydalPreprocessor:

    def __init__(self, oscServer):
        self.oscServer = oscServer
        self.oscServer.addMsgHandler("/pianoRollNotes", self.recievePianoRoll)
        self.pianoRollNotes = {}
        self.preprocessingSteps = [lambda a : a]


    def preprocess(self, patternString):
        for preprocessStep in self.preprocessingSteps:
            patternString = preprocessStep(patternString)
        return patternString

    def chordFinder(self, patternString):
        # [[m.start(), m.group()] for m in re.finditer("aab", "aab aab aab")] - returns [[0, 'aab'], [4, 'aab'], [8, 'aab']]
        patternList = list(patternString)
        chordExpr = "p[0-9]+"
        chordSymbols = [[m.start(), m.group()] for m in re.finditer(chordExpr, patternString)]
        chordSymbols.sort(cmp=lambda a, b: a[0]-b[0], reverse=True)
        for cs in chordSymbols:
            chordTime = float(cs[1][1:])
            positionNotes = self.findIntersectingNotes(chordTime + 0.05) #fudging just in case mouse drags make note not exactly start at clean position
            noteString = "[" + ",".join([str(n) for n in positionNotes]) + "]"

            # splice chord string into pattern
            del patternList[cs[0]:cs[0]+len(cs[1])]
            patternList.insert(cs[0], noteString)
        return "".join(patternList)


    def findIntersectingNotes(self, time):
        intersectingNotes = []
        for note in self.pianoRollNotes:
            if note["position"] <= time and time <= note["position"]+note["duration"]:
                intersectingNotes.append(note["pitch"])
        return intersectingNotes


        return inputString

    # stuff[0] is pianoRoll key, stuff[1] is noteState
    def recievePianoRoll(self, addr, tags, stuff, source):
        self.pianoRollNotes = json.loads(stuff[1])


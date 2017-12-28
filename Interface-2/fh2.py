import OSC
import threading
import random
import copy
import phrase
import pickle
import itertools


# functionHanlder
class FH2:
    def __init__(self):
        self.superColliderClient = OSC.OSCClient()
        self.superColliderClient.connect(('127.0.0.1', 57120))

        self.LSClient = OSC.OSCClient()
        self.LSClient.connect(('127.0.0.1', 7100))

        self.superColliderServer = OSC.OSCServer(('127.0.0.1', 13371))
        self.serverThread = threading.Thread(target=self.superColliderServer.serve_forever)
        self.serverThread.daemon = False
        self.serverThread.start()

        self.topRowFunctions = [0] * 8

        n = 4

        self.loops = [0 for i in range(100)]
        self.loopInfo = [{} for i in range(100)]

        # [(loops, loopInfo)]
        self.scenes = [0] * 32  # scenes[18] is scene in 1st row 8th column of launchpad
        self.sceneStack = []
        self.sceneCollectionsStack = []
        self.faderBanks = [[[0] * 12 for i in range(4)] for j in range(4)]
        self.currentFaderVals = [[0] * 12 for i in range(4)]

        # todo - update scales/roots here when changed programatically?
        self.scales = [[0, 2, 3, 5, 7, 8, 10] for i in range(n - 1)] + [range(12)]
        self.roots = [60, 60, 36, 36]

        self.superColliderServer.addMsgHandler("/algRequest", self.handleAlgRequest)
        self.superColliderServer.addMsgHandler("/saveLoop", self.saveNewLaunchpadLoop)
        self.superColliderServer.addMsgHandler("/algRequestUpdate", self.updateChannel)
        self.superColliderServer.addMsgHandler("/loopPlay", self.loopPlay)
        self.superColliderServer.addMsgHandler("/saveScene", self.saveSceneHandler)
        self.superColliderServer.addMsgHandler("/playScene", self.playSceneHandler)
        self.superColliderServer.addMsgHandler("/faderSettingSave", self.saveFaderSetting)
        self.superColliderServer.addMsgHandler("/getCurrentFaderVals", self.recieveCurrentFaderVals)
        self.superColliderServer.addMsgHandler("/buttonForwarding", self.buttonForwardingHandler)
        self.superColliderServer.addMsgHandler("/miniLaunchpadTopRow", self.topRowHandler)
        self.superColliderServer.addMsgHandler("/pedalButton", self.pedalButtonHandler)
        self.superColliderServer.addMsgHandler("/saveMetaInfo", self.saveMetaInfo)
        self.superColliderServer.addMsgHandler("/metaInfoLoadRequest", self.metaInfoLoadRequestHandler)

        self.pedalButtonFunc = lambda: 0

        self.channels = {}  # key - int, val - (transFunc, rootMel)
        self.savedStrings = []
        self.buttonForwardingHandlers = [[] for i in range(n)]

        # leaderPadInd -> [(padIndex, delayFromLeader)]
        self.delays = {}
        self.superColliderServer.addMsgHandler("/xyToPython", self.padFollowerHandler)

    def addForwardingHandler(self, chanInd, handler):
        self.buttonForwardingHandlers[chanInd].append(handler)

    # stuff = [chan, note, vel, on/off, launchpadKeyMidi]
    def buttonForwardingHandler(self, addr, tags, stuff, source):
        for handler in self.buttonForwardingHandlers[stuff[0]]:
            handler.handle(*stuff)

    def pedalButtonHandler(self, addr, tags, stuff, source):
        return self.pedalButtonFunc()

    # stuff = [chanInd, bankNum, root, scale, loopString]
    def handleAlgRequest(self, addr, tags, stuff, source):
        msg = OSC.OSCMessage()
        msg.setAddress("/algResponse")
        msg.append(int(stuff[0]))
        msg.append(int(stuff[1]))
        print "got from supercollider"
        print stuff
        hitList = self.stringToHitList(stuff[4])
        for h in hitList:
            h[1] += 5
        msg.append(self.hitListToString(hitList, scale, startBeat))
        self.superColliderClient.send(msg)

    # stuff = [bankNum, loopString, button]
    def saveNewLaunchpadLoop(self, addr, tags, stuff, source):
        self.savedStrings.append(stuff[2])
        hitList = self.stringToHitList(stuff[1])
        bankNum = stuff[0]
        button = stuff[2]
        self.loops[bankNum] = hitList
        self.loopInfo[bankNum]["button"] = button
        self.loopInfo[bankNum]["playing"] = True
        # Send loop change event to LoopSequencer
        msg = OSC.OSCMessage()
        msg.setAddress("/loopChanged")
        msg.append(bankNum)
        self.LSClient.send(msg)

    # stuff = [root, scaleString]

    # stuff = [metaInfoType, loopInd, info...]
    def saveMetaInfo(self, addr, tags, stuff, source):
        if stuff[0] == "quadKey":
            self.saveQuadKeysMetaInfo(*stuff[:1])

    def saveQuadKeysMetaInfo(loopInd, rootStr, scalesStr):
        self.roots = [int(r) for r in rootStr.split(",")]
        self.scales[chanInd] = [[int(n) for n in scale.split(",")] for scale in scaleStr.split(".")]

    # stuff = [sceneInd]
    def metaInfoLoadRequestHandler(self, addr, tags, stuff, source):
        self.loadMetaInfo(stuff[0])

    def loadMetaInfo(self, sceneInd):
        sceneTuple = self.scenes[sceneInd]
        roots = sceneTuple[2]
        scales = sceneTuple[3]
        for i in range(4):
            self.rootScale(i, roots[i], scales[i])
        # todo - need to separate out quadKey logic from loop saving logic.
        # when implemented properly, the python modules of different interfaces
        # will be registered with the FH model, and when a scene is loaded this
        # function will send a message to all of the modules that a load-scene has
        # occured, the message contaning the meta-info appropriate for that insturment
        # the instrument will then either update or not, depending on its push-update flag

    # stuff = [bankchan, bankInd, playing(0/1)]
    def loopPlay(self, addr, tags, stuff, source):
        self.loopInfo[stuff[1]]["playing"] = stuff[2]

    def resetButtonDestinations(self, destList):
        msg = OSC.OSCMessage()
        msg.setAddress("/resetButtonDestinations")
        msg.append(destList)
        self.superColliderClient.send(msg)

    @staticmethod
    def stringToHitList(loopString):
        def splitHit(hitString):
            s = hitString.split(",")
            return [float(s[0]), int(s[1]), int(s[2]), int(s[3]), s[4]]

        recBuf = map(splitHit, loopString.split("-"))
        return recBuf

    @staticmethod
    def hitListToString(hitList, button, startBeat, playing=0):
        hitToStringList = lambda h: ['%f' % h[0]] + map(str, h[1:])
        return str(button) + " " + "-".join(map(lambda h: ",".join(hitToStringList(h)), hitList)) + " " + str(playing)

    def sceneToString(self, loops, loopInfo):
        sceneStringList = []
        for i in range(len(loops)):
            if loops[i] != 0:
                sceneStringList.append(self.hitListToString(loops[i], loopInfo[i]["button"], "startBeat",
                                                            1 if loopInfo[i]["playing"] else 0))
            else:
                sceneStringList.append("none")
        return ":".join(sceneStringList)

    def sendScene(self, ind, loops, loopInfo):
        msg = OSC.OSCMessage()
        msg.setAddress("/sendScene")
        msg.append(self.sceneToString(loops, loopInfo))
        msg.append(ind)
        self.superColliderClient.send(msg)

    def getScene(self):
        return (self.loops, self.loopInfo, self.roots, self.scales, self.faderBanks, self.currentFaderVals)

    def sendCurrentScene(self):
        self.sendScene(*self.getScene())

    # stuff[0] is ind of pad to which to save scene
    def saveSceneHandler(self, addr, tags, stuff, source):
        self.saveScene(int(stuff[0]))

    def saveScene(self, ind):
        c = copy.deepcopy
        self.scenes[ind] = map(c, self.getScene())
        msg = OSC.OSCMessage()
        msg.setAddress("/getCurrentFaderVals")
        msg.append(ind)
        self.superColliderClient.send(msg)

    # msg[0] is cuffentFaderVals string, msg[1] is sceneIndex to save them in
    def recieveCurrentFaderVals(self, addr, tags, stuff, source):
        print "GOT CURRENT FADER VALS"
        self.currentFaderVals = map(lambda s: map(int, s.split(",")), stuff[0].split("."))
        currentFadersToString = lambda bank: ".".join(map(lambda slot: ",".join(map(str, slot)), bank))
        self.scenes[stuff[1]][5] = copy.deepcopy(self.currentFaderVals)

    # stuff[0] is ind of pad corresponding to which scene to play
    def playSceneHandler(self, addr, tags, stuff, source):
        self.playScene(int(stuff[0]))

    def setCurrentScene(self, sceneTuple):
        self.loops, self.loopInfo, self.roots, self.scales, self.faderBanks, self.currentFaderVals = sceneTuple

    def playScene(self, ind):
        c = copy.deepcopy
        self.sceneStack.append(map(c, self.getScene()))
        self.loadMetaInfo(ind)
        self.setCurrentScene(c(self.scenes[ind]))
        self.sendCurrentScene()

    def undoScenePlay(self):
        self.setCurrentScene(self.sceneStack.pop())
        self.sendCurrentScene()

    def loadScenesFromFile(self, fileName):
        self.sceneCollectionsStack.append(copy.deepcopy(self.scenes))
        self.scenes = pickle.load(open(fileName))
        nonNullScenes = [x for x in range(len(self.scenes)) if self.scenes[x] != 0]
        for i in range(len(self.scenes)):
            if self.scenes[i] != 0:
                self.sendScene(i, self.scenes[i][0], self.scenes[i][1])
            else:
                msg = OSC.OSCMessage()
                msg.setAddress("/sendScene")
                msg.append("none")
                msg.append(i)
                self.superColliderClient.send(msg)

    def saveScenesToFile(self, fileName):
        pickle.dump(self.scenes, open(fileName, "w"))

    def saveFaderSetting(self, addr, tags, stuff, source):
        print "fader saved"
        self.lastFader = stuff
        self.faderBanks[stuff[0]][stuff[1]] = map(int, stuff[2].split(","))

    def end(self):
        self.superColliderServer.close()

    def startChannel(self, chanInd, transFunc, rootMel):
        # self.stopChannel(chanInd)
        self.channels[chanInd] = (transFunc, rootMel)
        msg = OSC.OSCMessage()
        msg.setAddress("/algStart")
        msg.append(chanInd)
        msg.append(self.hitListToString(rootMel, 'fillerStuff', 'fillerStuff'))
        self.superColliderClient.send(msg)

    # stuff[0] is channelInd
    def updateChannel(self, addr, tags, stuff, source):
        chanInd = stuff[0]
        transFunc = self.channels[chanInd][0]
        rootMel = self.channels[chanInd][1]
        newMel = transFunc(rootMel)
        msg = OSC.OSCMessage()
        msg.setAddress("/algRecieveUpdate")
        msg.append(chanInd)
        msg.append(self.hitListToString(newMel, 'fillerStuff', 'fillerStuff'))
        self.superColliderClient.send(msg)

    def rootScale(self, chan=0, root=0, scale='minor'):
        msg = OSC.OSCMessage()
        msg.setAddress('/rootScale')
        msg.append(root)
        keyval = scale
        if scale in phrase.modes.keys():
            keyval = ",".join(map(str, phrase.modes[scale]))
        else:
            keyVal = scale
            if len(keyval) == 0:
                raise StopIteration("malformed scale string")
            keyval = ','.join(str(keyval))
        msg.append(keyval)
        msg.append(chan)
        self.superColliderClient.send(msg)

    def stopChannel(self, chanInd):
        msg = OSC.OSCMessage()
        msg.setAddress("/algStop")
        msg.append(chanInd)
        self.superColliderClient.send(msg)

    def topRowHandler(self, addr, tags, stuff, source):
        if stuff[1] == 127:
            self.topRowFunctions[stuff[0]]()

    # followerPadDelay is [(padIndex, delayFromLeader)]
    def setFollowers(self, leaderPad, *followerPadDelay):
        self.delays[leaderPad] = followerPadDelay

    # stuff - [padInd, xVal, yVal]
    def padFollowerHandler(self, addr, tags, stuff, source):
        if stuff[0] in self.delays:
            for padDelay in self.delays[stuff[0]]:
                msg = OSC.OSCMessage()
                msg.setAddress("/xyFollowing")
                msg.append(padDelay[0])
                msg.append(stuff[1])
                msg.append(stuff[2])
                msg.append(padDelay[1])
                self.superColliderClient.send(msg)
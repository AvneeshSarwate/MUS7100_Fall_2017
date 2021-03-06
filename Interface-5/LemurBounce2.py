import optparse
import threading
import OSC

class LemurBounce2:
    def __init__(self):
        self.superColliderServer = OSC.OSCServer(('127.0.0.1', 7100))
        self.SCServerThread = threading.Thread(target=self.superColliderServer.serve_forever)
        self.SCServerThread.daemon = False
        self.SCServerThread.start()

        self.superColliderClient = OSC.OSCClient()
        self.superColliderClient.connect(('127.0.0.1', 57120))

        self.superColliderServer.addMsgHandler("/funcTrigger", self.funcTriggerResponder)

        self.visualsServer = OSC.OSCServer(('127.0.0.1', 57121))
        self.vizServerThread = threading.Thread(target=self.visualsServer.serve_forever)
        self.vizServerThread.daemon = False
        self.vizServerThread.start()

        self.visualsClient = OSC.OSCClient()
        self.visualsClient.connect(('127.0.0.1', 7400))

        self.visualsServer.addMsgHandler("/hello", self.testResponder)
        self.visualsServer.addMsgHandler("/toSC", self.toSCResponder)

        self.printLog = False;

        self.triggerFunctions = {}


    def funcTriggerResponder(self, addr, tags, stuff, source):
        if stuff[0] in self.triggerFunctions:
            self.triggerFunctions[stuff[0]]()


    def sendOSCMessage(self, addr, client=0, *msgArgs):
        msg = OSC.OSCMessage()
        msg.setAddress(addr)
        msg.append(*msgArgs)
        if (client == 0):
            self.superColliderClient.send(msg)
        else:
            self.visualsClient.send(msg)

    def toSCResponder(self, addr, tags, stuff, source):
        address = stuff[0]
        args = stuff[1:]
        if self.printLog:
            print address
            print args
        self.sendOSCMessage(address, 0, args)

    def testResponder(self, addr, tags, stuff, source):
        print stuff
        self.sendOSCMessage('/test', 1, ['Did you get this message?', 'Didja?'])


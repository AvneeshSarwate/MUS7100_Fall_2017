import OSC
import threading
import SimpleHTTPServer
import SocketServer
import time
import copy
import numpy as np
from pubnub.callbacks import SubscribeCallback
from pubnub.enums import PNStatusCategory
from pubnub.pnconfiguration import PNConfiguration
from pubnub.pubnub import PubNub

pnconfig = PNConfiguration()

pnconfig.subscribe_key = 'sub-c-8881abc2-a14d-11e7-8751-e66010d856a3'
pnconfig.publish_key = 'pub-c-b761da8c-d080-4868-931a-40c03e949212'

pubnub = PubNub(pnconfig)


class MySubscribeCallback(SubscribeCallback):
    def presence(self, pubnub, presence):
        pass  # handle incoming presence data

    def status(self, pubnub, status):
        if status.category == PNStatusCategory.PNUnexpectedDisconnectCategory:
            pass  # This event happens when radio / connectivity is lost

        elif status.category == PNStatusCategory.PNConnectedCategory:
            # Connect event. You can do stuff like publish, and know you'll get it.
            # Or just use the connected event to confirm you are subscribed for
            # UI / internal notifications, etc
            pubnub.publish().channel("parametercurves").message("Connected to server.").async(publish_callback)
        elif status.category == PNStatusCategory.PNReconnectedCategory:
            pass
            # Happens as part of our regular operation. This event happens when
            # radio / connectivity is lost, then regained.
        elif status.category == PNStatusCategory.PNDecryptionErrorCategory:
            pass
            # Handle message decryption error. Probably client configured to
            # encrypt messages and on live data feed it received plain text.

    def message(self, pubnub, message):
        print message


pubnub.add_listener(MySubscribeCallback())
pubnub.subscribe().channels('parametercurves').execute()

# HTTP Server
PORT = 8000
Handler = SimpleHTTPServer.SimpleHTTPRequestHandler
httpd = SocketServer.TCPServer(("", PORT), Handler)
print "serving at port", PORT
server_thread = threading.Thread(target=httpd.serve_forever)
server_thread.daemon = True
server_thread.start()


class ParameterCurves:
    def __init__(self):
        self.pubnub = pubnub
        self.channel = 'parametercurves'
        self.superColliderServer = OSC.OSCServer(('127.0.0.1', 7100))
        self.SCServerThread = threading.Thread(target=self.superColliderServer.serve_forever)
        self.SCServerThread.daemon = False
        self.SCServerThread.start()

        self.superColliderClient = OSC.OSCClient()
        self.superColliderClient.connect(('127.0.0.1', 57120))

    def sendPubNubMessage(self, m):
        result = pubnub.publish().channel(self.channel).message([m]).async(publish_callback)

    def sendOSCMessage(self, addr, *msgArgs):
        msg = OSC.OSCMessage()
        msg.setAddress(addr)
        msg.append(*msgArgs)
        self.superColliderClient.send(msg)


def publish_callback(result, status):
    return

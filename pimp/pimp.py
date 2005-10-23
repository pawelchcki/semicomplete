#!/usr/local/bin/python

import SocketServer, BaseHTTPServer
from threading import Thread,Event
from pysqlite2 import dbapi2 as sqlite

import Queue
import re

import socket
import signal
import sys
import os
import time

MEDIAPATH = "/mnt/Audio/MP3"

eventqueue = Queue.Queue()
streamlist = {}
clientlist = []

class Callable:
	def __init__(self, anycallable):
		self.__call__ = anycallable

class MusicList:
	needinit = 0
	singleton_instance = None

	def singleton():
		if MusicList.singleton_instance is None:
			MusicList.singleton_instance = MusicList()
		return MusicList.singleton_instance

	singleton = Callable(singleton)

	def __init__(self):
		self.dbpath = "%s/.pimpdb" % os.getenv("HOME")
		if not os.path.isfile(self.dbpath):
			self.needinit = 1

		self.db = sqlite.connect(self.dbpath)

		if self.needinit:
			self.initdb()
			self.findmusic()

	def initdb(self):
		print "Creating database..."
		cur = self.db.cursor()
		cur.execute("""
			CREATE TABLE music (
				songid INTEGER PRIMARY KEY,
				artist TEXT,
				album TEXT,
				title TEXT,
				genre TEXT,
				filename TEXT
			)
		""")
		cur.close()

	def findmusic(self):
		print "Finding music in %s" % MEDIAPATH
		cur = self.db.cursor()
		os.path.walk(MEDIAPATH, self._findmusic, cur)
		cur.close()
		self.db.commit()

	def _findmusic(self, arg, dirname, fnames):
		cur = arg
		print "Dir: %s" % dirname
		songs = map(lambda x: "%s/%s" % (dirname, x), 
						filter(lambda x: x[-4:] == ".mp3", fnames))
		for s in songs:
			cur.execute("INSERT INTO music (filename) VALUES (:song)", {"song":s})

	def find_randomsong(self):
		cur = self.db.cursor()
		#cur.execute("SELECT filename FROM music LIMIT 
		# XXX: Cache this...
		cur.execute("SELECT count(*) FROM music")
		rows = cur.fetchone()
		print "ROWS: %d" % rows
		cur.close()

class MP3Client:
	def __init__(self, request):
		self.request = request
		self.output = request.wfile
		(self.myhost, self.myport) = self.request.request.getsockname()
		(self.yourhost, self.yourport) = self.request.request.getpeername()
		self.myhost = socket.gethostbyaddr(self.myhost)[0]
		self.yourhost = socket.gethostbyaddr(self.yourhost)[0]
		if streamlist.has_key(request.path):
			self.stream = streamlist[request.path]
		else:
			self.stream = MP3Stream(request.path)
			streamlist[request.path] = self.stream

	def __str__(self):
		return "%s:%d" % (self.yourhost, self.yourport)

	def respond(self):
		response = []
		response.append("ICY 200 OK") # Standard shoutcast response
		response.append("icy-url: http://%s:%d/%s" 
							 % (self.myhost, self.myport, self.request.path[1:]))
		response.append("icy-name: Pimp 4.0")

		# Send the response header
		self.output.write("%s\n\n" % "\n".join(response))
	
	def broadcast(self):
		clientlist.append(self)
		print "New client: %s" % self
		print map(lambda x: "%s" % x, clientlist)
		self.respond()
		self.output.write("Me: %s:%d\n" % (self.myhost, self.myport))
		self.output.write("You: %s:%d\n" % (self.yourhost, self.yourport))

		try:
			while 1:
				music.find_randomsong()
				time.sleep(1)
		except socket.error:
			print "SERVER: Client %s:%d disconnected or died" \
				% (self.yourhost,self.yourport)
			if clientlist.index(self) > -1:
				clientlist.remove(self)
			else:
				print "Disconnected client not found in client list (UNEXPECTED ERROR)"

class MP3Stream:
	def __init__(self, request, name="Unknown Stream"):
		self.clients = []
		self.name = name

	def addclient(self, client):
		self.clients.append(client)

class Pimp:#{{{
	def __init__(self):
		self.server = ConnectionHandler()
		self.threads = [self.server]

	def start(self):
		for a in self.threads:
			print "Starting %s thread" % a.getName()
			a.start()

		# Wait for threads to die
		for a in self.threads:
			a.join()
#}}}

class Plug:#{{{
	def __init__(self,request):
		self.request = request
	
	def sendfile(self, src):
		if not os.path.isfile(src):
			return 0

		f = open(src)
		data = f.read(4096)
		while data:
			self.request.wfile.write(data)
			data = f.read(4096)
#}}}
class RedirectPlug(Plug):#{{{
	def process(self):
		r = self.request
		r.send_response(302)
		r.send_header("Location","/control")
		r.end_headers()
#}}}
class ControlWebPlug(Plug):#{{{
	def process(self):
		r = self.request
		r.send_response(200)
		r.send_header("Content-type", "text/html")
		r.end_headers()

		if r.command == "GET":
			self.sendfile("content/index.html")
#}}}
class ControlXMLRPCPlug(Plug):#{{{
	def process(self):
		# XMLRPC Interface
		pass
#}}}
class GenerateContentPlug(Plug):#{{{
	def process(self):
		r = self.request

#}}}
class StreamPlug(Plug):#{{{
	def process(self):
		client = MP3Client(self.request)
		client.broadcast()

#}}}
class Error404Plug(Plug):#{{{
	def process(self):
		r = self.request
		r.send_response(404)
		r.send_header("Content-type", "text/html")
		r.end_headers()
		
		if r.command == "GET":
			self.sendfile("content/404.html")
#}}}
class SendContentPlug(Plug):#{{{
	content_type = {
		"css": "text/css",
		"html": "text/html",
		"js": "text/javascript",
		"jpg": "image/jpeg",
		"png": "image/png",
	}

	def process(self):
		r = self.request
		path = "/".join(r.path.split("/")[1:])
		print "PATH: %s" % path

		if path.find("..") > -1:
			Error404Plug(r).process()
			return
		if not os.path.isfile(path):
			Error404Plug(r).process()
			return

		ext = path.split(".")[-1]
		ctype = self.content_type.has_key(ext) \
			and self.content_type[ext] or "text/plain"
		r.send_response(200)
		r.send_header("Content-type", ctype)
		r.end_headers()

		if r.command == "GET":
			self.sendfile(path)
#}}}

class ConnectionHandler(Thread):#{{{
	"""Handle connections from clients. Pass them off to the appropriate handler """

	def __init__(self, port=8000):
		self.port = port
		self.done = False
		self.server = SocketServer.ThreadingTCPServer(('', self.port),
																	 self.RequestHandler)
		Thread.__init__(self,name="ConnectionHandler")

	def run(self):
		while not self.done:
			self.server.handle_request()

	def join(self,timeout=None):
		Thread.join(self, timeout)

	class RequestHandler(BaseHTTPServer.BaseHTTPRequestHandler):
		""" HTTP connection handler """

		handlers = {
			'404': Error404Plug,
			'': RedirectPlug,
			'control': ControlWebPlug,
			'xmlrpc': ControlXMLRPCPlug,
			'content': SendContentPlug,
			'generate': GenerateContentPlug,
			'stream': StreamPlug,
		}

		def do_POST(self):
			""" This should only be hit via xmlrpc calls from the frontend """
			self.send_response(404)
			self.end_headers()
			self.wfile.write("Hello")

		def do_GET(self):
			plug = self.path.split("/")[1]
			if self.handlers.has_key(plug):
				handler = self.handlers[plug](self)
				handler.process()
			else:
				self.handlers['404'](self).process()

		def do_HEAD(self):
			plug = self.path.split("/")[1]
			if self.handlers.has_key(plug):
				handler = self.handlers[plug](self)
				handler.process()
			else:
				self.handlers['404'](self).process()
#}}}

if __name__ == '__main__':
	#p = Pimp()
	#p.start()
	print MusicList.singleton()
	print MusicList.singleton()

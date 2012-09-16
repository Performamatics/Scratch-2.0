// Persistent variable/list manager for Scratch 2.0
// Sayamindu Dasgupta <sayamindu@media.mit.edu>
// June 2011

// FIXME: The socket is not closed here. Does ActionScript3 support destructors? (no -- jhm)

// TODO:
//		* Support proxies
//		* Javascript interface to let the site know that we are using persistent data
//		* Open socket only if required
//		* Complain gracefully if the socket cannot be opened
//		* Something that I've probably forgotten

package interpreter {
	import flash.events.*;
	import flash.net.*;
	import watchers.ListWatcher;
	import util.JSON_AB;

public class PersistenceManager {

	private const server:String = 'jiggler.media.mit.edu';
	private const port:int = 1337;

	private var app:Scratch;
	private var projectId:String;
	private var socket:Socket;
	private var buffer:String = '';

	public function PersistenceManager(app:Scratch) {
		this.app = app;
		socket = new Socket();
		socket.addEventListener(Event.CONNECT, connected);
		socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
		socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
		socket.addEventListener(ProgressEvent.SOCKET_DATA, gotData);
	}

	public function updateVariable(variableName:String, variableValue:*):void {
		if (socket.connected) {
			socket.writeUTFBytes('{"set" : {"name" : "'+variableName+'", "value" : "'+variableValue+'"}}\n');
			socket.flush();
		}
	}

	public function setList(listName:String, listValue:*):void {
		if (socket.connected) {
			var JsonString:String = JSON_AB.stringify(listValue).split(",\n").join(","); //Ugly workaround for newlines added to JSON
			socket.writeUTFBytes('{"lset" : {"name" : "'+listName+'", "value" : '+JsonString+'}}\n');
		}
	}

	public function appendList(listName:String, value:*):void {
		if (socket.connected) {
			var JsonString:String = JSON_AB.stringify(value);
			socket.writeUTFBytes('{"lappend" : {"name" : "'+listName+'", "value" : '+JsonString+'}}\n');
		}
	}

	public function deleteList(listName:String, i:Number):void {
		if (socket.connected) {
			socket.writeUTFBytes('{"ldelete" : {"name" : "'+listName+'", "i" : '+i.toString()+'}}\n');
		}
	}

	public function insertList(listName:String, value:*, i:Number):void {
		if (socket.connected) {
			var JsonString:String = JSON_AB.stringify(value);
			socket.writeUTFBytes('{"linsert" : {"name" : "'+listName+'", "i" : '+i.toString()+', "value" : '+JsonString+'}}\n');
		}
	}

	public function replaceList(listName:String, value:*, i:Number):void {
		if (socket.connected) {
			var JsonString:String = JSON_AB.stringify(value);
			socket.writeUTFBytes('{"lreplace" : {"name" : "'+listName+'", "i" : '+i.toString()+', "value" : '+JsonString+'}}\n');
		}
	}

	public function connectOrReconnect(projectId:String):void {
		this.projectId = projectId;
		if (socket.connected == true) socket.close();
		if (projectId && (projectId.length > 0)) socket.connect(server, port);
	}

	private function connected(e:Event):void {
		buffer = ''; // clear input buffer
		socket.writeUTFBytes('{"handshake" : { "projectId" : "' + projectId + '"}}\n');
		socket.flush();
	}

	private function onError(evt:Event):void {
		app.browserTrace('Persistence Server error:' + String(evt));
	}

	private function gotData(e:Event):void {
		buffer += socket.readUTFBytes(socket.bytesAvailable);
		parseBuffer();
	}

	private function parseBuffer():void {
		var list:ListWatcher, i:int;
		while ((i = buffer.indexOf('\n')) >= 0) {
			//app.browserTrace("GOT DATA: " + buffer);
			var line:String = buffer.slice(0, i);
			buffer = buffer.slice(i + 1);
			if (line.length > 0) {
				var msg:Object = JSON_AB.parse(line);
				var methodName:String = msg.method;
				if (methodName == 'set') {
					var v:Variable = app.stagePane.lookupVar(msg.name);
					if (v && v.isPersistent) v.value = msg.value;
				}
				if (methodName == 'lset') {
					list = app.stagePane.lookupOrCreateList(msg.name);
					if (list.isPersistent) list.contents = msg.value;
					if (list.visible) list.updateWatcher(list.contents.length, false, app.interp);
				}
				if (methodName == 'lappend') {
					list = app.stagePane.lookupOrCreateList(msg.name);
					if (list.isPersistent) {
						list.contents.push(msg.value);
					}
					if (list.visible) list.updateWatcher(list.contents.length, false, app.interp);
				}
				if (methodName == 'ldelete') {
					if (isNaN(msg.i)) return; // Check against list length as well
					list = app.stagePane.lookupOrCreateList(msg.name);
					if (list.isPersistent) {
						list.contents.splice(msg.i - 1, 1);
					}
					if (list.visible) list.updateWatcher(list.contents.length, false, app.interp);
				}
				if (methodName == 'lreplace') {
					if (isNaN(msg.i)) return; // Check against list length as well
					list = app.stagePane.lookupOrCreateList(msg.name);
					if (list.isPersistent) {
						list.contents.splice(msg.i - 1, 1, msg.value);
					}
					if (list.visible) list.updateWatcher(list.contents.length, false, app.interp);
				}
				if (methodName == 'linsert') {
					if (isNaN(msg.i)) return; // Check against list length as well
					list = app.stagePane.lookupOrCreateList(msg.name);
					if (list.isPersistent) {
						list.contents.splice(msg.i - 1, 0, msg.value);
					}
					if (list.visible) list.updateWatcher(list.contents.length, false, app.interp);
				}
			}
		}
	}

}}

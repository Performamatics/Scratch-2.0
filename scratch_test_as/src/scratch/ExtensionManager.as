// ExtensionManager.as
// John Maloney, September 2011
//
// Scratch extension manager. Maintains a list of all extensions in use and manages
// socket-based communications with local and server-based extension helper applications.

package scratch {
	import flash.events.*;
	import flash.net.*;
	import flash.utils.getTimer;
	import util.JSON_AB;

public class ExtensionManager {

	private const secsBetweenRetries:int = 5;

	private var app:Scratch;
	private var extensions:Object = new Object(); // extension name -> extension record
	private var lastOpenAttempt:int;

	public function ExtensionManager(app:Scratch) {
		this.app = app;
// xxx extensions disabled for now:
//		addExtension('Midi', '127.0.0.1', 1234); // for testing
//		addExtension('WeDo', '127.0.0.1', 4321); // for testing
	}

	public function addExtension(extensionName: String, host: String, port: int):void {
		if (extensions[extensionName] != null) return; // already added
		var ext:Extension = new Extension();
		ext.name = extensionName;
		ext.host = host,
		ext.port = port,
		extensions[extensionName] = ext;
	}

	public function call(extensionName:String, op:String, args:Array):int {
		var ext:Extension = extensions[extensionName];
		if (ext == null) return -1; // unknown extension
		if (!ext.socket.connected) return -1; // not connected to extension
		var request:Object = {method: op, params: args, id: ext.requestID++}
		var msg:String = JSON_AB.stringify(request, false); // encode without formatting to avoid CR's
		ext.socket.writeUTFBytes(msg + '\n');
		ext.socket.flush();
		return request.id;
	}

	public function getStateVar(extensionName:String, varName:String, defaultValue:*):* {
		var value:* = extensions[extensionName].stateVars[varName];
		return (value == undefined) ? defaultValue : value;
	}

	public function getReply(extensionName:String, id:int):Object {
		// Return the reply to the request with the given ID, and remove the
		// reply from the message queue. Return null if there is no reply with
		// the given ID in the queue.
		var ext:Extension = extensions[extensionName];
		if (ext == null) return null; // unknown extension
		for (var i:int = 0; i < ext.messages.length; i++) {
			var msg:Object = ext.messages[i];
			if (msg.id == id) {
				ext.messages = ext.messages.splice(i, 1); // remove message
				return msg;
			}
		}
		return null;
	}

	public function setExtensionHost(extensionName:String, host:String):void {
		var ext:Extension = extensions[extensionName];
		if (ext == null) return;
		closeExtensionSocket(ext);
		ext.host = host;
		openExtensionSockets();
	}

	public function step():void {
		if (((getTimer() - lastOpenAttempt) / 1000) > secsBetweenRetries) {
			openExtensionSockets();
			lastOpenAttempt = getTimer();
		}
		pollForUpdates();
	}

	private function pollForUpdates():void {
		for each (var ext:Extension in extensions) {
			if ((ext.socket != null) && (ext.socket.connected)) {
				var request:Object = {method: 'update-poll', params: []}
				var msg:String = JSON_AB.stringify(request, false); // encode without formatting to avoid CR's
				ext.socket.writeUTFBytes(msg + '\n');
				ext.socket.flush();
			}
		}
	}

	private function openExtensionSockets():void {
		// Attempt to open sockets to all extensions.
		for each (var ext:Extension in extensions) {
			if ((ext.socket != null) && (ext.socket.connected)) continue;
			var sock:Socket = new Socket();
			sock.addEventListener(Event.CONNECT, socketConnected);
			sock.addEventListener(IOErrorEvent.IO_ERROR, socketError);
			sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socketError);
			sock.addEventListener(ProgressEvent.SOCKET_DATA, socketData);
			sock.connect(ext.host, ext.port);
			ext.socket = sock;
		}
	}

	private function closeExtensionSocket(ext:Extension):void {
		if (ext.socket != null) {
			try { ext.socket.close() } catch (e:*) { }
			ext.socket = null;
		}
	}

	private function socketError(evt:Event):void {
		var ext:Extension = extensionForSocket(evt.target as Socket);
		if (ext != null) {
//			app.browserTrace('Could not connect to extension ' + ext.name + ' at ' + ext.host + ':' + ext.port);
			closeExtensionSocket(ext);
		}
	}

	private function socketConnected(evt:Event):void {
		var ext:Extension = extensionForSocket(evt.target as Socket);
		if (ext != null) {
			app.browserTrace('Connected to extension:' + ext.name);
			ext.buffer = '';
			ext.messages = [];
			ext.stateVars = new Object();
		}
	}

	private function socketData(evt:Event):void {
		var ext:Extension = extensionForSocket(evt.target as Socket);
		if (ext == null) return; // shouldn't happen
		ext.buffer += ext.socket.readUTFBytes(ext.socket.bytesAvailable);
		var i:int;
		while ((i = ext.buffer.indexOf('\n')) >= 0) {
			var line:String = ext.buffer.slice(0, i);
			ext.buffer = ext.buffer.slice(i + 1);
			if (line.length > 0) {
				var msg:Object = JSON_AB.parse(line);
				if (msg.method == 'update') updateVars(ext, msg);
				else saveReply(ext, msg);
			}
		}
	}

	private function updateVars(ext:Extension, msg:Object):void {
		// Update the state variables (e.g. sensor values) for this extension.
		// The msg argument is a JSON-rpc message object whose first parameter
		// should be an array of [varName, value] pairs.
		var pairs:Array = [];
		if ((msg.params is Array) &&
			(msg.params.length > 0) &&
			(msg.params[0] is Array)) {
				pairs = msg.params;
		}
		for each (var p:Array in pairs) {
			if ((p is Array) && (p.length == 2) && (p[0] is String)) {
				ext.stateVars[p[0]] = p[1];
			}
		}
	}

	private function saveReply(ext:Extension, msg:Object):void {
		// Record the given message if it is a valid JSON-rpc reply.
		if ((msg.method != null) &&
			(msg.id is int) &&
			(msg.error == null)) {
				ext.messages.push(msg);
		}
	}

	private function extensionForSocket(sock:Socket):Extension {
		// Return the extension that owns the given socket or null.
		for each (var ext:Extension in extensions) {
			if (ext.socket == sock) return ext;
		}
		return null;
	}

}}

// internal class to record extension state
class Extension {
	public var name:String;
	public var host:String;
	public var port:int;
	public var socket:flash.net.Socket;
	public var requestID:int;
	public var buffer:String = '';
	public var messages:Array = [];
	public var stateVars:Object = new Object();
}

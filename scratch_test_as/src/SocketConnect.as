// Matthew Vaughan Aug/30/2012
// Establishes a connection to Server
// To connect to jMusic

package {
	
	import flash.events.*;
	import flash.net.Socket;

/**
 * SocketClass which connects to server
 */ 
public class SocketConnect {
					
	// single Instance of SocketConnect - Singleton Pattern
	public static var socketConnect:SocketConnect = new SocketConnect();
	
	private var host:String = "localhost"; 	//This means we're connecting to our own computer (127.0.0.1)
	private var sock:Socket = new Socket(); //This is our socket
		
	public static function getInstance():SocketConnect {
		return socketConnect;
	}
	
	public function SocketConnect() {
		
/*		sock.addEventListener(Event.CONNECT,onConnect); //Called when the socket connects
		sock.addEventListener(Event.CLOSE,onClose); //Called when the socket is closed
		sock.addEventListener(IOErrorEvent.IO_ERROR,onError); //Called on a connection problem
		sock.addEventListener(ProgressEvent.SOCKET_DATA,onDataIn); //Called when data is received
*/					
		//sendData("test");	// DEBUG
	}
	
	// overloaded connect
	public function connectTo( host:String ):Boolean {
		this.host = host;
		return connect();
	}

	public function connect():Boolean {
		
		sock.connect(host,42001); //Pass the host variable from above and 42001 to connect()
		
		if ( sock.connected ) 
			return true;
		else 
			return false;
	}
	
	public function disconnect():void {
				
		if ( sock.connected ) {
			sock.close();
		}
	}
	
	public function sendData( data:String ):void {
		
		if ( sock.connected ) {
			sock.writeUTF( data );	
			sock.flush();					// Might not need this, but, as I understand it, windows doesn't do this explicitly. Matt Vaughan - Aug/28/2012
		}
		else {
			// do nothing or inform user there is no connection
		}
	}
	
	public function isConnected():Boolean {
		return sock.connected;
	}
/*	
	private function onConnect(e:Event):void
	{
		trace("Connected!")
	}
	
	private function onClose(e:Event):void
	{
		trace("Socket has been closed.")
	}
	
	private function onError(e:IOErrorEvent):void
	{
		trace("Oh no! Trouble connecting!")
	}
	
	private function onDataIn(e:ProgressEvent):void
	{
		//We'll just call another function to do our dirty work
		//getData()
	}
*/	
	
}}
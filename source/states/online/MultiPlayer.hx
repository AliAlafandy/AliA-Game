package states.online;

import haxe.Json;
import haxe.Timer;
import flixel.math.FlxMath;

#if sys
import sys.net.Socket;
import sys.net.Host;
import sys.thread.Thread;
import sys.thread.Mutex;
#end

#if js
import js.html.WebSocket;
import js.lib.ArrayBuffer;
#end

enum abstract PacketType(String) to String
{
	var HELLO = "hello";
	var WELCOME = "welcome";
	var JOIN_ROOM = "join_room";
	var ROOM_STATE = "room_state";
	var PLAYER_JOINED = "player_joined";
	var PLAYER_LEFT = "player_left";
	var PLAYER_UPDATE = "player_update";
	var PING = "ping";
	var PONG = "pong";
	var CHAT = "chat";
	var GAME_EVENT = "game_event";
	var DISCONNECT = "disconnect";
	var ERROR = "error";
}

enum ConnectionState
{
	DISCONNECTED;
	CONNECTING;
	CONNECTED;
	RECONNECTING;
}

class NetPacket
{
	public var type:String;
	public var data:Dynamic;
	public var timestamp:Float;

	public function new(type:String, data:Dynamic)
	{
		this.type = type;
		this.data = data;
		this.timestamp = Timer.stamp();
	}

	public function serialize():String
	{
		return Json.stringify({ type: type, data: data, timestamp: timestamp });
	}

	public static function parse(raw:String):NetPacket
	{
		var obj:Dynamic = Json.parse(raw);
		var packet = new NetPacket(obj.type, obj.data);
		packet.timestamp = obj.timestamp;
		return packet;
	}
}

class RemotePlayer
{
	public var id:String;
	public var name:String;
	public var x:Float = 0;
	public var y:Float = 0;
	public var targetX:Float = 0;
	public var targetY:Float = 0;
	public var animation:String = "idle";
	public var score:Int = 0;
	public var ping:Int = 0;
	public var connected:Bool = true;

	public function new(id:String, name:String)
	{
		this.id = id;
		this.name = name;
	}

	public function interpolate(elapsed:Float, speed:Float):Void
	{
		x = FlxMath.lerp(x, targetX, FlxMath.bound(speed * elapsed, 0, 1));
		y = FlxMath.lerp(y, targetY, FlxMath.bound(speed * elapsed, 0, 1));
	}
}

class MultiPlayer
{
	private static inline var MAX_RECONNECT_ATTEMPTS:Int = 5;
	private static inline var RECONNECT_BASE_DELAY:Float = 1.5;
	private static inline var HEARTBEAT_INTERVAL:Float = 3;
	private static inline var INTERPOLATION_SPEED:Float = 12;

	public static var instance:MultiPlayer;

	public var state(default, null):ConnectionState = DISCONNECTED;
	public var localPlayerId(default, null):String;
	public var localPlayerName:String = "Player";
	public var roomCode:String;
	public var players:Map<String, RemotePlayer> = new Map();
	public var currentPing(default, null):Int = 0;

	private var host:String;
	private var port:Int;
	private var listeners:Map<String, Array<Dynamic->Void>> = new Map();
	private var reconnectAttempts:Int = 0;
	private var heartbeatTimer:Float = 0;
	private var lastPingSentAt:Float = 0;
	private var awaitingPong:Bool = false;

	#if sys
	private var socket:Socket;
	private var recvThread:Thread;
	private var sendMutex:Mutex = new Mutex();
	private var incomingQueue:Array<NetPacket> = [];
	private var queueMutex:Mutex = new Mutex();
	private var shouldRun:Bool = false;
	#end

	#if js
	private var ws:WebSocket;
	#end

	public function new()
	{
		instance = this;
	}

	public function connect(host:String, port:Int, playerName:String):Void
	{
		if (state == CONNECTED || state == CONNECTING)
			return;

		this.host = host;
		this.port = port;
		this.localPlayerName = playerName;
		state = CONNECTING;
		reconnectAttempts = 0;

		#if js
		connectJs();
		#elseif sys
		connectSys();
		#end
	}

	public function disconnect():Void
	{
		if (state == DISCONNECTED)
			return;

		send(DISCONNECT, {});

		#if sys
		shouldRun = false;
		if (socket != null)
		{
			try socket.close() catch (e:Dynamic) {}
			socket = null;
		}
		#end

		#if js
		if (ws != null)
		{
			ws.close();
			ws = null;
		}
		#end

		state = DISCONNECTED;
		players.clear();
		emit("disconnected", {});
	}

	public function update(elapsed:Float):Void
	{
		if (state != CONNECTED)
			return;

		#if sys
		flushIncomingQueue();
		#end

		for (player in players)
			player.interpolate(elapsed, INTERPOLATION_SPEED);

		heartbeatTimer += elapsed;
		if (heartbeatTimer >= HEARTBEAT_INTERVAL)
		{
			heartbeatTimer = 0;
			sendPing();
		}
	}

	public function send(type:PacketType, data:Dynamic):Void
	{
		if (state != CONNECTED && type != HELLO)
			return;

		var packet = new NetPacket(type, data);
		var raw = packet.serialize();

		#if sys
		writeFrame(raw);
		#end

		#if js
		if (ws != null && ws.readyState == WebSocket.OPEN)
			ws.send(raw);
		#end
	}

	public function joinRoom(code:String):Void
	{
		roomCode = code;
		send(JOIN_ROOM, { code: code, name: localPlayerName });
	}

	public function sendPlayerUpdate(x:Float, y:Float, animation:String):Void
	{
		send(PLAYER_UPDATE, { x: x, y: y, animation: animation });
	}

	public function sendChat(message:String):Void
	{
		send(CHAT, { message: message });
	}

	public function sendGameEvent(name:String, payload:Dynamic):Void
	{
		send(GAME_EVENT, { name: name, payload: payload });
	}

	public function getPlayer(id:String):RemotePlayer
	{
		return players.exists(id) ? players.get(id) : null;
	}

	public function getPlayers():Array<RemotePlayer>
	{
		var list:Array<RemotePlayer> = [];
		for (player in players)
			list.push(player);
		return list;
	}

	public function isConnected():Bool
	{
		return state == CONNECTED;
	}

	public function on(event:String, callback:Dynamic->Void):Void
	{
		if (!listeners.exists(event))
			listeners.set(event, []);
		listeners.get(event).push(callback);
	}

	public function off(event:String, callback:Dynamic->Void):Void
	{
		if (!listeners.exists(event))
			return;
		listeners.get(event).remove(callback);
	}

	private function emit(event:String, data:Dynamic):Void
	{
		if (!listeners.exists(event))
			return;
		for (callback in listeners.get(event))
			callback(data);
	}

	private function sendPing():Void
	{
		lastPingSentAt = Timer.stamp();
		awaitingPong = true;
		send(PING, {});
	}

	private function handlePacket(packet:NetPacket):Void
	{
		switch (packet.type)
		{
			case WELCOME:
				localPlayerId = packet.data.id;
				state = CONNECTED;
				reconnectAttempts = 0;
				emit("connected", packet.data);

			case ROOM_STATE:
				players.clear();
				var remotePlayers:Array<Dynamic> = packet.data.players;
				for (entry in remotePlayers)
				{
					if (entry.id == localPlayerId)
						continue;
					var player = new RemotePlayer(entry.id, entry.name);
					player.x = entry.x;
					player.y = entry.y;
					player.targetX = entry.x;
					player.targetY = entry.y;
					players.set(entry.id, player);
				}
				emit("room_state", packet.data);

			case PLAYER_JOINED:
				var id:String = packet.data.id;
				if (id != localPlayerId && !players.exists(id))
				{
					var player = new RemotePlayer(id, packet.data.name);
					players.set(id, player);
					emit("player_joined", player);
				}

			case PLAYER_LEFT:
				var id:String = packet.data.id;
				if (players.exists(id))
				{
					var player = players.get(id);
					players.remove(id);
					emit("player_left", player);
				}

			case PLAYER_UPDATE:
				var id:String = packet.data.id;
				if (players.exists(id))
				{
					var player = players.get(id);
					player.targetX = packet.data.x;
					player.targetY = packet.data.y;
					player.animation = packet.data.animation;
				}

			case PONG:
				if (awaitingPong)
				{
					currentPing = Math.round((Timer.stamp() - lastPingSentAt) * 1000);
					awaitingPong = false;
				}

			case CHAT:
				emit("chat", packet.data);

			case GAME_EVENT:
				emit("game_event", packet.data);

			case ERROR:
				emit("error", packet.data);

			case DISCONNECT:
				disconnect();

			default:
				emit(packet.type, packet.data);
		}
	}

	#if sys
	private function connectSys():Void
	{
		try
		{
			socket = new Socket();
			socket.connect(new Host(host), port);
			socket.setBlocking(true);
			shouldRun = true;

			send(HELLO, { name: localPlayerName });

			recvThread = Thread.create(receiveLoop);
		}
		catch (e:Dynamic)
		{
			handleConnectionFailure();
		}
	}

	private function receiveLoop():Void
	{
		while (shouldRun && socket != null)
		{
			try
			{
				var lengthBytes = socket.input.read(4);
				var length = (lengthBytes.get(0) << 24) | (lengthBytes.get(1) << 16) | (lengthBytes.get(2) << 8) | lengthBytes.get(3);
				var body = socket.input.readString(length);
				var packet = NetPacket.parse(body);

				queueMutex.acquire();
				incomingQueue.push(packet);
				queueMutex.release();
			}
			catch (e:Dynamic)
			{
				shouldRun = false;
				queueMutex.acquire();
				incomingQueue.push(new NetPacket("__connection_lost", {}));
				queueMutex.release();
				break;
			}
		}
	}

	private function flushIncomingQueue():Void
	{
		queueMutex.acquire();
		var pending = incomingQueue.copy();
		incomingQueue = [];
		queueMutex.release();

		for (packet in pending)
		{
			if (packet.type == "__connection_lost")
				handleConnectionFailure();
			else
				handlePacket(packet);
		}
	}

	private function writeFrame(raw:String):Void
	{
		if (socket == null)
			return;

		sendMutex.acquire();
		try
		{
			var bytes = haxe.io.Bytes.ofString(raw);
			var length = bytes.length;

			var header = haxe.io.Bytes.alloc(4);
			header.set(0, (length >> 24) & 0xFF);
			header.set(1, (length >> 16) & 0xFF);
			header.set(2, (length >> 8) & 0xFF);
			header.set(3, length & 0xFF);

			socket.output.write(header);
			socket.output.write(bytes);
		}
		catch (e:Dynamic)
		{
			handleConnectionFailure();
		}
		sendMutex.release();
	}
	#end

	#if js
	private function connectJs():Void
	{
		ws = new WebSocket('ws://$host:$port');

		ws.onopen = function(_)
		{
			send(HELLO, { name: localPlayerName });
		};

		ws.onmessage = function(event:Dynamic)
		{
			var packet = NetPacket.parse(event.data);
			handlePacket(packet);
		};

		ws.onclose = function(_)
		{
			handleConnectionFailure();
		};

		ws.onerror = function(_)
		{
			handleConnectionFailure();
		};
	}
	#end

	private function handleConnectionFailure():Void
	{
		if (state == DISCONNECTED)
			return;

		state = RECONNECTING;
		players.clear();
		emit("connection_lost", {});

		if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS)
		{
			state = DISCONNECTED;
			emit("reconnect_failed", {});
			return;
		}

		reconnectAttempts++;
		var delay = RECONNECT_BASE_DELAY * reconnectAttempts;

		Timer.delay(function()
		{
			if (state == RECONNECTING)
			{
				#if js
				connectJs();
				#elseif sys
				connectSys();
				#end
			}
		}, Math.round(delay * 1000));
	}
}

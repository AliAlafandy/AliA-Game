package states.online;

import haxe.Timer;
import flixel.math.FlxMath;

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

/**
 * AliA-Online REST multiplayer transport.
 * The host argument is the HTTPS base URL, e.g. https://alia-server.onrender.com.
 */
class MultiPlayer
{
    private static inline var POLL_INTERVAL:Float = 0.45;
    private static inline var INTERPOLATION_SPEED:Float = 12;

    public static var instance:MultiPlayer;
    public var state(default, null):ConnectionState = DISCONNECTED;
    public var localPlayerId(default, null):String;
    public var localPlayerName:String = "Player";
    public var roomCode:String;
    public var players:Map<String, RemotePlayer> = new Map();
    public var currentPing(default, null):Int = 0;

    private var baseUrl:String = "";
    private var listeners:Map<String, Array<Dynamic->Void>> = new Map();
    private var pollTimer:Float = 0;
    private var lastMessageId:Int = 0;
    private var pollInFlight:Bool = false;
    private var updateInFlight:Bool = false;
    private var lastRequestAt:Float = 0;

    public function new()
    {
        instance = this;
    }

    public function connect(host:String, port:Int, playerName:String):Void
    {
        if (state == CONNECTED || state == CONNECTING) return;
        baseUrl = StringTools.endsWith(host, "/") ? host.substr(0, host.length - 1) : host;
        localPlayerName = playerName == null || StringTools.trim(playerName).length == 0 ? "Player" : StringTools.trim(playerName);
        state = CONNECTING;
        var started = Timer.stamp();

        Network.postJson(baseUrl + "/api/game/connect", { name: localPlayerName }, function(data:Dynamic) {
            if (state != CONNECTING) return;
            if (data == null || data.id == null) {
                fail("Server did not return a player session.");
                return;
            }
            localPlayerId = Std.string(data.id);
            state = CONNECTED;
            lastRequestAt = Timer.stamp();
            currentPing = Std.int((lastRequestAt - started) * 1000);
            emit("connected", data);
        }, function(reason:String) {
            if (state == CONNECTING) fail(reason);
        });
    }

    public function disconnect():Void
    {
        if (state == DISCONNECTED) return;
        var id = localPlayerId;
        state = DISCONNECTED;
        localPlayerId = null;
        roomCode = null;
        players.clear();
        if (id != null && baseUrl.length > 0)
            Network.postJson(baseUrl + "/api/game/disconnect", { playerId: id }, function(_) {}, function(_) {});
        emit("disconnected", {});
    }

    public function update(elapsed:Float):Void
    {
        if (state != CONNECTED) return;
        for (player in players) player.interpolate(elapsed, INTERPOLATION_SPEED);
        pollTimer += elapsed;
        if (roomCode != null && pollTimer >= POLL_INTERVAL && !pollInFlight) {
            pollTimer = 0;
            pollRoom();
        }
    }

    public function send(type:PacketType, data:Dynamic):Void
    {
        switch (type) {
            case JOIN_ROOM: joinRoom(data != null && Reflect.hasField(data, "code") ? Std.string(data.code) : "");
            case PLAYER_UPDATE:
                if (data != null) sendPlayerUpdate(data.x, data.y, data.animation);
            case CHAT:
                if (data != null) sendChat(Std.string(data.message));
            case DISCONNECT: disconnect();
            default:
                // HELLO/WELCOME/PING are handled by the REST session lifecycle.
        }
    }

    public function joinRoom(code:String):Void
    {
        if (state != CONNECTED) {
            emit("error", { message: "Connect to AliA-Online first." });
            return;
        }
        var cleanCode = code == null ? "" : StringTools.trim(code).toUpperCase();
        if (cleanCode.length == 0) {
            emit("error", { message: "Room code is required." });
            return;
        }
        Network.postJson(baseUrl + "/api/game/join", { playerId: localPlayerId, code: cleanCode }, function(data:Dynamic) {
            roomCode = Std.string(data.roomCode);
            players.clear();
            applyPlayers(data.players);
            lastMessageId = 0;
            pollTimer = POLL_INTERVAL;
            emit("room_state", data);
        }, function(reason:String) emit("error", { message: reason }));
    }

    public function sendPlayerUpdate(x:Float, y:Float, animation:String):Void
    {
        if (state != CONNECTED || roomCode == null || updateInFlight) return;
        updateInFlight = true;
        Network.postJson(baseUrl + "/api/game/update", {
            playerId: localPlayerId, x: x, y: y, animation: animation
        }, function(_) {
            updateInFlight = false;
        }, function(reason:String) {
            updateInFlight = false;
            if (StringTools.startsWith(reason, "Game session expired")) fail(reason);
            else emit("error", { message: reason });
        });
    }

    public function sendChat(message:String):Void
    {
        if (state != CONNECTED || roomCode == null) return;
        Network.postJson(baseUrl + "/api/game/chat", { playerId: localPlayerId, message: message },
            function(_) {}, function(reason:String) emit("error", { message: reason }));
    }

    public function sendGameEvent(name:String, payload:Dynamic):Void
    {
        // Reserved for future server-authoritative gameplay events.
        emit("error", { message: "Game events are not enabled on AliA-Online yet." });
    }

    public function getPlayer(id:String):RemotePlayer
        return players.exists(id) ? players.get(id) : null;

    public function getPlayers():Array<RemotePlayer>
    {
        var result:Array<RemotePlayer> = [];
        for (player in players) result.push(player);
        return result;
    }

    public function isConnected():Bool return state == CONNECTED;

    public function on(event:String, callback:Dynamic->Void):Void
    {
        if (!listeners.exists(event)) listeners.set(event, []);
        listeners.get(event).push(callback);
    }

    public function off(event:String, callback:Dynamic->Void):Void
    {
        if (!listeners.exists(event)) return;
        if (callback == null) listeners.remove(event);
        else listeners.get(event).remove(callback);
    }

    private function pollRoom():Void
    {
        if (pollInFlight || state != CONNECTED || roomCode == null) return;
        pollInFlight = true;
        var started = Timer.stamp();
        Network.postJson(baseUrl + "/api/game/poll", {
            playerId: localPlayerId, afterMessageId: lastMessageId
        }, function(data:Dynamic) {
            pollInFlight = false;
            currentPing = Std.int((Timer.stamp() - started) * 1000);
            if (data == null) return;
            var previous = players.copy();
            players.clear();
            applyPlayers(data.players);
            for (id in players.keys()) {
                if (!previous.exists(id)) emit("player_joined", players.get(id));
            }
            for (id in previous.keys()) {
                if (!players.exists(id)) emit("player_left", previous.get(id));
            }
            if (data.messages != null) {
                for (message in (cast data.messages:Array<Dynamic>)) {
                    if (message.id != null && Std.int(message.id) > lastMessageId)
                        lastMessageId = Std.int(message.id);
                    emit("chat", message);
                }
            }
        }, function(reason:String) {
            pollInFlight = false;
            if (StringTools.startsWith(reason, "Game session expired")) fail(reason);
            else emit("error", { message: reason });
        });
    }

    private function applyPlayers(entries:Dynamic):Void
    {
        if (entries == null) return;
        for (entry in (cast entries:Array<Dynamic>)) {
            if (entry == null || entry.id == null || Std.string(entry.id) == localPlayerId) continue;
            var id = Std.string(entry.id);
            var player = players.exists(id) ? players.get(id) : new RemotePlayer(id, Std.string(entry.name));
            player.name = entry.name == null ? "Player" : Std.string(entry.name);
            player.targetX = entry.x == null ? 0 : entry.x;
            player.targetY = entry.y == null ? 0 : entry.y;
            player.animation = entry.animation == null ? "idle" : Std.string(entry.animation);
            if (!players.exists(id)) {
                player.x = player.targetX;
                player.y = player.targetY;
            }
            players.set(id, player);
        }
    }

    private function fail(reason:String):Void
    {
        state = DISCONNECTED;
        localPlayerId = null;
        roomCode = null;
        players.clear();
        emit("error", { message: reason });
        emit("connection_lost", { message: reason });
        emit("reconnect_failed", {});
    }

    private function emit(event:String, data:Dynamic):Void
    {
        if (!listeners.exists(event)) return;
        for (callback in listeners.get(event).copy()) callback(data);
    }
}

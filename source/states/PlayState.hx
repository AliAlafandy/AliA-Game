package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import data.objects.Player;
import states.menus.CharacterState;

import data.backend.StageData;

import states.online.MultiPlayer;
import states.online.MultiPlayer.RemotePlayer;

import substates.PauseSubState;

#if mobile
import mobile.data.MobileInputManager;
#end

#if DISCORD_ALLOWED
import data.debug.DiscordRPC;
#end

#if HSCRIPT_ALLOWED
import data.scripts.HScript;
import tea.SScript;
#end

class RemotePlayerGhost extends Player
{
	public var netId:String;
	public var nameTag:FlxText;

	public function new(netId:String, name:String)
	{
		super(0, 0, 'Ellawy', false);
		this.netId = netId;

		nameTag = new FlxText(0, 0, 120, name, 12);
		nameTag.setFormat(null, 12, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (nameTag != null)
		{
			nameTag.setPosition(x + (width / 2) - (nameTag.width / 2), y - 20);
		}
	}
}

class PlayState extends GameState
{
	public var player:Player;
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var curStage:String = 'ATown';

	private var elapsedTime:Float = 0;
	private var rpcTimer:Float = 0;
	private var netUpdateTimer:Float = 0;

	private static inline var NET_UPDATE_INTERVAL:Float = 0.05;
	private static inline var CHAT_LOG_MAX:Int = 6;
	private static inline var CHAT_LOG_DURATION:Float = 6;

	public static var isOnlineMode:Bool = false;
	private var remoteGhosts:Map<String, RemotePlayerGhost> = new Map();
	private var ghostGroup:FlxTypedGroup<RemotePlayerGhost>;
	private var nameTagGroup:FlxTypedGroup<FlxText>;
	private var chatOverlay:FlxText;
	private var chatLog:Array<String> = [];
	private var chatInputActive:Bool =false;
	private var chatBuffer:String = "";

	private var paused:Bool = false;
	private var testGround:FlxSprite;
	private var groundSegments:FlxTypedGroup<FlxSprite>;
	private var grassTop:FlxSprite;
	private var backgroundLayers:FlxTypedGroup<FlxSprite>;

	#if mobile
	public var manager:MobileInputManager;
	#end

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	public var debugGroup:FlxTypedGroup<FlxText>;
	public static var instance:PlayState;

	public function new():Void
	{
		super();
		instance = this;

		#if mobile
		manager = new MobileInputManager();
		#end
	}

	override public function create():Void
	{
		super.create();

		debugGroup = new FlxTypedGroup<FlxText>();
		add(debugGroup);

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
		{
			for (file in Paths.readDirectory(folder))
			{
				#if HSCRIPT_ALLOWED
				var lowerFile = file.toLowerCase();
				if (lowerFile.endsWith('.ellawy'))
				{
					initHScript(folder + file);
				}
				#end
			}
		}

		// Sonic-inspired scenery built from small generated shapes. Avoid
		// stretching a placeholder/missing texture across the entire screen.
		FlxG.camera.bgColor = FlxColor.fromRGB(105, 190, 255);
		backgroundLayers = new FlxTypedGroup<FlxSprite>();
		add(backgroundLayers);

		// Distant rolling hills. Each hill uses a modest texture size and a
		// slower scroll factor to create a simple parallax effect.
		var hillColors:Array<FlxColor> = [
			FlxColor.fromRGB(90, 190, 100),
			FlxColor.fromRGB(55, 160, 80),
			FlxColor.fromRGB(40, 135, 70)
		];
		for (i in 0...18)
		{
			var hill = new FlxSprite(-900 + i * 420, 210 + (i % 3) * 28);
			hill.makeGraphic(840, 420, FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawCircle(hill, 420, 420, 390, hillColors[i % hillColors.length]);
			hill.scrollFactor.set(0.35, 0.55);
			backgroundLayers.add(hill);
		}

		// Soft cloud clusters behind the hills.
		for (i in 0...14)
		{
			var cloud = new FlxSprite(i * 560 - 300, 65 + (i % 4) * 35);
			cloud.makeGraphic(260, 100, FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawCircle(cloud, 75, 60, 38, FlxColor.WHITE);
			FlxSpriteUtil.drawCircle(cloud, 125, 42, 48, FlxColor.WHITE);
			FlxSpriteUtil.drawCircle(cloud, 180, 60, 36, FlxColor.WHITE);
			cloud.scrollFactor.set(0.12, 0.08);
			backgroundLayers.add(cloud);
		}

		// Keep textures small for mobile GPUs; tile the ground across the level.
		var groundY:Float = FlxG.height - 48;
		groundSegments = new FlxTypedGroup<FlxSprite>();
		add(groundSegments);
		for (i in 0...34)
		{
			var dirt = new FlxSprite(-2048 + i * 1024, groundY);
			dirt.makeGraphic(1024, 48, FlxColor.fromRGB(130, 78, 42));
			dirt.immovable = true;
			dirt.allowCollisions = FlxDirectionFlags.UP;
			groundSegments.add(dirt);

			var grass = new FlxSprite(-2048 + i * 1024, groundY);
			grass.makeGraphic(1024, 10, FlxColor.fromRGB(70, 180, 65));
			add(grass);
		}
		testGround = groundSegments.members[0];

		var characterName:String = CharacterState.selectedCharacter;
		if (characterName == null || characterName.length == 0)
		{
			characterName = Player.DEFAULT_CHARACTER;
		}

		// Ellawy is the default character; other registered characters remain
		// selectable. Enlarge the sprite for a readable platform-game camera.
		player = new Player(500, 100, characterName, false);
		player.scale.set(1, 1);
		player.updateHitbox();
		player.y = groundY - player.height;
		player.velocity.set(0, 0);
		player.grounded = true;
		player.touching = FlxDirectionFlags.FLOOR;
		add(player);

		FlxG.camera.follow(player, LOCKON, 0.05);

		FlxG.camera.setScrollBounds(0, 10000, 0, FlxG.height);

		FlxG.camera.deadzone = new flixel.math.FlxRect(
			(FlxG.width / 2) - 100, 
			(FlxG.height / 2) - 100, 
			200, 
			200
		);

		FlxG.sound.music.resume();

		#if mobile
		addCustomDPad('EXITE', 'PLAY');
		addCustomDPadCam();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Play - Ali Alafandy Game', null);
		#end

		isOnlineMode = (MultiPlayer.instance != null && MultiPlayer.instance.isConnected());

		if (isOnlineMode)
			setupOnlineMode();
	}

	private function setupOnlineMode():Void
	{
		ghostGroup = new FlxTypedGroup<RemotePlayerGhost>();
		nameTagGroup = new FlxTypedGroup<FlxText>();

		add(ghostGroup);
		add(nameTagGroup);

		chatOverlay = new FlxText(10, 70, FlxG.width - 20, "", 14);
		chatOverlay.setFormat(null, 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(chatOverlay);

		for (remote in MultiPlayer.instance.getPlayers())
		{
			spawnGhost(remote);
		}

		MultiPlayer.instance.on("player_joined", onRemotePlayerJoined);
		MultiPlayer.instance.on("player_left", onRemotePlayerLeft);
		MultiPlayer.instance.on("chat", onRemoteChat);
		MultiPlayer.instance.on("connection_lost", onConnectionLost);

		#if (js || sys)
		openfl.Lib.current.stage.addEventListener(openfl.events.TextEvent.TEXT_INPUT, onChatTextInput);
		#end
	}

	private function spawnGhost(remote:RemotePlayer):Void
	{
		if (remoteGhosts.exists(remote.id))
		{
			return;
		}

		var ghost = new RemotePlayerGhost(remote.id, remote.name);
		ghost.x = remote.x;
		ghost.y = remote.y;
		remoteGhosts.set(remote.id, ghost);
		ghostGroup.add(ghost);
		nameTagGroup.add(ghost.nameTag);
	}

	private function removeGhost(netId:String):Void
	{
		if (!remoteGhosts.exists(netId))
		{
			return;
		}

		var ghost = remoteGhosts.get(netId);
		ghostGroup.remove(ghost, true);
		nameTagGroup.remove(ghost.nameTag, true);
		remoteGhosts.remove(netId);
		ghost.destroy();
	}

	private function onRemotePlayerJoined(remote:RemotePlayer):Void
	{
		spawnGhost(remote);
		pushChatLog('* ${remote.name} joined');
	}

	private function onRemotePlayerLeft(remote:RemotePlayer):Void
	{
		removeGhost(remote.id);
		pushChatLog('* ${remote.name} left');
	}

	private function onRemoteChat(data:Dynamic):Void
	{
		pushChatLog('${data.name}: ${data.message}');
	}

	private function onConnectionLost(_:Dynamic):Void
	{
		pushChatLog('* Connection lost, reconnecting...');
	}

	private function pushChatLog(line:String):Void
	{
		chatLog.push(line);

		if (chatLog.length > CHAT_LOG_MAX)
		{
			chatLog.shift();
		}

		if (chatOverlay != null)
		{
			chatOverlay.text = chatLog.join("\n");
		}
	}

	#if HSCRIPT_ALLOWED
	public function addTextToDebug(text:String, color:FlxColor)
	{
		if (debugGroup == null)
		{
			return;
		}

		var newText:flixel.text.FlxText = debugGroup.recycle(flixel.text.FlxText, function()
				{
					var txt = new flixel.text.FlxText(10, 0, 0, "", 12);
					txt.setFormat(null, 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
					return txt;
				}
			);

		newText.text = text;
		newText.color = color;
		newText.alpha = 1;
		newText.setPosition(10, 8);

		debugGroup.forEachAlive(function(spr:flixel.text.FlxText)
			{
				if (spr != newText)
				{
					spr.y += newText.height + 2;
				}
			}
		);

		debugGroup.add(newText);

		flixel.util.FlxTimer.wait(6, function()
			{
				if (newText != null && newText.alive)
				{
					newText.kill();
				}
			}
		);
	}
	#end

	override public function update(elapsed:Float):Void
	{
		elapsedTime += elapsed;
		rpcTimer += elapsed;
		handleInput();

		if (!paused && player != null && testGround != null)
		{
			FlxG.collide(player, groundSegments);
			player.updateGroundState();
		}

		#if DISCORD_ALLOWED
		if (rpcTimer >= 1)
		{
			rpcTimer = 0;
			DiscordClient.changePresence('Playing Ali-A Game\n' + 'Play - ' + 'Time: ' + Std.int(elapsedTime), null);
		}
		#end

		if (isOnlineMode)
		{
			updateOnlineMode(elapsed);
		}

		#if HSCRIPT_ALLOWED
		callOnScripts('onUpdate', [elapsed]);
		#end

		if (!paused && (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.P
				#if mobile
				#if android
				|| FlxG.android.justReleased.BACK || customDPad.pauseButton.justPressed
				#else
				|| customDPad.pauseButton.justPressed
				#end
				#end
			)
		)
		{
			FlxG.sound.play(Paths.sound('cancel_sound'));
			openPauseMenu();
			return;
		}

		super.update(elapsed);
	}

	private function handleInput():Void
	{
		if (chatInputActive || paused || player == null)
		{
			return;
		}

		var leftPressed:Bool = FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A;
		var rightPressed:Bool = FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
		var jumpPressed:Bool = FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W;

		#if mobile
		if (customDPad != null)
		{
			leftPressed = leftPressed || customDPad.buttonLeft.justPressed || customDPad.buttonLeft.pressed;
			rightPressed = rightPressed || customDPad.buttonRight.justPressed || customDPad.buttonRight.pressed;
			jumpPressed = jumpPressed || customDPad.jumpButton.justPressed || customDPad.jumpButton.pressed;
		}
		#end

		var direction:Float = 0;

		if (leftPressed)
		{
			direction -= 1;
		}

		if (rightPressed)
		{
			direction += 1;
		}

		player.moveCharacter(direction, jumpPressed);

		#if HSCRIPT_ALLOWED
		callOnScripts('onhandleInput');
		#end
	}

	private function updateOnlineMode(elapsed:Float):Void
	{
		if (MultiPlayer.instance == null)
		{
			return;
		}

		MultiPlayer.instance.update(elapsed);
		netUpdateTimer += elapsed;

		if (netUpdateTimer >= NET_UPDATE_INTERVAL)
		{
			netUpdateTimer = 0;
			var animName:String = 'idle';

			if (player != null && player.animation.curAnim != null)
			{
				animName = player.animation.curAnim.name;
			}

			if (player != null)
			{
				MultiPlayer.instance.sendPlayerUpdate(player.x, player.y, animName);
			}
		}

		for (remote in MultiPlayer.instance.getPlayers())
		{
			var ghost = remoteGhosts.get(remote.id);
			if (ghost == null)
				continue;

			ghost.x = remote.x;
			ghost.y = remote.y;

			if (ghost.animation.curAnim == null || ghost.animation.curAnim.name != remote.animation)
			{
				if (ghost.animation.exists(remote.animation))
				{
					ghost.animation.play(remote.animation);
				}
			}
		}

		if (chatInputActive)
		{
			handleChatControlKeys();
		} else if (FlxG.keys.justPressed.T) {
			toggleChatInput(true);
		}
	}

	private function toggleChatInput(active:Bool):Void
	{
		chatInputActive = active;
		chatBuffer = "";
	}

	private function handleChatControlKeys():Void
	{
		if (FlxG.keys.justPressed.ENTER)
		{
			if (chatBuffer.length > 0)
			{
				MultiPlayer.instance.sendChat(chatBuffer);
				pushChatLog('${MultiPlayer.instance.localPlayerName}: $chatBuffer');
			}
			toggleChatInput(false);
		} else if (FlxG.keys.justPressed.ESCAPE) {
			toggleChatInput(false);
		} else if (FlxG.keys.justPressed.BACKSPACE && chatBuffer.length > 0) {
			chatBuffer = chatBuffer.substr(0, chatBuffer.length - 1);
		}
	}

	#if (js || sys)
	private function onChatTextInput(event:openfl.events.TextEvent):Void
	{
		if (!chatInputActive)
			return;

		if (event.text.charCodeAt(0) >= 32 && chatBuffer.length < 96)
		{
			chatBuffer += event.text;
		}
	}
	#end

	private function leaveOnlineMode():Void
	{
		if (!isOnlineMode)
			return;

		if (MultiPlayer.instance == null)
		{
			return;
		}

		MultiPlayer.instance.off("player_joined", onRemotePlayerJoined);
		MultiPlayer.instance.off("player_left", onRemotePlayerLeft);
		MultiPlayer.instance.off("chat", onRemoteChat);
		MultiPlayer.instance.off("connection_lost", onConnectionLost);

		#if (js || sys)
		openfl.Lib.current.stage.removeEventListener(openfl.events.TextEvent.TEXT_INPUT, onChatTextInput);
		#end
	}

	#if HSCRIPT_ALLOWED
	public function startScriptsNamed(scriptFile:String)
	{
		if (!scriptFile.toLowerCase().endsWith('.ellawy'))
		{
			var lastDot = scriptFile.lastIndexOf('.');
			if (lastDot != -1)
			{
				scriptFile = scriptFile.substr(0, lastDot) + '.ellawy';
			} else {
				scriptFile += '.ellawy';
			}
		}

		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad))
		{
			scriptToLoad = Paths.getSharedPath(scriptFile);
		}
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if (FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad))
			{
				return false;
			}

			initHScript(scriptToLoad);
			return true;
		}

		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var finalFilePath:String = file;

			#if ELLAWY_ALLOWED
			if (file.toLowerCase().endsWith('.ellawy'))
			{
				var sourceCode = sys.io.File.getContent(file);
				var compiledHaxe = ellawy.Compiler.compileSource(sourceCode, file);
				var cachePath:String = file.substr(0, file.lastIndexOf('.')) + '_cache.hx';

				sys.io.File.saveContent(cachePath, compiledHaxe);
				finalFilePath = cachePath;
			}
			#end

			var newScript:HScript = new HScript(null, finalFilePath);
			if (newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING ($file): ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);

			if (newScript.exists('onGame'))
			{
				var callValue = newScript.call('onGame');
				if (!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if (len <= 0)
							{
								len = e.message.length;
							}

							addTextToDebug('ERROR ($file: onGame) - ${e.message.substr(0, len)}', FlxColor.RED);
						}
					}

					newScript.destroy();
					hscriptArray.remove(newScript);
				}
			}
		}
		catch (e)
		{
			var len:Int = e.message.indexOf('\n') + 1;
			if (len <= 0)
			{
				len = e.message.length;
			}

			addTextToDebug('ERROR - ' + e.message.substr(0, len), FlxColor.RED);

			var newScript:HScript = cast(SScript.global.get(file), HScript);
			if (newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = 0;

		if (args == null)
			args = [];

		if (exclusions == null)
			exclusions = [];

		if (excludeValues == null)
			excludeValues = [];

		return callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = null;

		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = [];

		if (excludeValues == null)
			excludeValues = [];

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for (i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
			{
				continue;
			}

			try
			{
				var callValue = script.call(funcToCall, args);
				if (!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if (e != null)
					{
						var errLen:Int = e.message.indexOf('\n') + 1;
						if (errLen <= 0)
						{
							errLen = e.message.length;
						}

						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, errLen), FlxColor.RED);
					}
				} else {
					var myValue:Dynamic = callValue.returnValue;
					if (myValue != null && !excludeValues.contains(myValue))
					{
						returnVal = myValue;
					}
				}
			}
			catch (e)
			{
				addTextToDebug('ERROR (${funcToCall}) - ${e.message}', FlxColor.RED);
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		if (exclusions == null)
			exclusions = [];

		setOnHScript( variable, arg, exclusions);
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = [];

		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin))
			{
				continue;
			}

			if (!instancesExclude.contains(variable))
			{
				instancesExclude.push(variable);
			}

			script.set(variable, arg);
		}
		#end
	}

	public function openPauseMenu():Void
	{
		if (paused)
			return;

		paused = true;
		FlxG.sound.music.pause();
		openSubState(new PauseSubState());

		#if mobile
		removeCustomDPad();
		#end
	}

	override public function closeSubState():Void
	{
		paused = false;
		FlxG.sound.music.resume();
		super.closeSubState();

		#if mobile
		addCustomDPad('EXITE', 'PLAY');
		addCustomDPadCam();
		#end
	}

	override public function destroy():Void
	{
		leaveOnlineMode();

		if (remoteGhosts != null)
		{
			for (id in remoteGhosts.keys())
			{
				removeGhost(id);
			}
		}

		if (testGround != null)
		{
			testGround.kill();
			testGround.destroy();
			testGround = null;
		}

		player = null;

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
		{
			if (script != null)
			{
				script.call('onDestroy');

				#if sys
				var originPath:String = script.origin;
				if (originPath != null && originPath.endsWith('_cache.hx'))
				{
					if (sys.FileSystem.exists(originPath))
					{
						try
						{
							sys.FileSystem.deleteFile(originPath);
						}
						catch (e:Dynamic) {}
					}
				}
				#end

				script.destroy();
			}
		}

		while (hscriptArray.length > 0)
		{
			hscriptArray.pop();
		}
		#end

		super.destroy();
	}
}

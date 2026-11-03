package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxSave;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import data.objects.Player;
import states.menus.CharacterState;

import data.backend.StageData;
import data.backend.StageData.LevelBin;

import states.online.MultiPlayer;
import states.online.MultiPlayer.RemotePlayer;

import substates.PauseSubState;

#if mobile
import mobile.data.MobileInputManager;
#end

#if DISCORD_ALLOWED
import data.debug.DiscordRPC;
#end

#if ELLAWY_ALLOWED
import data.scripts.GameEllawyScript;
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
	public var partner:Player;
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var curStage:String = 'ATown';
	public static var saveSlot:Int = 0;
	public static var noSave:Bool = true;

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
	private var flashGroup:FlxTypedGroup<FlxSprite>;
	private var levelData:LevelBin;
	private var flashCount:Int = 0;

	public var timer:FlxText;
	public var score:FlxText;
	public var flash:FlxText;

	#if mobile
	public var manager:MobileInputManager;
	#end

	#if ELLAWY_ALLOWED
	public var ellawyScripts:Array<GameEllawyScript> = [];
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

		#if ELLAWY_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
        {
            for (file in Paths.readDirectory(folder))
            {
                if (file.toLowerCase().endsWith('.ellawy'))
                {
                    initEllawyScript(folder + file);
                }
            }
        }
		#end

		levelData = LevelBin.load(curStage);

		// ATown street scene: blue sky, outlined city blocks, clouds, sun,
		// street lamps, a tiled sidewalk and a dark road. All scenery is
		// generated from lightweight sprites so no external stage image is needed.
		FlxG.camera.bgColor = FlxColor.fromRGB(105, 218, 245);
		backgroundLayers = new FlxTypedGroup<FlxSprite>();
		add(backgroundLayers);

		var worldWidth:Float = 2920;
		var segmentWidth:Int = 730;

		// Sun and cloud clusters in the far background.
		for (segment in 0...4)
		{
			var baseX:Float = segment * segmentWidth;
			addStageCircle(baseX + 615, 18, 104, FlxColor.BLACK, 0.12, 0.08);
			addStageCircle(baseX + 620, 22, 88, FlxColor.YELLOW, 0.12, 0.08);

			for (cloudIndex in 0...2)
			{
				var cloudX:Float = baseX + 35 + cloudIndex * 345;
				var cloudY:Float = 12 + ((segment + cloudIndex) % 2) * 12;
				addStageCircle(cloudX, cloudY + 18, 48, FlxColor.BLACK, 0.10, 0.06);
				addStageCircle(cloudX + 42, cloudY, 58, FlxColor.BLACK, 0.10, 0.06);
				addStageCircle(cloudX + 92, cloudY + 18, 48, FlxColor.BLACK, 0.10, 0.06);
				addStageCircle(cloudX + 5, cloudY + 20, 43, FlxColor.WHITE, 0.10, 0.06);
				addStageCircle(cloudX + 45, cloudY + 5, 51, FlxColor.WHITE, 0.10, 0.06);
				addStageCircle(cloudX + 92, cloudY + 20, 42, FlxColor.WHITE, 0.10, 0.06);
			}

			// City skyline: thick dark outlines with bright flat building colors.
			addStageBuilding(baseX - 4, 148, 205, 326, 0xFF990000);
			addStageBuilding(baseX + 198, 244, 168, 230, 0xFFFFE000);
			addStageBuilding(baseX + 363, 190, 188, 284, 0xFF888888);
			addStageBuilding(baseX + 548, 232, 102, 242, 0xFF00BDBD);
			addStageBuilding(baseX + 648, 268, 84, 206, 0xFF00C900);

			// Street lamp in front of the skyline.
			addStageRect(baseX + 510, 215, 19, 310, FlxColor.BLACK, 0.9, 1);
			addStageRect(baseX + 516, 226, 7, 292, 0xFFAAAAAA, 0.9, 1);
			addStageCircle(baseX + 476, 148, 83, FlxColor.BLACK, 0.9, 1);
			addStageCircle(baseX + 483, 156, 68, 0xFF777777, 0.9, 1);
			addStageCircle(baseX + 496, 176, 38, FlxColor.BLACK, 0.9, 1);
			addStageCircle(baseX + 502, 182, 26, 0xFF77C8FF, 0.9, 1);
		}

		// Sidewalk and road are drawn separately from the collision floor.
		addStageRect(0, 468, Std.int(worldWidth), 98, FlxColor.BLACK, 1, 1);
		addStageRect(0, 475, Std.int(worldWidth), 84, 0xFFCCCCCC, 1, 1);
		for (stripeX in 0...12)
		{
			var stripe = new FlxSprite(stripeX * 245 - 35, 472);
			stripe.makeGraphic(12, 112, FlxColor.BLACK);
			stripe.angle = 42;
			stripe.scrollFactor.set(1, 1);
			backgroundLayers.add(stripe);
		}
		addStageRect(0, 562, Std.int(worldWidth), 158, FlxColor.BLACK, 1, 1);
		for (laneX in 0...8)
		{
			addStageRect(laneX * 365 + 18, 624, 252, 44, FlxColor.BLACK, 1, 1);
			addStageRect(laneX * 365 + 28, 630, 232, 32, FlxColor.WHITE, 1, 1);
		}

		// Draw authored background images over the procedural fallback when supplied by Level.bin.
		StageData.addLevelImages(curStage, backgroundLayers);
		if (levelData != null)
			levelData.addBackgrounds(backgroundLayers);

		// Invisible collision strips sit at the top of the sidewalk.
		// The visible road and pavement are scenery only.
		var groundY:Float = (levelData != null && levelData.groundY >= 0) ? levelData.groundY : 562;
		groundSegments = new FlxTypedGroup<FlxSprite>();
		add(groundSegments);

		if (StageData.floorCollider != null)
		{
			groundSegments.add(StageData.floorCollider);
			testGround = StageData.floorCollider;
			groundY = StageData.floorCollider.y;
		}
		else
		{
			for (segment in 0...4)
			{
				var floor = new FlxSprite(segment * segmentWidth, groundY);
				floor.makeGraphic(segmentWidth, 24, FlxColor.TRANSPARENT);
				floor.immovable = true;
				floor.allowCollisions = FlxDirectionFlags.UP;
				groundSegments.add(floor);
			}
			testGround = groundSegments.members[0];
		}
		var characterName:String = CharacterState.selectedCharacter;
		if (characterName == null || characterName.length == 0)
		{
			characterName = Player.DEFAULT_CHARACTER;
		}

		var mainChar:String = characterName;
		var partnerChar:String = "";

		if (characterName == "Ellawy+")
		{
			mainChar = "Ellawy";
			partnerChar = "Hamedo";
		}

		var spawnX:Float = levelData != null ? levelData.playerX : 500;
		var hasCustomSpawn:Bool = levelData != null && levelData.playerY >= 0;
		var spawnY:Float = hasCustomSpawn ? levelData.playerY : groundY;
		player = new Player(spawnX, spawnY, mainChar, false);
		player.updateHitbox();
		if (!hasCustomSpawn) player.y = groundY - player.height;
		player.velocity.set(0, 0);
		player.grounded = !hasCustomSpawn;
		if (!hasCustomSpawn) player.touching = FlxDirectionFlags.FLOOR;
		add(player);

		if (partnerChar != "")
		{
			partner = new Player(450, 130, partnerChar, true);
			partner.followTarget = player;
			partner.updateHitbox();
			partner.y = groundY - partner.height;
			partner.velocity.set(0, 0);
			partner.grounded = true;
			partner.touching = FlxDirectionFlags.FLOOR;
			
			partner.moveSpeed *= 0.85;
			partner.maxMoveSpeed *= 0.85;
			
			add(partner);
		}

		FlxG.camera.follow(player, LOCKON, 0.05);

		FlxG.camera.setScrollBounds(0, 2920, 0, FlxG.height);

		FlxG.camera.deadzone = new flixel.math.FlxRect(
			(FlxG.width / 2) - 100, 
			(FlxG.height / 2) - 100, 
			200, 
			200
		);

		var spaceY:Float = 40;
		timer = new FlxText(20, 20, FlxG.width, "TIME: ", 32);
		timer.setFormat(null, 32, FlxColor.WHITE, LEFT); // , OUTLINE, FlxColor.BLACK
		timer.scrollFactor.set(0, 0);
		debugGroup.add(timer);

		score = new FlxText(timer.x, timer.y + spaceY, timer.width, "SCORE: ", 32);
		score.setFormat(null, 32, FlxColor.WHITE, LEFT); // , OUTLINE, FlxColor.BLACK
		score.scrollFactor.set(0, 0);
		debugGroup.add(score);

		flash = new FlxText(timer.x, score.y + spaceY, timer.width, "FLASH: ", 32);
		flash.setFormat(null, 32, FlxColor.WHITE, LEFT);
		flash.scrollFactor.set(0, 0);
		debugGroup.add(flash);

		flashGroup = new FlxTypedGroup<FlxSprite>();
		add(flashGroup);
		if (levelData != null) levelData.addFlashes(flashGroup);
		flashCount = 0;
		updateFlashHud();

		if (levelData != null && levelData.music != null && levelData.music.length > 0)
			FlxG.sound.playMusic(Paths.music(levelData.music), 1, true);
		else
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

		#if ELLAWY_ALLOWED
		trace('Current mod directory: ${Mods.currentModDirectory}');
		trace('Global mods: ${Mods.getGlobalMods()}');
		trace('All mod directories: ${Mods.getModDirectories()}');
		
		// Run the selection callback after the default player and partner exist.
		// "isPartner" is exposed to Ellawy so the same script can return a
		// different character configuration for the main player and partner.
		for (script in ellawyScripts)
		{
			if (script != null) script.set("isPartner", false);
		}
		var scriptResult:Dynamic = callOnEllawyScripts('onLoadGame', []);
		if (scriptResult == null)
			scriptResult = callOnEllawyScripts('onCreate', []);

		if (scriptResult != null && Reflect.hasField(scriptResult, "charLoad"))
		{
			var charPath:String = Std.string(Reflect.field(scriptResult, "charLoad"));
			var charName:String = charPath.split("/").pop();
			if (charName != null && charName.length > 0)
			{
				remove(player, true);
				player.destroy();
				player = new Player(500, 130, charName, false);
				player.updateHitbox();
				player.y = groundY - player.height;
				player.velocity.set(0, 0);
				player.grounded = true;
				player.touching = FlxDirectionFlags.FLOOR;
				add(player);
				FlxG.camera.follow(player, LOCKON, 0.05);
				addTextToDebug("Ellawy selected character: " + charName, FlxColor.GREEN);
			}
		}

		if (partner != null)
		{
			for (script in ellawyScripts)
			{
				if (script != null) script.set("isPartner", true);
			}
			var partnerResult:Dynamic = callOnEllawyScripts('onLoadGame', []);
			if (partnerResult != null && Reflect.hasField(partnerResult, "partnerLoad"))
			{
				var partnerPath:String = Std.string(Reflect.field(partnerResult, "partnerLoad"));
				var partnerName:String = partnerPath.split("/").pop();
				if (partnerName != null && partnerName.length > 0)
				{
					remove(partner, true);
					partner.destroy();
					partner = new Player(450, 130, partnerName, true);
					partner.followTarget = player;
					partner.updateHitbox();
					partner.y = groundY - partner.height;
					partner.velocity.set(0, 0);
					partner.grounded = true;
					partner.touching = FlxDirectionFlags.FLOOR;
					partner.moveSpeed *= 0.85;
					partner.maxMoveSpeed *= 0.85;
					add(partner);
					addTextToDebug("Ellawy selected partner: " + partnerName, FlxColor.GREEN);
				}
			}
		}
		for (script in ellawyScripts)
		{
			if (script != null) script.set("isPartner", false);
		}
		#end
	}

	/** Add a flat-color scenery rectangle to the background group. */
	private function addStageRect(x:Float, y:Float, width:Int, height:Int, color:FlxColor,
		scrollX:Float = 1, scrollY:Float = 1):FlxSprite
	{
		var sprite = new FlxSprite(x, y);
		sprite.makeGraphic(width, height, color);
		sprite.scrollFactor.set(scrollX, scrollY);
		backgroundLayers.add(sprite);
		return sprite;
	}

	/** Add a circular scenery shape; used for the sun, clouds and lamp. */
	private function addStageCircle(x:Float, y:Float, diameter:Int, color:FlxColor,
		scrollX:Float = 1, scrollY:Float = 1):FlxSprite
	{
		var sprite = new FlxSprite(x, y);
		sprite.makeGraphic(diameter, diameter, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawCircle(sprite, diameter * 0.5, diameter * 0.5, diameter * 0.5 - 1, color);
		sprite.scrollFactor.set(scrollX, scrollY);
		backgroundLayers.add(sprite);
		return sprite;
	}

	/** Add a black-outlined city building. */
	private function addStageBuilding(x:Float, y:Float, width:Int, height:Int, color:FlxColor):Void
	{
		addStageRect(x, y, width, height, FlxColor.BLACK, 0.82, 1);
		addStageRect(x + 6, y + 6, width - 12, height - 6, color, 0.82, 1);
	}

	private function collectFlash(playerSprite:FlxObject, flashSprite:FlxObject):Void
	{
		var item:FlxSprite = cast flashSprite;
		if (item == null || !item.exists) return;
		flashCount += item.ID > 0 ? item.ID : 1;
		item.kill();
		updateFlashHud();
	}

	private function updateFlashHud():Void
	{
		if (flash != null) flash.text = 'FLASH: $flashCount';
	}
	private function setupOnlineMode():Void
	{
		ghostGroup = new FlxTypedGroup<RemotePlayerGhost>();
		nameTagGroup = new FlxTypedGroup<FlxText>();

		add(ghostGroup);
		add(nameTagGroup);

		chatOverlay = new FlxText(10, 70, FlxG.width - 20, "", 14);
		chatOverlay.setFormat(null, 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		chatOverlay.scrollFactor.set(0, 0);
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

	override public function update(elapsed:Float):Void
	{
		elapsedTime += elapsed;
		rpcTimer += elapsed;

		if (!paused && player != null && testGround != null)
		{
			FlxG.collide(player, groundSegments);
			player.updateGroundState();
			
			if (partner != null)
			{
				FlxG.collide(partner, groundSegments);
				partner.updateGroundState();
				partner.updatePartnerAI(elapsed);
			}
		}

		if (!paused && player != null && flashGroup != null)
			FlxG.overlap(player, flashGroup, collectFlash);

		handleInput();

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

		#if ELLAWY_ALLOWED
		callOnEllawyScripts('onUpdate', [elapsed]);
		#end

		if (!paused && (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.P
				#if mobile
				#if android || FlxG.android.justReleased.BACK || customDPad.pauseButton.justPressed
				#else || customDPad.pauseButton.justPressed #end
				#end
			))
		{
			FlxG.sound.play(Paths.sound('cancel_sound'));
			openPauseMenu();
			return;
		}

		if (FlxG.keys.justPressed.E #if mobile || customDPad.powerButton.justPressed #end)
		{
				GameState.switchState(new TestState());
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
		
		var jumpPressed:Bool = FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z;
		var powerPressed:Bool = FlxG.keys.justPressed.X;
		
		var upPressed:Bool = FlxG.keys.pressed.UP || FlxG.keys.pressed.W;
		var downPressed:Bool = FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S;

		#if mobile
		if (customDPad != null)
		{
			leftPressed = leftPressed || customDPad.buttonLeft.justPressed || customDPad.buttonLeft.pressed;
			rightPressed = rightPressed || customDPad.buttonRight.justPressed || customDPad.buttonRight.pressed;
			upPressed = upPressed || customDPad.buttonUp.justPressed || customDPad.buttonUp.pressed;
			downPressed = downPressed || customDPad.buttonDown.justPressed || customDPad.buttonDown.pressed;
			jumpPressed = jumpPressed || customDPad.jumpButton.justPressed || customDPad.jumpButton.pressed;
			powerPressed = powerPressed || customDPad.powerButton.justPressed || customDPad.powerButton.pressed;
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

		if (upPressed && Math.abs(player.velocity.x) <= 10 && (player.grounded || player.isTouching(FlxDirectionFlags.FLOOR) || player.velocity.y == 0))
		{
			FlxG.camera.followLerp = 0.05;
			FlxG.camera.focusOn(new flixel.math.FlxPoint(player.getMidpoint().x, player.getMidpoint().y - 80));
		}
		else if (downPressed && Math.abs(player.velocity.x) <= 10 && (player.grounded || player.isTouching(FlxDirectionFlags.FLOOR) || player.velocity.y == 0))
		{
			FlxG.camera.followLerp = 0.05;
			FlxG.camera.focusOn(new flixel.math.FlxPoint(player.getMidpoint().x, player.getMidpoint().y + 80));
		}
		else
		{
			FlxG.camera.follow(player, LOCKON, 0.05);
		}

		player.moveCharacter(direction, jumpPressed, upPressed, downPressed);
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

	#if ELLAWY_ALLOWED
	public function initEllawyScript(file:String):Void
    {
        try
        {
            var sourceCode:String = null;
            
            #if sys
            if (sys.FileSystem.exists(file)) {
                sourceCode = sys.io.File.getContent(file);
            } else {
                sourceCode = Paths.getTextFromFile(file);
            }
            #else
            sourceCode = Paths.getTextFromFile(file);
            #end
            
            if (sourceCode == null) {
                addTextToDebug('ERROR: Could not read file ($file)', FlxColor.RED);
                return;
            }

            var script = new data.scripts.GameEllawyScript(file, sourceCode);
			
            script.set("PlayState", PlayState);
            script.set("FlxG", flixel.FlxG);
            script.set("Paths", Paths);
			script.set("Mods", Mods);
            
            script.set("print", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
                addTextToDebug("[PRINT] " + args.map(Std.string).join(" "), FlxColor.GREEN);
            }));
            
            script.set("trace", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
                addTextToDebug("[TRACE] " + args.map(Std.string).join(" "), FlxColor.GREEN);
            }));
            
            script.set("warn", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
                addTextToDebug("[WARN] " + args.map(Std.string).join(" "), FlxColor.YELLOW);
            }));
            
            script.set("error", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
                addTextToDebug("[ERROR] " + args.map(Std.string).join(" "), FlxColor.RED);
            }));
            
            ellawyScripts.push(script);
            script.call("onGame", []);
			script.call("onTest", []);
        }
        catch (e:Dynamic)
        {
            addTextToDebug('ERROR ON LOADING ($file): ${e}', FlxColor.RED);
        }
    }

	public function callOnEllawyScripts(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = null;
		if (args == null) args = [];

		for (script in ellawyScripts)
		{
			if (script != null)
			{
				var result = script.call(funcToCall, args);
				if (result != null) returnVal = result;
			}
		}
		return returnVal;
	}
	
	public function addTextToDebug(text:String, color:FlxColor):Void
	{
		if (debugGroup == null) return;

		var newText:flixel.text.FlxText = debugGroup.recycle(flixel.text.FlxText, function()
		{
			var txt = new flixel.text.FlxText(10, 0, 0, "", 12);
			txt.setFormat(null, 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			txt.scrollFactor.set(0, 0);
			return txt;
		});

		newText.text = text;
		newText.color = color;
		newText.alpha = 1;
		newText.setPosition(10, 8);

		debugGroup.add(newText);

		debugGroup.forEachAlive(function(spr:flixel.text.FlxText)
		{
			if (spr != newText)
				spr.y += newText.height + 2;
		});

		flixel.util.FlxTimer.wait(6, function()
		{
			if (newText != null && newText.alive)
				newText.kill();
		});
	}
	#end

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

		#if ELLAWY_ALLOWED
		for (script in ellawyScripts) {
			if (script != null) {
				script.call("onDestroy", []);
			}
		}
		ellawyScripts = [];
		#end

		player = null;

		if (partner != null)
		{
			partner.destroy();
			partner = null;
		}

		super.destroy();
	}
}

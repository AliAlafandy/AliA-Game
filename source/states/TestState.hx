package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.group.FlxGroup.FlxTypedGroup;

import data.objects.Player;
import states.menus.CharacterState;
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

import bin.BIN;

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
			nameTag.setPosition(x + (width / 2) - (nameTag.width / 2), y - 20);
	}
}

class TestState extends GameState
{
	public var player:Player;
	public var partner:Player;
	
	private var testGround:FlxSprite;
	private var groundSegments:FlxTypedGroup<FlxSprite>;
	private var backgroundLayers:FlxTypedGroup<FlxSprite>;

	public var debugGroup:FlxTypedGroup<FlxText>;
	public static var instance:TestState;

	private var levelStartY:Float = 0;

	#if mobile
	public var manager:MobileInputManager;
	#end

	#if ELLAWY_ALLOWED
	public var ellawyScripts:Array<GameEllawyScript> = [];
	#end

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
		FlxG.camera.bgColor = FlxColor.fromRGB(105, 190, 255);
		backgroundLayers = new FlxTypedGroup<FlxSprite>();
		add(backgroundLayers);

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
		loadBinLevel("AliA-Town/MyLevel");
		if (groundSegments == null || groundSegments.length == 0) {
			levelStartY = FlxG.height - 48;
			groundSegments = new FlxTypedGroup<FlxSprite>();
			add(groundSegments);
			for (i in 0...34) {
				var dirt = new FlxSprite(-2048 + i * 1024, levelStartY);
				dirt.makeGraphic(1024, 48, FlxColor.fromRGB(130, 78, 42));
				dirt.immovable = true;
				dirt.allowCollisions = FlxDirectionFlags.UP;
				groundSegments.add(dirt);
			}
			testGround = groundSegments.members[0];
		}

		var characterName:String = CharacterState.selectedCharacter;
		if (characterName == null || characterName.length == 0) {
			characterName = Player.DEFAULT_CHARACTER;
		}

		var mainChar:String = characterName;
		var partnerChar:String = "";

		if (characterName == "Ellawy+") {
			mainChar = "Ellawy";
			partnerChar = "Hamedo";
		}
		var spawnX:Float = 100;
		var spawnY:Float = levelStartY - 150; 

		player = new Player(spawnX, spawnY, mainChar, false);
		player.updateHitbox();
		player.velocity.set(0, 0);
		player.grounded = false;
		add(player);

		if (partnerChar != "") {
			partner = new Player(spawnX - 50, spawnY, partnerChar, true);
			partner.followTarget = player;
			partner.updateHitbox();
			partner.velocity.set(0, 0);
			partner.grounded = false;
			partner.moveSpeed *= 0.85;
			partner.maxMoveSpeed *= 0.85;
			add(partner);
		}
		FlxG.camera.follow(player, LOCKON, 0.05);
		FlxG.camera.setScrollBounds(0, 10000, 0, FlxG.height);
		FlxG.camera.deadzone = new flixel.math.FlxRect(
			(FlxG.width / 2) - 100, 
			(FlxG.height / 2) - 100, 
			200, 
			200
		);
		var debugText = new FlxText(20, 20, FlxG.width, "TEST STATE - BIN LEVEL LOADER", 24);
		debugText.setFormat(null, 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		debugText.scrollFactor.set(0, 0);
		debugGroup.add(debugText);

		FlxG.sound.music.resume();

		#if mobile
		addCustomDPad('EXITE', 'PLAY');
		addCustomDPadCam();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Testing BIN Loader', null);
		#end
		#if ELLAWY_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/')) {
			for (file in Paths.readDirectory(folder)) {
				if (file.toLowerCase().endsWith('.ellawy')) {
					initEllawyScript(folder + file);
				}
			}
		}
		
		var scriptResult = callOnEllawyScripts('onCreate', []);
		if (scriptResult != null && Reflect.hasField(scriptResult, "charLoad")) {
			var charPath:String = Reflect.field(scriptResult, "charLoad");
			var charName:String = charPath.split("/").pop(); 
			remove(player, true);
			player.destroy();
			player = new Player(spawnX, spawnY, charName, false);
			player.updateHitbox();
			player.velocity.set(0, 0);
			player.grounded = false;
			add(player);
			FlxG.camera.follow(player, LOCKON, 0.05);
			addTextToDebug("Loaded custom character via Ellawy: " + charName, FlxColor.GREEN);
		}
		#end
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (player != null && groundSegments != null) {
			FlxG.collide(player, groundSegments);
			player.updateGroundState();
			
			if (partner != null) {
				FlxG.collide(partner, groundSegments);
				partner.updateGroundState();
				partner.updatePartnerAI(elapsed);
			}
		}

		handleInput();
		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.P
			#if mobile
			|| (customDPad != null && customDPad.pauseButton.justPressed)
			#end
		) {
			FlxG.sound.play(Paths.sound('cancel_sound'));
			openPauseMenu();
		}
	}

	private function handleInput():Void
	{
		if (player == null) return;

		var leftPressed:Bool = FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A;
		var rightPressed:Bool = FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
		var jumpPressed:Bool = FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z;
		var upPressed:Bool = FlxG.keys.pressed.UP || FlxG.keys.pressed.W;
		var downPressed:Bool = FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S;

		#if mobile
		if (customDPad != null) {
			leftPressed = leftPressed || customDPad.buttonLeft.pressed;
			rightPressed = rightPressed || customDPad.buttonRight.pressed;
			upPressed = upPressed || customDPad.buttonUp.pressed;
			downPressed = downPressed || customDPad.buttonDown.pressed;
			jumpPressed = jumpPressed || customDPad.jumpButton.justPressed || customDPad.jumpButton.pressed;
		}
		#end

		var direction:Float = 0;
		if (leftPressed) direction -= 1;
		if (rightPressed) direction += 1;

		player.moveCharacter(direction, jumpPressed, upPressed, downPressed);
	}

	#if ELLAWY_ALLOWED
	public function initEllawyScript(file:String):Void {
		try {
			var sourceCode:String = sys.FileSystem.exists(file) ? sys.io.File.getContent(file) : Paths.getTextFromFile(file);
			if (sourceCode == null) return;
			var script = new data.scripts.GameEllawyScript(file, sourceCode);
			script.set("PlayState", TestState);
			script.set("FlxG", flixel.FlxG);
			script.set("Paths", Paths);
			script.set("Mods", Mods);
			ellawyScripts.push(script);
			script.call("onCreate", []);
		} catch (e:Dynamic) {}
	}

	public function callOnEllawyScripts(funcToCall:String, args:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = null;
		if (args == null) args = [];
		for (script in ellawyScripts) {
			if (script != null) {
				var result = script.call(funcToCall, args);
				if (result != null) returnVal = result;
			}
		}
		return returnVal;
	}
	
	public function addTextToDebug(text:String, color:FlxColor):Void {
		if (debugGroup == null) return;
		var newText:FlxText = debugGroup.recycle(FlxText, function() {
			var txt = new FlxText(10, 0, 0, "", 12);
			txt.setFormat(null, 12, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			txt.scrollFactor.set(0, 0);
			return txt;
		});
		newText.text = text;
		newText.color = color;
		newText.setPosition(10, 50 + (debugGroup.length * 14));
		debugGroup.add(newText);
		flixel.util.FlxTimer.wait(6, function() { if (newText != null) newText.kill(); });
	}
	#end

	private function loadBinLevel(levelPath:String):Void
	{
		#if sys
		var fileName = levelPath + ".bin";
		var targetPath:String = null;

		#if MODS_ALLOWED
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			var modPath = Paths.mods(Mods.currentModDirectory + '/levels/' + fileName);
			if (sys.FileSystem.exists(modPath)) targetPath = modPath;
		}
		if (targetPath == null) {
			for (mod in Mods.getGlobalMods()) {
				var modPath = Paths.mods(mod + '/levels/' + fileName);
				if (sys.FileSystem.exists(modPath)) {
					targetPath = modPath;
					break;
		}
			}
		}
		#end
		
		if (targetPath == null) {
			var basePath = 'levels/' + fileName;
			if (sys.FileSystem.exists(basePath)) targetPath = basePath;
		}

		if (targetPath == null) {
			trace("Level not found: " + levelPath);
			return;
		}

		try {
			var binValue = BIN.read(targetPath);
			var obj = binValue.asObject();
			if (obj == null) return;

			var cols = obj.get("cols").asInt(40);
			var rows = obj.get("rows").asInt(24);
			var tileSize = obj.get("tileSize").asInt(32);
			var tilesArray = obj.get("tiles").asArray();
			if (tilesArray == null) return;

			if (groundSegments != null) {
				remove(groundSegments, true);
				groundSegments.destroy();
			}
			groundSegments = new FlxTypedGroup<FlxSprite>();
			add(groundSegments);
			levelStartY = FlxG.height - (rows * tileSize) - 48; 
			if (levelStartY < 0) levelStartY = 0;

			for (y in 0...rows) {
				var rowBin = tilesArray.get(y).asArray();
				if (rowBin == null) continue;

				for (x in 0...cols) {
					var tileValue = rowBin.get(x).asInt(0);
					if (tileValue > 0) {
						var tile = new FlxSprite(x * tileSize, levelStartY + (y * tileSize));
						
						var color = switch(tileValue) {
							case 1: FlxColor.fromRGB(130, 78, 42);
							case 2: FlxColor.fromRGB(70, 180, 65);
							case 3: FlxColor.CYAN;
							case 4: FlxColor.ORANGE;
							case 5: FlxColor.MAGENTA;
							default: FlxColor.WHITE;
						}
						
						tile.makeGraphic(tileSize, tileSize, color);
						if (tileValue == 2) {
							tile.immovable = true;
							tile.allowCollisions = FlxDirectionFlags.UP;
						} else {
							tile.immovable = false;
							tile.allowCollisions = FlxDirectionFlags.NONE;
						}
						
						groundSegments.add(tile);
					}
				}
			}
			
			if (groundSegments.length > 0) {
				testGround = groundSegments.members[0];
			}
			
			trace("Successfully loaded BIN level from: " + targetPath);
		} catch (e:Dynamic) {
			trace("Failed to load BIN level: " + e);
		}
		#else
		trace("BIN loading is only supported on PC/Mobile (sys targets).");
		#end
	}

	public function openPauseMenu():Void {
		FlxG.sound.music.pause();
		openSubState(new PauseSubState());
		#if mobile
		removeCustomDPad();
		#end
	}

	override public function closeSubState():Void {
		FlxG.sound.music.resume();
		super.closeSubState();
		#if mobile
		addCustomDPad('EXITE', 'PLAY');
		addCustomDPadCam();
		#end
	}

	override public function destroy():Void {
		if (groundSegments != null) {
			remove(groundSegments, true);
			groundSegments.destroy();
			groundSegments = null;
		}
		if (player != null) {
			player.destroy();
			player = null;
		}
		if (partner != null) {
			partner.destroy();
			partner = null;
		}
		super.destroy();
	}
}

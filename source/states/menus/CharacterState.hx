package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.graphics.frames.FlxAtlasFrames;

#if MODS_ALLOWED
import sys.FileSystem;
#end

import data.backend.Paths;

class CharacterState extends GameState {
	public static var selectedCharacter:String = "Ellawy";

	var index:Int = 0;
	var defaultChars:Array<String> = [
		"Ellawy",
		"Hamedo",
		"Zezo",
		"Shaaban",
		"Ellawy+"
	];
	var chars:Array<String> = [];

	var gridGroup:FlxTypedGroup<FlxSprite>;
	var iconGroup:FlxTypedGroup<FlxSprite>;
	var nameTxt:FlxText;

	static inline var SLOTS:Int = 5;
	static inline var BOX_SIZE:Float = 80;
	static inline var SPACING_X:Float = 15;
	static inline var SPACING_Y:Float = 15;

	#if mobile
	public var manager:MobileInputManager;
	#end

	public function new():Void {
		super();
		#if mobile
		manager = new MobileInputManager();
		#end
	}

	override public function create() {
		var selectMusic = Paths.music('menus/select_character');
		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			if (selectMusic != null) {
				FlxG.sound.playMusic(selectMusic, 1, true);
			}
		}

		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/background'));
		add(bg);

		loadCharactersList();

		gridGroup = new FlxTypedGroup<FlxSprite>();
		iconGroup = new FlxTypedGroup<FlxSprite>();
		add(gridGroup);
		add(iconGroup);

		createGrid();

		nameTxt = new FlxText(0, FlxG.height - 60, FlxG.width, "", 22);
		nameTxt.setFormat(null, 22, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(nameTxt);

		updateSelection();

		#if mobile
		addCustomDPad('EXITE', 'MENU');
		addCustomDPadCam();
		#end
	}

	private function loadCharactersList():Void {
		chars = defaultChars.copy();

		#if MODS_ALLOWED
		var charactersDir:String = Paths.getModsDirectory() + "/characters";
		if (FileSystem.exists(charactersDir)) {
			for (folder in FileSystem.readDirectory(charactersDir)) {
				if (FileSystem.isDirectory(charactersDir + "/" + folder)) {
					if (!chars.contains(folder)) {
						chars.push(folder);
					}
				}
			}
		}
		#end
	}

	private function createGrid():Void {
		gridGroup.clear();
		iconGroup.clear();

		var totalSLOTS:Int = SLOTS;
		var startX:Float = (FlxG.width - (totalSLOTS * BOX_SIZE + (totalSLOTS - 1) * SPACING_X)) / 2;
		var startY:Float = 80;

		for (i in 0...chars.length) {
			var col:Int = i % SLOTS;
			var row:Int = Std.int(i / SLOTS);

			var posX:Float = startX + col * (BOX_SIZE + SPACING_X);
			var posY:Float = startY + row * (BOX_SIZE + SPACING_Y);

			var box:FlxSprite = new FlxSprite(posX, posY);
			try {
				var atlas:FlxAtlasFrames = Paths.getSparrowAtlas('menus/Selects/char_place');
				box.frames = atlas;
				box.animation.addByPrefix('idle', 'Idle0000', 24, true);
				box.animation.addByPrefix('select', 'Select0000', 24, true);
				box.animation.addByPrefix('press', 'Press0000', 24, false);
				box.animation.play('idle');
			} catch (e:Dynamic) {
				box.makeGraphic(Std.int(BOX_SIZE), Std.int(BOX_SIZE), 0xFF1B1A33);
			}

			box.setGraphicSize(Std.int(BOX_SIZE), Std.int(BOX_SIZE));
			box.updateHitbox();
			box.ID = i;
			gridGroup.add(box);
			
			var charName:String = chars[i];
			var iconPath:String = (charName == "Ellawy+") ? 'characters/Ellawy/icon-partner' : 'characters/$charName/icon';

			var icon:FlxSprite = new FlxSprite(posX, posY);
			try {
				icon.loadGraphic(Paths.image(iconPath));
			} catch (e:Dynamic) {
				icon.makeGraphic(48, 48, FlxColor.TRANSPARENT);
			}
			icon.setGraphicSize(Std.int(BOX_SIZE * 0.7), Std.int(BOX_SIZE * 0.7));
			icon.updateHitbox();
			icon.setPosition(
				posX + (BOX_SIZE - icon.width) / 2,
				posY + (BOX_SIZE - icon.height) / 2
			);
			icon.ID = i;
			iconGroup.add(icon);
		}
	}

	private function updateSelection():Void {
		for (i in 0...gridGroup.members.length) {
			var box = gridGroup.members[i];
			var icon = iconGroup.members[i];

			if (i == index) {
				if (box.animation.exists('select'))
					box.animation.play('select');
				box.scale.set(1.08, 1.08);
				if (icon != null) icon.scale.set(0.78, 0.78);
			} else {
				if (box.animation.exists('idle'))
					box.animation.play('idle');
				box.scale.set(1.0, 1.0);
				if (icon != null) icon.scale.set(0.7, 0.7);
			}
		}

		nameTxt.text = 'Selected: < ${chars[index]} >\nPress ENTER to Play';
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var selectMusic = Paths.music('menus/select_character');
		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			if (selectMusic != null) {
				FlxG.sound.playMusic(selectMusic, 1, true);
			}
		}

		var oldIndex:Int = index;

		if (controls.UI_LEFT_P) {
			index--;
			if (index < 0) index = chars.length - 1;
		}
		if (controls.UI_RIGHT_P) {
			index++;
			if (index >= chars.length) index = 0;
		}
		if (controls.UI_UP_P) {
			if (index - SLOTS >= 0) index -= SLOTS;
		}
		if (controls.UI_DOWN_P) {
			if (index + SLOTS < chars.length) index += SLOTS;
		}

		if (oldIndex != index) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateSelection();
		}

		if (controls.ACCEPT) {
			selectedCharacter = chars[index];
			var activeBox = gridGroup.members[index];
			if (activeBox != null && activeBox.animation.exists('press')) {
				activeBox.animation.play('press');
			}

			GameState.switchState(new PlayState());
			FlxG.sound.play(Paths.sound('confirm_sound'));
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancel_sound'));
			GameState.switchState(new SelectState());
		}
	}
}

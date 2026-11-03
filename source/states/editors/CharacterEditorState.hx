package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.ui.AUIBox;
import flixel.ui.AUIButton;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

/**
 * Character workspace. This edits character-level presentation only.
 * Animation definitions are intentionally handled by AnimationEditorState.
 */
class CharacterEditorState extends GameState
{
	private var paths:Array<String> = [];
	private var selected:Int = 0;
	private var character:Dynamic;
	private var preview:FlxSprite;
	private var fileRows:FlxTypedGroup<FlxSprite>;
	private var fileLabels:FlxTypedGroup<FlxText>;
	private var nameLabel:FlxText;
	private var infoLabel:FlxText;
	private var status:FlxText;
	private var previewScale:Float = 1;
	private var previewFlip:Bool = false;
	private var previewX:Float;
	private var previewY:Float;
	private var editorButtons:Array<AUIButton> = [];

	public function new():Void super();

	override public function create():Void
	{
		super.create();
		FlxG.camera.bgColor = 0xFF101722;
		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF101722));
		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, 54, 0xFF263449));
		var title = new FlxText(16, 14, FlxG.width - 32, "CHARACTER WORKSPACE", 21);
		title.setFormat(null, 21, FlxColor.WHITE, LEFT);
		add(title);

		var leftW = Std.int(FlxG.width * 0.34);
		add(new AUIBox(10, 64, leftW, FlxG.height - 122, "CHARACTERS"));
		add(new AUIBox(leftW + 20, 64, FlxG.width - leftW - 30, FlxG.height - 122, "CHARACTER PREVIEW"));
		fileRows = new FlxTypedGroup<FlxSprite>();
		fileLabels = new FlxTypedGroup<FlxText>();
		add(fileRows);
		add(fileLabels);

		previewX = leftW + (FlxG.width - leftW) * 0.5;
		previewY = FlxG.height * 0.48;
		preview = new FlxSprite();
		add(preview);

		nameLabel = new FlxText(leftW + 34, FlxG.height - 112, FlxG.width - leftW - 50, "", 16);
		nameLabel.setFormat(null, 16, FlxColor.WHITE, LEFT);
		add(nameLabel);
		infoLabel = new FlxText(leftW + 34, FlxG.height - 86, FlxG.width - leftW - 50, "", 11);
		infoLabel.setFormat(null, 11, 0xFFB7C5D8, LEFT);
		add(infoLabel);
		status = new FlxText(14, FlxG.height - 28, FlxG.width - 28, "UP/DOWN Select  |  LEFT/RIGHT Scale  |  F Flip  |  S Save  |  BACK Return", 11);
		status.setFormat(null, 11, 0xFF9EADC2, CENTER);
		add(status);
		addEditorButton(leftW + 34, FlxG.height - 62, "SCALE -", function() adjustScale(-0.05));
		addEditorButton(leftW + 124, FlxG.height - 62, "SCALE +", function() adjustScale(0.05));
		addEditorButton(leftW + 214, FlxG.height - 62, "FLIP", function() { previewFlip = !previewFlip; buildPreview(); });
		addEditorButton(leftW + 304, FlxG.height - 62, "SAVE", saveCharacter);

		scanCharacters();
		refreshList();
		if (paths.length > 0) loadCharacter(0);
		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end
	}

	private function addEditorButton(x:Float, y:Float, label:String, callback:Void->Void):Void
	{
		var button = new AUIButton(x, y, 82, 28, label, callback);
		editorButtons.push(button);
		add(button);
	}

	private function scanCharacters():Void
	{
		paths = [];
		#if sys
		#if MODS_ALLOWED
		var root = Paths.mods();
		if (FileSystem.exists(root))
			for (mod in FileSystem.readDirectory(root))
			{
				var folder = haxe.io.Path.join([root, mod, "characters"]);
				if (FileSystem.exists(folder) && FileSystem.isDirectory(folder)) scanDirectory(folder);
			}
		#end
		var shared = Paths.getSharedPath() + "characters/";
		if (FileSystem.exists(shared) && FileSystem.isDirectory(shared)) scanDirectory(shared);
		#end
		paths.sort(Reflect.compare);
	}

	private function scanDirectory(folder:String):Void
	{
		#if sys
		for (entry in FileSystem.readDirectory(folder))
		{
			var full = haxe.io.Path.join([folder, entry]);
			if (FileSystem.isDirectory(full)) scanDirectory(full);
			else if (entry.toLowerCase().endsWith(".json") && !paths.contains(full)) paths.push(full);
		}
		#end
	}

	private function refreshList():Void
	{
		fileRows.clear();
		fileLabels.clear();
		var rowH = 34;
		var leftW = Std.int(FlxG.width * 0.34);
		var maxRows = Std.int((FlxG.height - 160) / rowH);
		var start = Std.int(Math.max(0, Math.min(selected - maxRows + 1, paths.length - maxRows)));
		for (i in start...Std.int(Math.min(paths.length, start + maxRows)))
		{
			var y = 102 + (i - start) * rowH;
			var row = new FlxSprite(16, y).makeGraphic(leftW - 12, 30, i == selected ? 0xFF315A7C : 0xFF243244);
			fileRows.add(row);
			var label = new FlxText(25, y + 7, leftW - 30, haxe.io.Path.withoutExtension(pathToName(paths[i])), 11);
			label.setFormat(null, 11, FlxColor.WHITE, LEFT);
			fileLabels.add(label);
		}
	}

	private function pathToName(path:String):String
	{
		var parts = path.split("/");
		return parts.length > 0 ? parts[parts.length - 1] : path;
	}

	private function loadCharacter(index:Int):Void
	{
		if (paths.length == 0) return;
		selected = FlxMath.wrap(index, 0, paths.length - 1);
		#if sys
		try
		{
			character = haxe.Json.parse(File.getContent(paths[selected]));
			previewScale = 1;
			previewFlip = false;
			buildPreview();
			var characterName = Reflect.field(character, "charName");
			nameLabel.text = characterName == null ? pathToName(paths[selected]) : Std.string(characterName);
			var anims:Array<Dynamic> = cast Reflect.field(character, "anim");
			infoLabel.text = "Character definition  |  " + (anims == null ? 0 : anims.length) + " animation entries\nScale is editable here; animation timing and frames are in Animation Editor.";
			refreshList();
			status.text = "Loaded " + paths[selected];
		}
		catch (e:Dynamic)
		{
			status.text = "Could not load character: " + Std.string(e);
			character = null;
		}
		#end
	}

	private function buildPreview():Void
	{
		if (preview == null || character == null) return;
		preview.destroy();
		preview = new FlxSprite();
		var anims:Array<Dynamic> = cast Reflect.field(character, "anim");
		if (anims != null && anims.length > 0)
		{
			var data = anims[0];
			var image = Std.string(Reflect.field(data, "image"));
			var folder = haxe.io.Path.directory(paths[selected]);
			var characterFolder = haxe.io.Path.withoutDirectory(folder);
			var asset = "characters/" + characterFolder + "/" + image;
			try
			{
				preview.frames = Paths.getSparrowAtlas(asset);
				var prefix = Std.string(Reflect.field(data, "prefix"));
				preview.animation.addByPrefix("preview", prefix, 24, true);
				preview.animation.play("preview");
			}
			catch (e:Dynamic)
			{
				preview.makeGraphic(70, 100, 0xFF55CCFF);
				status.text = "Sprite atlas unavailable: " + asset;
			}
			var scaleValue:Dynamic = Reflect.field(data, "scale");
			preview.scale.set((scaleValue == null ? 1 : Std.parseFloat(Std.string(scaleValue))) * previewScale,
				(scaleValue == null ? 1 : Std.parseFloat(Std.string(scaleValue))) * previewScale);
		}
		else preview.makeGraphic(70, 100, 0xFF55CCFF);
		preview.flipX = previewFlip;
		preview.updateHitbox();
		preview.x = previewX - preview.width * 0.5;
		preview.y = previewY - preview.height * 0.5;
		add(preview);
	}

	private function adjustScale(amount:Float):Void
	{
		previewScale = Math.max(0.2, Math.min(3, previewScale + amount));
		buildPreview();
		status.text = "Preview scale: " + Std.int(previewScale * 100) + "%";
	}

	private function saveCharacter():Void
	{
		#if sys
		if (character == null || paths.length == 0)
		{
			status.text = "No character loaded.";
			return;
		}
		try
		{
			var anims:Array<Dynamic> = cast Reflect.field(character, "anim");
			if (anims == null || anims.length == 0)
			{
				status.text = "This character has no animation entry to store its scale.";
				return;
			}
			var currentScale = Reflect.field(anims[0], "scale");
			var baseScale = currentScale == null ? 1.0 : Std.parseFloat(Std.string(currentScale));
			Reflect.setField(anims[0], "scale", baseScale * previewScale);
			File.saveContent(paths[selected], haxe.Json.stringify(character, null, "\\t"));
			previewScale = 1;
			buildPreview();
			status.text = "Saved character scale to " + pathToName(paths[selected]);
		}
		catch (e:Dynamic)
		{
			status.text = "Character save failed: " + Std.string(e);
		}
		#end
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		#if mobile
		for (i in 0...fileRows.members.length)
			if (TouchUtil.justPressedOn(fileRows.members[i]) || TouchUtil.justPressedOn(fileLabels.members[i]))
			{
				var visibleStart = Std.int(Math.max(0, Math.min(selected - fileRows.members.length + 1, paths.length - fileRows.members.length)));
				loadCharacter(visibleStart + i);
				return;
			}
		#end
		if (controls.GAME_UP_P && paths.length > 0) loadCharacter(selected - 1);
		else if (controls.GAME_DOWN_P && paths.length > 0) loadCharacter(selected + 1);
		if (controls.GAME_LEFT_P) adjustScale(-0.05);
		else if (controls.GAME_RIGHT_P) adjustScale(0.05);
		if (FlxG.keys.justPressed.F) { previewFlip = !previewFlip; buildPreview(); }
		if (FlxG.keys.justPressed.S) saveCharacter();
		if (controls.BACK) GameState.switchState(new EditorState());
	}
}

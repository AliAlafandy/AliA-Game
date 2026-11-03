package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import mobile.TouchUtil;
import flixel.ui.AUIBox;
import flixel.ui.AUIButton;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

/**
 * Animation workspace. Animation data is edited through a preview, animation
 * selector and frame properties. Character-level settings remain in CharacterEditorState.
 */
class AnimationEditorState extends GameState
{
	private var paths:Array<String> = [];
	private var selectedFile:Int = 0;
	private var selectedAnimation:Int = 0;
	private var characterData:Dynamic;
	private var animations:Array<Dynamic> = [];
	private var rows:FlxTypedGroup<FlxSprite>;
	private var rowLabels:FlxTypedGroup<FlxText>;
	private var preview:FlxSprite;
	private var details:FlxText;
	private var status:FlxText;
	private var fps:Int = 24;
	private var loop:Bool = true;
	private var actionButtons:Array<AUIButton> = [];

	public function new():Void super();

	override public function create():Void
	{
		super.create();
		FlxG.camera.bgColor = 0xFF101722;
		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF101722));
		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, 54, 0xFF263449));
		var title = new FlxText(16, 14, FlxG.width - 32, "ANIMATION WORKSPACE", 21);
		title.setFormat(null, 21, FlxColor.WHITE, LEFT);
		add(title);

		var leftW = Std.int(FlxG.width * 0.36);
		add(new FlxSprite(10, 64).makeGraphic(leftW, FlxG.height - 120, 0xFF1B2736));
		add(new AUIBox(10, 64, leftW, FlxG.height - 120, "ANIMATIONS"));
		add(new AUIBox(leftW + 20, 64, FlxG.width - leftW - 30, FlxG.height - 120, "FRAME PREVIEW"));
		var listTitle = new FlxText(22, 72, leftW - 20, "ANIMATIONS", 14);
		listTitle.setFormat(null, 14, FlxColor.CYAN, LEFT);
		add(listTitle);
		addAction("ADD", addAnimation, 0);
		addAction("REMOVE", removeAnimation, 1);
		addAction("SAVE", save, 2);
		rows = new FlxTypedGroup<FlxSprite>();
		rowLabels = new FlxTypedGroup<FlxText>();
		add(rows);
		add(rowLabels);

		var previewTitle = new FlxText(leftW + 34, 72, FlxG.width - leftW - 50, "FRAME PREVIEW", 14);
		previewTitle.setFormat(null, 14, FlxColor.CYAN, LEFT);
		add(previewTitle);
		preview = new FlxSprite();
		add(preview);
		details = new FlxText(leftW + 34, FlxG.height - 145, FlxG.width - leftW - 50, "", 13);
		details.setFormat(null, 13, FlxColor.WHITE, LEFT);
		add(details);
		status = new FlxText(14, FlxG.height - 28, FlxG.width - 28, "UP/DOWN Animation  |  LEFT/RIGHT FPS  |  L Loop  |  S Save  |  BACK Return", 11);
		status.setFormat(null, 11, 0xFF9EADC2, CENTER);
		add(status);

		scan();
		if (paths.length > 0) loadCharacter(0);
		else status.text = "No character definition files found.";
		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end
	}

	private function addAction(label:String, callback:Void->Void, index:Int):Void
	{
		var x = 18 + index * 92;
		var y = FlxG.height - 66;
		var button = new AUIButton(x, y, 84, 28, label, callback);
		actionButtons.push(button);
		add(button);
	}

	private function addAnimation():Void
	{
		if (characterData == null) return;
		var image = "character";
		if (animations.length > 0) image = fieldString(animations[0], "image", image);
		var name = "newAnimation" + animations.length;
		animations.push({
			name: name,
			image: image,
			prefix: name,
			offsets: [0, 0],
			loop: true,
			scale: 1,
			fps: 24,
			indices: []
		});
		selectedAnimation = animations.length - 1;
		refreshAnimations();
		status.text = "Created " + name + ". Set its prefix and frame data in the character definition.";
	}

	private function removeAnimation():Void
	{
		if (selectedAnimation < 0 || selectedAnimation >= animations.length) return;
		var removed = fieldString(animations[selectedAnimation], "name", "animation");
		animations.splice(selectedAnimation, 1);
		selectedAnimation = Std.int(Math.max(0, Math.min(selectedAnimation, animations.length - 1)));
		refreshAnimations();
		status.text = "Removed " + removed + ". Press SAVE to keep the change.";
	}

	private function scan():Void
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

	private function loadCharacter(index:Int):Void
	{
		if (paths.length == 0) return;
		selectedFile = FlxMath.wrap(index, 0, paths.length - 1);
		#if sys
		try
		{
			characterData = haxe.Json.parse(File.getContent(paths[selectedFile]));
			var raw:Dynamic = Reflect.field(characterData, "anim");
			animations = raw == null ? [] : cast raw;
			selectedAnimation = 0;
			refreshAnimations();
			status.text = "Loaded animation data from " + paths[selectedFile];
		}
		catch (e:Dynamic) status.text = "Could not load animation definitions: " + Std.string(e);
		#end
	}

	private function refreshAnimations():Void
	{
		rows.clear();
		rowLabels.clear();
		var leftW = Std.int(FlxG.width * 0.36);
		var rowH = 32;
		var maxRows = Std.int((FlxG.height - 158) / rowH);
		var start = Std.int(Math.max(0, Math.min(selectedAnimation - maxRows + 1, animations.length - maxRows)));
		for (i in start...Std.int(Math.min(animations.length, start + maxRows)))
		{
			var y = 102 + (i - start) * rowH;
			var name = fieldString(animations[i], "name", "Animation " + i);
			rows.add(new FlxSprite(16, y).makeGraphic(leftW - 12, 28, i == selectedAnimation ? 0xFF315A7C : 0xFF243244));
			var label = new FlxText(25, y + 6, leftW - 30, name, 11);
			label.setFormat(null, 11, FlxColor.WHITE, LEFT);
			rowLabels.add(label);
		}
		refreshPreview();
	}

	private function refreshPreview():Void
	{
		if (preview != null) preview.destroy();
		preview = new FlxSprite();
		if (selectedAnimation >= 0 && selectedAnimation < animations.length)
		{
			var data = animations[selectedAnimation];
			var image = fieldString(data, "image", "");
			var prefix = fieldString(data, "prefix", "");
			var folder = haxe.io.Path.directory(paths[selectedFile]);
			var charFolder = haxe.io.Path.withoutDirectory(folder);
			var asset = "characters/" + charFolder + "/" + image;
			try
			{
				preview.frames = Paths.getSparrowAtlas(asset);
				var indices:Dynamic = Reflect.field(data, "indices");
				if (indices != null && Std.isOfType(indices, Array) && (cast indices:Array<Dynamic>).length > 0)
				{
					var frames:Array<Int> = [];
					for (value in (cast indices:Array<Dynamic>)) frames.push(Std.int(value));
					preview.animation.addByIndices("selected", prefix, frames, "", fps, loop);
				}
				else preview.animation.addByPrefix("selected", prefix, fps, loop);
				preview.animation.play("selected");
			}
			catch (e:Dynamic)
			{
				preview.makeGraphic(72, 96, 0xFF55CCFF);
				status.text = "Atlas/prefix unavailable: " + asset + " / " + prefix;
			}
			var scaleValue = fieldFloat(data, "scale", 1);
			preview.scale.set(scaleValue, scaleValue);
			fps = fieldInt(data, "fps", 24);
			loop = fieldBool(data, "loop", true);
			details.text = "Name: " + fieldString(data, "name", "") + "\nAtlas: " + image + "\nPrefix: " + prefix
				+ "\nFPS: " + fps + "     Loop: " + (loop ? "ON" : "OFF")
				+ "\nOffset: " + arrayValue(data, "offsets", 0) + ", " + arrayValue(data, "offsets", 1)
				+ "\nScale: " + scaleValue;
		}
		else details.text = "No animations in this character definition.";
		preview.x = (FlxG.width + Std.int(FlxG.width * 0.36)) * 0.5 - preview.width * 0.5;
		preview.y = FlxG.height * 0.32 - preview.height * 0.5;
		add(preview);
	}

	private function fieldString(data:Dynamic, key:String, fallback:String):String
	{
		var value = Reflect.field(data, key);
		return value == null ? fallback : Std.string(value);
	}

	private function fieldInt(data:Dynamic, key:String, fallback:Int):Int
	{
		var value = Reflect.field(data, key);
		return value == null ? fallback : Std.int(Std.parseFloat(Std.string(value)));
	}

	private function fieldFloat(data:Dynamic, key:String, fallback:Float):Float
	{
		var value = Reflect.field(data, key);
		return value == null ? fallback : Std.parseFloat(Std.string(value));
	}

	private function fieldBool(data:Dynamic, key:String, fallback:Bool):Bool
	{
		var value = Reflect.field(data, key);
		return value == null ? fallback : value == true || Std.string(value) == "true";
	}

	private function arrayValue(data:Dynamic, key:String, index:Int):String
	{
		var value:Dynamic = Reflect.field(data, key);
		return value != null && (cast value:Array<Dynamic>).length > index ? Std.string((cast value:Array<Dynamic>)[index]) : "0";
	}

	private function changeFPS(amount:Int):Void
	{
		if (animations.length == 0) return;
		fps = Std.int(Math.max(1, Math.min(120, fps + amount)));
		Reflect.setField(animations[selectedAnimation], "fps", fps);
		refreshPreview();
	}

	private function toggleLoop():Void
	{
		if (animations.length == 0) return;
		loop = !loop;
		Reflect.setField(animations[selectedAnimation], "loop", loop);
		refreshPreview();
	}

	private function save():Void
	{
		#if sys
		if (characterData == null || paths.length == 0) return;
		try
		{
			Reflect.setField(characterData, "anim", animations);
			File.saveContent(paths[selectedFile], haxe.Json.stringify(characterData, null, "\t"));
			status.text = "Saved animation data: " + paths[selectedFile];
		}
		catch (e:Dynamic) status.text = "Save failed: " + Std.string(e);
		#end
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		#if mobile
		for (i in 0...rows.members.length)
			if (TouchUtil.justPressedOn(rows.members[i]) || TouchUtil.justPressedOn(rowLabels.members[i]))
			{
				var maxRows = rows.members.length;
				var start = Std.int(Math.max(0, Math.min(selectedAnimation - maxRows + 1, animations.length - maxRows)));
				selectedAnimation = start + i;
				refreshAnimations();
				return;
			}
		#end
		if (controls.GAME_UP_P && animations.length > 0)
		{
			selectedAnimation = FlxMath.wrap(selectedAnimation - 1, 0, animations.length - 1);
			refreshAnimations();
		}
		else if (controls.GAME_DOWN_P && animations.length > 0)
		{
			selectedAnimation = FlxMath.wrap(selectedAnimation + 1, 0, animations.length - 1);
			refreshAnimations();
		}
		if (controls.GAME_LEFT_P) changeFPS(-1);
		else if (controls.GAME_RIGHT_P) changeFPS(1);
		if (FlxG.keys.justPressed.L) toggleLoop();
		if (FlxG.keys.justPressed.N) addAnimation();
		if (FlxG.keys.justPressed.DELETE || FlxG.keys.justPressed.BACKSPACE) removeAnimation();
		if (FlxG.keys.justPressed.S) save();
		if (controls.BACK) GameState.switchState(new EditorState());
	}
}

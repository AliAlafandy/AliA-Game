package states.editors;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;

import states.editors.*;

typedef EditorOption =
{
	label:String,
	action:Void->Void
}

class EditorState extends GameState
{
	private var title:FlxText;
	private var info:FlxText;
	private var optionTexts:FlxTypedGroup<FlxText>;
	private var options:Array<EditorOption>;
	private var selectedIndex:Int = 0;

	#if mobile
	public var manager:MobileInputManager;
	#end

	public function new():Void
	{
		super();
		#if mobile
		manager = new MobileInputManager();
		#end
	}

	override public function create():Void
	{
		super.create();

		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/Options/background'));
		add(bg);

		buildOptions();

		title = new FlxText(0, 80, FlxG.width, 'EDITOR ZONE', 32);
		title.setFormat(null, 32, FlxColor.WHITE, CENTER);
		add(title);

		optionTexts = new FlxTypedGroup<FlxText>();
		add(optionTexts);

		for (i in 0...options.length)
		{
			var entry = new FlxText(0, 180 + (i * 40), FlxG.width, options[i].label, 24);
			entry.setFormat(null, 24, FlxColor.WHITE, CENTER);
			//entry.alignment(CENTER, null);
			optionTexts.add(entry);
		}

		info = new FlxText(80, 180 + (options.length * 40) + 40, FlxG.width - 160, 'UP/DOWN - Navigate\nACCEPT - Open\nBACK - Return to Menu', 18);
		info.setFormat(null, 18, FlxColor.GRAY, CENTER);
		add(info);

		#if mobile
		addCustomDPad('EXITE', 'MENU');
		addCustomDPadCam();
		#end

		refreshSelection();
	}

	private function buildOptions():Void
	{
		options = [
			{ label: 'Level Editor', action: openLevelEditor },
			{ label: 'Character Editor', action: openCharacterEditor },
			{ label: 'Animation Editor', action: openAnimationEditor },
			{ label: 'Script Editor', action: openScriptEditor }
		];
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.GAME_UP_P)
			moveSelection(-1);
		else if (controls.GAME_DOWN_P)
			moveSelection(1);

		if (controls.ACCEPT)
			options[selectedIndex].action();

		if (controls.BACK)
			GameState.switchState(new MenuState());
	}

	private function moveSelection(direction:Int):Void
	{
		selectedIndex = FlxMath.wrap(selectedIndex + direction, 0, options.length - 1);
		refreshSelection();
	}

	private function refreshSelection():Void
	{
		var i = 0;
		for (entry in optionTexts.members)
		{
			var selected = (i == selectedIndex);
			entry.color = selected ? FlxColor.YELLOW : FlxColor.WHITE;
			entry.scale.set(selected ? 1.1 : 1, selected ? 1.1 : 1);
			i++;
		}
	}

	private function openLevelEditor():Void
	{
		FlxG.switchState(new LevelEditorState());
	}

	private function openCharacterEditor():Void
	{
	}

	private function openAnimationEditor():Void
	{
	}

	private function openScriptEditor():Void
	{
	}
}

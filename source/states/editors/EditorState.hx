package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.ui.AUIBox;
import flixel.ui.AUIButton;

/**
 * Visual editor hub for AliA-Game.
 * The layout borrows the panel/tool workflow of game editors without importing FNF content.
 */
class EditorState extends GameState
{
	private var options:Array<EditorOption>;
	private var selectedIndex:Int = 0;
	private var descriptions:FlxTypedGroup<FlxText>;
	private var footer:FlxText;
	private var optionButtons:Array<AUIButton> = [];

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

		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
		    FlxG.sound.playMusic(Paths.music('menus/menu'), 1, true);
		} else if (FlxG.sound.music != null || !FlxG.sound.music.playing) {
			FlxG.sound.music.resume();
		}

		FlxG.camera.bgColor = 0xFF101722;

		var background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF101722);
		add(background);
		// Keep the editor header clear of the engine's top-left debug overlay.
		add(new AUIBox(0, 48, FlxG.width, 58, "ALI A-GAME / EDITOR ZONE"));

		var subtitle = new FlxText(22, 118, FlxG.width - 44, "Choose a workspace", 16);
		subtitle.setFormat(null, 16, 0xFF9EADC2, LEFT);
		add(subtitle);

		options = [
			{label:"LEVEL EDITOR", description:"Build scenes, place objects and configure level data.", action:openLevelEditor},
			{label:"CHARACTER EDITOR", description:"Preview and configure character properties.", action:openCharacterEditor},
			{label:"ANIMATION EDITOR", description:"Create and preview sprite animations and frame timing.", action:openAnimationEditor},
			{label:"ELLAWY SCRIPT EDITOR", description:"Write and manage .ellawy mod scripts.", action:openScriptEditor}
		];

		descriptions = new FlxTypedGroup<FlxText>();
		add(descriptions);

		var cardW = FlxG.width - 44;
		var cardH = Std.int(Math.min(82, (FlxG.height - 226) / 4));
		for (i in 0...options.length)
		{
			var y = 154 + i * (cardH + 10);
			var option = options[i];
			var button = new AUIButton(22, y, cardW, cardH, option.label, function() {
				FlxG.sound.play(Paths.sound("confirm_sound"));
				option.action();
			});
			// Keep hit testing in AUIButton, but render labels as state-level
			// text objects so they are not clipped by FlxSpriteGroup bounds.
			button.caption.visible = false;
			optionButtons.push(button);
			add(button);

			var label = new FlxText(40, y + 10, cardW - 36, options[i].label, 17);
			label.setFormat(null, 17, FlxColor.WHITE, LEFT);
			label.color = i == selectedIndex ? FlxColor.YELLOW : FlxColor.WHITE;
			add(label);

			var desc = new FlxText(40, y + 42, cardW - 36, options[i].description, 12);
			desc.setFormat(null, 12, 0xFF9EADC2, LEFT);
			descriptions.add(desc);
		}

		footer = new FlxText(20, FlxG.height - 32, FlxG.width - 40, "UP / DOWN  SELECT     ENTER  OPEN     BACK  MENU", 12);
		footer.setFormat(null, 12, 0xFF8798AE, CENTER);
		add(footer);

		#if mobile
		addCustomDPad('NONE', 'BACK');
		addCustomDPadCam();
		#end
		refreshSelection();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (controls.GAME_UP_P) moveSelection(-1);
		else if (controls.GAME_DOWN_P) moveSelection(1);
		if (controls.ACCEPT) options[selectedIndex].action();
		if (controls.BACK) GameState.switchState(new MenuState());
	}

	private function moveSelection(amount:Int):Void
	{
		selectedIndex = FlxMath.wrap(selectedIndex + amount, 0, options.length - 1);
		FlxG.sound.play(Paths.sound("scroll_sound"));
		refreshSelection();
	}

	private function refreshSelection():Void
	{
		for (i in 0...optionButtons.length)
		{
			var active = i == selectedIndex;
			optionButtons[i].background.color = active ? 0xFF315A7C : 0xFF202B3A;
			optionButtons[i].background.alpha = active ? 0.65 : 0.28;
			// Card titles are rendered as standalone FlxText objects; the AUIButton
			// captions stay hidden and are used only for click/touch hit testing.
			var label = cast(members[4 + i * 3], FlxText);
			label.color = active ? FlxColor.YELLOW : FlxColor.WHITE;
			descriptions.members[i].color = active ? FlxColor.WHITE : 0xFF9EADC2;
		}
	}

	private function openLevelEditor():Void GameState.switchState(new LevelEditorState());
	private function openCharacterEditor():Void GameState.switchState(new CharacterEditorState());
	private function openAnimationEditor():Void GameState.switchState(new AnimationEditorState());
	private function openScriptEditor():Void GameState.switchState(new ScriptEditorState());
}

typedef EditorOption =
{
	var label:String;
	var description:String;
	var action:Void->Void;
}

package states.menus;

import states.MenuState;
import substates.GameplaySettingsSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import states.PlayState;
import states.menus.CharacterState;

class SelectState extends GameState
{
	private var selected:Int = 0;
	private var deleting:Bool = false;
	private var saveStatus:String = "";
	private var staticSave:FlxSave;

	private final saves:Array<String> = [
		'NO SAVE',
		'SAVE SLOT 1',
		'SAVE SLOT 2',
		'SAVE SLOT 3',
		'SAVE SLOT 4',
		'SAVE SLOT 5',
		'SAVE SLOT 6',
		'SAVE SLOT 7',
		'SAVE SLOT 8',
		'DELETE'
	];kage states.menus;

import states.MenuState;
import substates.GameplaySettingsSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import states.PlayState;
import states.menus.CharacterState;

class SelectState extends GameState
{
	private var selected:Int = 0;
	private var deleting:Bool = false;
	private var saveStatus:String = "";
	private var staticSave:FlxSave;

	private final saves:Array<String> = [
		'NO SAVE',
        'NEW GAME 1',
        'NEW GAME 2',
        'NEW GAME 3',
        'NEW GAME 4',
        'NEW GAME 5',
        'NEW GAME 6',
        'NEW GAME 7',
        'NEW GAME 8',
		'DELETE'
    ];

	private var t:FlxText;

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

    override public function create()
	{
		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/background'));
		add(bg);

        t = new FlxText(0, 0, 0, "", 24);
        t.setFormat(null, 24, FlxColor.WHITE, CENTER);
        add(t);

		refresh();
		staticSave = new FlxSave();

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
		    FlxG.sound.playMusic(Paths.music('menus/menu'), 1, true);
		} else if (FlxG.sound.music != null || !FlxG.sound.music.playing) {
			FlxG.sound.music.resume();
		}

        #if mobile
		if (ClientPrefs.data.debugSecret) {
			addCustomDPad('EXITE', 'E-MENU');
		} else {
			addCustomDPad('EXITE', 'MENU');
		}
		addCustomDPadCam();
		addMobileSaveButtons();
		#end
    }

    override public function update(elapsed:Float)
	{
        super.update(elapsed);

		/*if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
		    FlxG.sound.playMusic(Paths.music('menus/menu'), 1, true);
		} else if (FlxG.sound.music != null || !FlxG.sound.music.playing) {
			FlxG.sound.music.resume();
		}*/

		if (controls.UI_UP_P)
		{
			selected--;

			if (selected < 0)
				selected = saves.length - 1;

			FlxG.sound.play(Paths.sound('scroll_sound'));

			refresh();
		}

		if (controls.UI_DOWN_P)
		{
			selected++;

			if (selected >= saves.length)
				selected = 0;

			FlxG.sound.play(Paths.sound('scroll_sound'));

			refresh();
		}

        if (controls.ACCEPT) openSelectedSave();

        if (controls.BACK) {
			// FlxG.sound.music.pause();
			FlxG.sound.play(Paths.sound('cancel_sound'));
            GameState.switchState(new MenuState());
        }

		if (ClientPrefs.data.debugSecret) {
			if (FlxG.keys.justPressed.E #if mobile || customDPad.powerButton.justPressed #end)
			{
				openSubState(new GameplaySettingsSubState());
			}
		}
    }

	#if mobile
	private function addMobileSaveButtons():Void
	{
		var labels = ['PREV', 'NEXT', 'OPEN', 'BACK'];
		var w = (FlxG.width - 20) / labels.length;
		for (i in 0...labels.length)
		{
			var index = i;
			var b = new FlxButton(4 + i * (w + 4), FlxG.height - 58, labels[i], function() {
				switch (index) {
					case 0: selected = (selected - 1 + saves.length) % saves.length; refresh();
					case 1: selected = (selected + 1) % saves.length; refresh();
					case 2: openSelectedSave();
					case 3: GameState.switchState(new MenuState());
				}
			});
			b.scale.set(0.85, 0.85);
			add(b);
		}
	}
	#end

	private function slotName(slot:Int):String
	{
		return 'AliAGameSaveSlot' + slot;
	}

	private function bindSlot(slot:Int):Bool
	{
		if (staticSave == null) staticSave = new FlxSave();
		return staticSave.bind(slotName(slot));
	}

	private function openSelectedSave():Void
	{
		FlxG.sound.play(Paths.sound('confirm_sound'));

		// NO SAVE always starts a fresh, non-persistent session.
		if (selected == 0)
		{
			PlayState.saveSlot = 0;
			PlayState.noSave = true;
			new FlxTimer().start(0.15, function(tmr:FlxTimer) GameState.switchState(new CharacterState()));
			return;
		}

		// DELETE enters deletion mode. Pick one of the eight slots to erase.
		if (selected == saves.length - 1)
		{
			deleting = !deleting;
			saveStatus = deleting ? 'DELETE MODE: choose slot 1-8, then OPEN' : 'Delete mode cancelled';
			refresh();
			return;
		}

		var slot = selected;
		if (deleting)
		{
			if (bindSlot(slot))
			{
				staticSave.erase();
				staticSave.close();
			}
			deleting = false;
			saveStatus = 'SAVE SLOT $slot deleted. Choose NO SAVE or a slot to start.';
			refresh();
			return;
		}

		// Selecting a slot stores the current character and launches directly.
		// It deliberately does not open CharacterState.
		if (!bindSlot(slot))
		{
			saveStatus = 'Could not open SAVE SLOT $slot';
			refresh();
			return;
		}
		staticSave.data.character = CharacterState.selectedCharacter;
		staticSave.data.characterIndex = CharacterState.selectedCharacterIndex;
		staticSave.data.stage = PlayState.curStage;
		staticSave.data.flashCount = 0;
		staticSave.data.elapsedTime = 0.0;
		staticSave.data.exists = true;
		staticSave.flush();
		staticSave.close();

		PlayState.saveSlot = slot;
		PlayState.noSave = false;
		new FlxTimer().start(0.15, function(tmr:FlxTimer) GameState.switchState(new PlayState()));
	}

	private function refresh():Void
    {
        var output:String = 'SELECT SAVE\n\n';

        for (i in 0...saves.length)
        {
            var prefix:String = i == selected ? '> ' : '';
			var prefix2:String = i == selected ? ' <' : '';
            output += prefix + saves[i] + prefix2 + '\n';
        }

        output += '\nUP / DOWN - Select\nENTER - Open\nESC - Back';

        t.text = output;
        t.screenCenter();
	}
}

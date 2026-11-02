package states.menus;

import states.MenuState;
import substates.GameplaySettingsSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;

class SelectState extends GameState
{
	private var selected:Int = 0;

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

	private function openSelectedSave():Void
	{
		new FlxTimer().start(1, function(tmr:FlxTimer) GameState.switchState(new CharacterState()));
		FlxG.sound.play(Paths.sound('confirm_sound'));
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

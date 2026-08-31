package states.menus;

import states.MenuState;

class SelectState extends GameState
{
	private var selected:Int = 0;

	private final saves:Array<String> = [
        'NEW GAME 1',
        'NEW GAME 2',
        'NEW GAME 3',
        'NEW GAME 4',
        'NEW GAME 5',
        'NEW GAME 6',
        'NEW GAME 7',
        'NEW GAME 8'
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

    override public function create() {
		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/background'));
		add(bg);

        t = new FlxText(0, 0, 0, "", 24);
        t.setFormat(null, 24, FlxColor.WHITE, CENTER);
        add(t);

		refresh();

        #if mobile
		addCustomDPad('EXITE', 'MENU');
		addCustomDPadCam();
		#end
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

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

        if (controls.ACCEPT) {
            GameState.switchState(new CharacterState());
			FlxG.sound.play(Paths.sound('confirm_sound'));
			FlxG.sound.music.volume = 0;
        }

        if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancel_sound'));
            GameState.switchState(new MenuState());
        }
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

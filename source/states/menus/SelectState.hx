package states.menus;

import states.MenuState;

class SelectState extends GameState
{
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

        var text = new FlxText(0, 0, 0, "", 14);
        text.screenCenter();
        add(text);

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
				selected = options.length - 1;

			refresh();
		}

		if (controls.UI_DOWN_P)
		{
			selected++;

			if (selected >= options.length)
				selected = 0;

			refresh();
		}

        if (controls.ACCEPT) {
            GameState.switchState(new CharacterState());
			FlxG.sound.music.volume = 0;
        }

        if (controls.BACK) {
            GameState.switchState(new MenuState());
        }
    }

	private function refresh():Void
    {
        var output:String = 'SELECT SAVE\n\n';

        for (i in 0...saves.length)
        {
            var prefix:String = i == selected ? '> ' : '  ';
            output += prefix + saves[i] + '\n';
        }

        output += '\nUP / DOWN - Select\nENTER - Open\nESC - Back';

        text.text = output;
        text.screenCenter();
	}
}

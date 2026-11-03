package substates;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

#if mobile
import mobile.TouchUtil;
#end

import states.PlayState;
import states.MenuState;
import states.options.OptionsState;

class PauseSubState extends GameSubState
{
    private var selected:Int = 0;

    private final options:Array<String> = [
        'RESUME',
        'RESTART',
        'QUIT'
    ];

    private var menuText:FlxText;

	#if mobile
	public var manager:MobileInputManager;
	#end

    public function new()
    {
        super();

		#if mobile
		manager = new MobileInputManager();
		#end

        FlxG.camera.stopFX();

        var background:FlxText = new FlxText(0, 0, FlxG.width, '', 1);
        background.scrollFactor.set();
        background.color = FlxColor.BLACK;
        background.alpha = 0.65;
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(background);

        menuText = new FlxText(0, 120, FlxG.width, '', 28);
        menuText.setFormat(null, 28, FlxColor.WHITE, CENTER);
        menuText.scrollFactor.set();
        add(menuText);

		/*#if mobile
        addCustomDPad('EXIST', 'JUMP');
		addCustomDPadCam();
        #end*/

        refresh();
    }

    override public function update(elapsed:Float):Void
    {
        if (controls.UI_UP_P)
        {
            selected--;

            if (selected < 0)
                selected = options.length - 1;

			FlxG.sound.play(Paths.sound('scroll_sound'));

            refresh();
        }

        if (controls.UI_DOWN_P)
        {
            selected++;

            if (selected >= options.length)
                selected = 0;
			
			FlxG.sound.play(Paths.sound('scroll_sound'));

            refresh();
        }

        #if mobile
        if (TouchUtil.justPressed)
        {
            for (touch in FlxG.touches.list)
            {
                if (!touch.justPressed) continue;

                // The menu has a two-line heading; each option occupies one 32px row.
                var row = Std.int((touch.y - menuText.y) / 32) - 2;
                if (row >= 0 && row < options.length)
                {
                    selected = row;
                    refresh();
                    FlxG.sound.play(Paths.sound('confirm_sound'));
                    select();
                    break;
                }
            }
        }
        #end

        if (controls.ACCEPT)
        {
            select();
        }

        /*if (controls.BACK)
        {
            close();
        }*/

        super.update(elapsed);
    }

    private function refresh():Void
    {
        var output:String = 'PAUSED\n\n';

        for (i in 0...options.length)
        {
            if (i == selected)
                output += '> ' + options[i] + ' <\n';
            else
                output += options[i] + '\n';
        }

        /*output += '\nUP / DOWN - Select';
        output += '\nENTER - Confirm';*/

        menuText.text = output;
        menuText.screenCenter();
    }

    private function select():Void
    {
        switch (options[selected])
        {
            case 'RESUME':
                close();
				FlxG.sound.music.resume();

            case 'RESTART':
                close();
				FlxG.sound.music.resume();
                GameState.resetState();

            case 'QUIT':
                close();
				FlxG.sound.music.stop();
                GameState.switchState(new MenuState());
        }
    }

    override public function close():Void
    {
        super.close();

		/*#if mobile
		removeCustomDPad();
		#end*/
    }
}

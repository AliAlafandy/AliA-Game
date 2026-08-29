package states.options;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionsState extends GameState
{
    private var selected:Int = 0;

    private final options:Array<String> = [
        'Data',
		'Controls',
		'Graphics',
		'Audio',
		'Gameplay',
    ];

    private var text:FlxText;

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

        text = new FlxText(0, 0, FlxG.width, '', 24);
        text.setFormat(null, 24, FlxColor.WHITE, CENTER);
		text.alignment(CENTER);
        add(text);

        refresh();

		#if mobile
		addCustomDPad('EXITE', 'MENU');
		addCustomDPadCam();
		#end
    }

    override public function update(elapsed:Float):Void
    {
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

        if (controls.ACCEPT)
        {
            activate();
        }

        if (controls.BACK)
        {
            GameState.switchState(new MenuState());
        }
    }

    private function activate():Void
    {
        var message:String = '';

        switch (options[selected])
        {
			case 'Data':
				#if android
                message =
                    'DATA\n\n' +
					'Sign In\n' +
                    'Save Data\n' +
                    'Load Data\n' +
                    'Delete Data\n' +
					'Check Updates: true\n' +
					'Storage Type: EXTERNAL_DATA';
				#else
				message =
                    'DATA\n\n' +
					'Sign In\n' +
                    'Savne Data\n' +
                    'Load Data\n' +
                    'Delete Data\n' +
					'Check Updates: true';
				#end

			case 'Controls':
				#if mobile
                message =
                    'CONTROLS\n\n' +
                    'Controls Color: Yellow\n' +
                    'Controls Alpha: 0.6\n' +
                    'Edit Controls';
				#else
				message =
                    'CONTROLS\n\n' +
                    'Arrow Keys / WASD\n' +
                    'ENTER - Confirm\n' +
                    'ESC - Back';
				#end

            case 'Graphics':
				#if mobile
                message =
                    'GRAPHICS\n\n' +
					'Show FPS: false\n' +
                    'Framerate: 60\n' +
					'Flashing Lights: true\n' +
					'Themes: Normal';
				#else
				message =
                    'GRAPHICS\n\n' +
                    'Resolution: 1280x720\n' +
					'Show FPS: false\n' +
                    'Framerate: 60\n' +
					'Flashing Lights: true\n' +
					'Themes: Normal\n' +
                    'Fullscreen: false';
				#end

            case 'Audio':
                message =
                    'AUDIO\n\n' +
                    'Master volume: ' +
                    Std.int(FlxG.sound.volume * 100) +
                    '%';

            case 'Gameplay':
				#if mobile
                message =
                    'GAMEPLAY\n\n' +
                    'Down Scroll: false\n' +
					'Shaders: true';
				#else
				message =
                    'GAMEPLAY\n\n' +
                    'Down Scroll: false\n' +
					'Shaders: true\n' +
					'Discord RPC: true';
				#end
		}

        text.text =
            message +
            '\n\nPress ESC to return.';

        text.screenCenter();
    }

    private function refresh():Void
    {
        var output:String = 'OPTIONS\n\n';

        for (i in 0...options.length)
        {
            var prefix:String = i == selected ? '> ' : '';
			var prefix2:String = i == selected ? ' <' : '';
            output += prefix + options[i] + prefix2 + '\n';
        }

        output += '\nUP / DOWN - Select\nENTER - Open\nESC - Back';

        text.text = output;
        text.screenCenter();
    }
}

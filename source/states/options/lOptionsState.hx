package states.options;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class lOptionsState extends GameState
{
    private var selected:Int = 0;

    private final options:Array<String> = [
        'Data',
		'Controls',
		'Graphics',
		'Audio',
		'Gameplay',
    ];

	public var bg:FlxSprite;
    private var text:FlxText;

    function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Data':
				openSubState(new substates.options.DataSubState());
			case 'Controls':
				openSubState(new substates.options.ControlsSubState());
			case 'Graphics':
				openSubState(new substates.options.GraphicsSubState());
			case 'Audio':
				openSubState(new substates.options.AudioSubState());
			case 'Gameplay':
				openSubState(new substates.options.GameplaySubState());
		}
	}

    override function create()
    {
        super.create();

        bg = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/Options/background'));
		add(bg);

		for (i in 0...options.length)
		{
			var optionText:FlxText = new FlxText(0, 0, FlxG.width, options[i], 24);
			optionText.setFormat(null, 24, FlxColor.WHITE, CENTER);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			add(optionText);
		}

        text = new FlxText(0, 0, FlxG.width, '', 24);
        text.setFormat(null, 24, FlxColor.WHITE, CENTER);
        add(text);

		refresh();

		#if mobile
		addCustomDPad('EXITE', 'MENU');
		addCustomDPadCam();
		#end
    }

	override function closeSubState() {
		super.closeSubState();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		ClientPrefs.saveSettings();
		ClientPrefs.loadPrefs();
		controls.isInSubstate = false;

		#if mobile
		removeCustomDPad();
		addCustomDPad("EXITE", "MENU");
		#end
	}

    override function update(elapsed:Float)
    {
        super.update(elapsed);

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('menus/menu'));

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

        if (controls.ACCEPT)
        {
			FlxG.sound.play(Paths.sound('confirm_sound'));
            openSelectedSubstate(options[curSelected]);
        }

        if (controls.BACK)
        {
			FlxG.sound.play(Paths.sound('cancel_sound'));
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

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}

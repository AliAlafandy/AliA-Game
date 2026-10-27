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
            openSelectedSubstate(options[selected]);
        }

        if (controls.BACK)
        {
			FlxG.sound.play(Paths.sound('cancel_sound'));
            GameState.switchState(new MenuState());
        }
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

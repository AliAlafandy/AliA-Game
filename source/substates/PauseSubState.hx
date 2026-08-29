package substates;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

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
		menuText.alignment(CENTER);
        menuText.scrollFactor.set();
        add(menuText);

        #if mobile
        addCustomDPad('EXITE', 'JUMP');
		addCustomDPadCam();
        #end

        refresh();
    }

    override public function update(elapsed:Float):Void
    {
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

        output += '\nUP / DOWN - Select';
        output += '\nENTER - Confirm';

        menuText.text = output;
        menuText.screenCenter();
    }

    private function select():Void
    {
        switch (options[selected])
        {
            case 'RESUME':
                close();

            case 'RESTART':
                close();
                GameState.resetState();

            case 'QUIT':
                close();
                GameState.switchState(new MenuState());
        }
    }

    override public function close():Void
    {
        FlxG.sound.music.resume();
        super.close();
    }
}

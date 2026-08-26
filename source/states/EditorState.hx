package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class EditorState extends GameState
{
    private var info:FlxText;

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

        FlxG.camera.bgColor = FlxColor.BLACK;

        var title:FlxText = new FlxText(
            0,
            80,
            FlxG.width,
            'ALI A GAME EDITOR',
            32
        );
        title.setFormat(null, 32, FlxColor.WHITE, CENTER);
        add(title);

        info = new FlxText(
            80,
            180,
            FlxG.width - 160,
            '',
            20
        );

        info.text =
            'EDITOR\n\n' +
            '- Level Editor\n' +
            '- Character Editor\n' +
            '- Animation Editor\n' +
            '- Script Editor\n\n' +
            'ESC - Return';

        info.setFormat(null, 20, FlxColor.WHITE, CENTER);
        add(info);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (controls.BACK)
            FlxG.switchState(new MenuState());
    }
}

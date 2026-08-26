package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import data.objects.Player;

#if mobile
import mobile.data.MobileInputManager;
#end

#if DISCORD_ALLOWED
import data.DiscordRPC;
#end

class PlayState extends GameState
{
    public var player:Player;

    private var elapsedTime:Float = 0;
    private var rpcTimer:Float = 0;

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

        player = new Player(0, 0, 'Ellawy', true);
        player.screenCenter();
        add(player);

        var title:FlxText = new FlxText(
            0,
            20,
            FlxG.width,
            'ALI ALAFANDY GAME',
            24
        );
        title.setFormat(null, 24, FlxColor.WHITE, CENTER);
        add(title);

        var help:FlxText = new FlxText(
            0,
            FlxG.height - 50,
            FlxG.width,
            'ARROW KEYS / WASD    PAUSE: ESC',
            16
        );
        help.setFormat(null, 16, FlxColor.WHITE, CENTER);
        add(help);

        #if mobile
		addCustomDPad();
		addCustomDPadCam();
		#end

        #if DISCORD_ALLOWED
        DiscordClient.changePresence('Play - Ali Alafandy Game',null);
        #end
    }

    override public function update(elapsed:Float):Void
    {
        elapsedTime += elapsed;
        rpcTimer += elapsed;

        handleInput();

        #if DISCORD_ALLOWED
        if (rpcTimer >= 1)
        {
            rpcTimer = 0;
            DiscordClient.changePresence('Playing Ali-A Game\n' + 'Play - ATown Act1' + "Time :" + Std.int(elapsedTime) ,null);
        }
        #end

        super.update(elapsed);
    }

    private function handleInput():Void
    {
        if (controls.BACK)
        {
            FlxG.switchState(new MenuState());
        }
    }

    override public function destroy():Void
    {
        player = null;

        super.destroy();
    }
}

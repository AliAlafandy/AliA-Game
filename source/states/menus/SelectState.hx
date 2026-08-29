package states.menus;

import states.MenuState;

class SelectState extends GameState {

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

        var t = new FlxText(0, 0, 0,
        	"SELECT SAVE\n
        	\n
        	NEW GAME 1\n
        	NEW GAME 2\n
        	NEW GAME 3\n
        	NEW GAME 4\n
        	NEW GAME 5\n
        	NEW GAME 6\n
        	NEW GAME 7\n
        	NEW GAME 8\n
        	\n
        	ENTER to Continue",
         14);
        t.screenCenter();
        add(t);

        #if mobile
		addCustomDPad('EXITE', 'MENU');
		addCustomDPadCam();
		#end
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (controls.ACCEPT) {
            GameState.switchState(new CharacterState());
			FlxG.sound.music.volume = 0;
        }
        if (controls.BACK) {
            GameState.switchState(new MenuState());
        }
    }
}

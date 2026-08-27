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
		addCustomDPad();
		addCustomDPadCam();
		#end
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (controls.ACCEPT) {
            FlxG.switchState(new CharacterState());
        }
        if (controls.BACK) {
            FlxG.switchState(new MenuState());
        }
    }
}

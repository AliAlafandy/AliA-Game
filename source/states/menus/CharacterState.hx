package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxAxes;

class CharacterState extends GameState {
    var index:Int = 0;
    var chars:Array<String> = [
        "Ellawy",
        "Hamedo",
        "Zezo",
        "Shaaban",
        "Ellawy+"
    ];
    var txt:FlxText;
    var iconSprite:FlxSprite;

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

        var charPlace:FlxSprite = new FlxSprite(30, 30).loadGraphic(Paths.image('menus/Selects/char_place'));
        charPlace.scale.set(0.5, 0.5);
        charPlace.updateHitbox();
        add(charPlace);

        iconSprite = new FlxSprite(charPlace.x, charPlace.y);
        add(iconSprite);

        txt = new FlxText(0, 0, 0, "", 16);
        txt.screenCenter();
        add(txt);
        updateChar();

        #if mobile
        addCustomDPad('EXITE', 'MENU');
        addCustomDPadCam();
        #end
    }

    function updateChar() {
        txt.text = "Select Character:\n< " + chars[index] + " >\n\nENTER to Play";
        txt.screenCenter();

        var charName = chars[index];
        var iconPath = "";

        if (charName == "Ellawy+") {
            iconPath = 'characters/Ellawy/icon-partner';
        } else {
            iconPath = 'characters/' + charName + '/icon';
        }

        try {
            iconSprite.loadGraphic(Paths.image(iconPath));
        } catch (e:Dynamic) {
            iconSprite.makeGraphic(64, 64, 0x00000000);
        }
        
        iconSprite.scale.set(0.65, 0.65);
        iconSprite.updateHitbox();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.sound.music == null)
            FlxG.sound.playMusic(Paths.music('menus/select_character'));

        var oldIndex = index;
        if (controls.UI_LEFT_P) index--;
        if (controls.UI_RIGHT_P) index++;
        index = (index + chars.length) % chars.length;

        if (oldIndex != index) {
            updateChar();
        }

        if (controls.ACCEPT) {
            GameState.switchState(new PlayState());
            FlxG.sound.play(Paths.sound('confirm_sound'));
            FlxG.sound.music.volume = 0;
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancel_sound'));
            GameState.switchState(new SelectState());
        }
    }
}

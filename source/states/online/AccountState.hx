package states.online;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import openfl.events.Event;
import openfl.events.TextEvent;

import data.backend.GameState;
import states.online.OnlineState;
import states.options.OptionsState;

class AccountState extends GameState
{
    var usernameInput:TextInputField;
    var passwordInput:TextInputField;
    var activeInput:TextInputField;
    var statusText:FlxText;

    public function new()
    {
        super();
    }

    override public function create()
    {
        super.create();

        var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/background'));
        add(bg);

        var titleText = new FlxText(0, 40, 0, "ACCOUNT", 32);
        titleText.screenCenter(FlxAxes.X);
        add(titleText);

        var inputWidth = 300;
        var centerX = (FlxG.width - inputWidth) / 2;

        usernameInput = new TextInputField(centerX, 120, inputWidth, "Username or Email");
        add(usernameInput.display);

        passwordInput = new TextInputField(centerX, 180, inputWidth, "Password");
        add(passwordInput.display);

        var loginBtn = new FlxButton(centerX, 240, "Login", onLogin);
        loginBtn.setGraphicSize(Std.int(loginBtn.width * 1.2), Std.int(loginBtn.height * 1.3));
        loginBtn.updateHitbox();
        add(loginBtn);

        var registerBtn = new FlxButton(centerX + 100, 240, "Register", onRegister);
        registerBtn.setGraphicSize(Std.int(loginBtn.width * 1.2), Std.int(loginBtn.height * 1.3));
        registerBtn.updateHitbox();
        add(registerBtn);

        statusText = new FlxText(0, 360, FlxG.width, "", 16);
        statusText.alignment = CENTER;
        statusText.color = FlxColor.YELLOW;
        add(statusText);

        #if mobile
        addCustomDPad('NONE', 'BACK');
        addCustomDPadCam();
        #end

        #if (js || sys)
        openfl.Lib.current.stage.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
        #if mobile
        openfl.Lib.current.stage.addEventListener(Event.RESIZE, onStageResize);

        function onStageResize(e:Event):Void {
            var keyboardHeight = FlxG.stage.stageHeight - FlxG.stage.window.height;
            if (keyboardHeight > 0) {
                y = -keyboardHeight / 2;
            } else {
                y = 0;
            }
        }
        #end
        #end
    }

    function onLogin()
    {
        if (usernameInput.value.length == 0 || passwordInput.value.length == 0)
        {
            statusText.text = "Please fill in all fields.";
            statusText.color = FlxColor.RED;
            return;
        }

        statusText.text = "Logging in...";
        statusText.color = FlxColor.YELLOW;

        var payload = {
            identifier: usernameInput.value,
            password: passwordInput.value
        };

        sendPostRequest("https://alia-server.onrender.com/api/login", payload, onDataLoaded, onDataError);
    }

    function onRegister()
    {
        if (usernameInput.value.length == 0 || passwordInput.value.length == 0)
        {
            statusText.text = "Please fill in all fields.";
            statusText.color = FlxColor.RED;
            return;
        }

        statusText.text = "Registering...";
        statusText.color = FlxColor.YELLOW;

        var payload = {
            username: usernameInput.value,
            password: passwordInput.value,
            email: usernameInput.value + "@example.com",
            phone: ""
        };

        sendPostRequest("https://alia-server.onrender.com/api/register", payload, onDataLoaded, onDataError);
    }

    function onDataLoaded(data:Dynamic)
    {
        if (data.success)
        {
            var uname = data.username != null ? data.username : usernameInput.value;
            statusText.text = "Success! Welcome, " + uname;
            statusText.color = FlxColor.LIME;
            FlxG.save.data.loggedInUser = uname;
            FlxG.save.flush();
            new flixel.util.FlxTimer().start(1.5, function(tmr:flixel.util.FlxTimer) {
                FlxG.switchState(new OptionsState());
            });
        }
        else
        {
            statusText.text = data.error != null ? data.error : "Failed.";
            statusText.color = FlxColor.RED;
        }
    }

    function onDataError(reason:String)
    {
        statusText.text = "Network error: " + reason;
        statusText.color = FlxColor.RED;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.sound.music == null)
			      FlxG.sound.playMusic(Paths.music('menus/menu'));

        if (FlxG.mouse.justPressed)
        {
            if (usernameInput.display.overlapsPoint(FlxG.mouse.getPosition()))
                setActiveInput(usernameInput);
            else if (passwordInput.display.overlapsPoint(FlxG.mouse.getPosition()))
                setActiveInput(passwordInput);
            else
                setActiveInput(null);
        }

        handleTextControlKeys();

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancel_sound'));
            FlxG.switchState(new OptionsState());
        }
    }

    function setActiveInput(field:TextInputField):Void
    {
        if (activeInput != null)
            activeInput.unfocus();

        activeInput = field;

        if (activeInput != null)
            activeInput.focus();
    }

    function handleTextControlKeys():Void
    {
        if (activeInput == null)
            return;

        if (FlxG.keys.justPressed.BACKSPACE)
            activeInput.handleBackspace();

        if (FlxG.keys.justPressed.ENTER)
        {
            if (activeInput == passwordInput)
                onLogin();
        }

        if (FlxG.keys.justPressed.ESCAPE)
            setActiveInput(null);
    }

    #if (js || sys)
    function onTextInput(event:TextEvent):Void
    {
        if (activeInput != null)
            activeInput.handleChar(event.text);
    }
    #end

    override public function destroy():Void
    {
        #if (js || sys)
        openfl.Lib.current.stage.removeEventListener(TextEvent.TEXT_INPUT, onTextInput);
        #end
        super.destroy();
    }

    function sendPostRequest(url:String, payload:Dynamic, onSuccess:Dynamic->Void, onError:String->Void)
    {
        var req = new haxe.Http(url);
        req.addHeader("Content-Type", "application/json");
        req.onData = function(data:String) {
            try {
                var json = haxe.Json.parse(data);
                onSuccess(json);
            } catch(e:Dynamic) {
                onError("Invalid response");
            }
        };
        req.onError = function(error:String) {
            onError(error);
        };
        req.request(haxe.Json.stringify(payload));
    }
}

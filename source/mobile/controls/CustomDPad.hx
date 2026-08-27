package mobile.controls;

import mobile.data.MobileInputManager;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxSignal.FlxTypedSignal;

class CustomDPad extends MobileInputManager implements IMobileControls
{
	public var buttonLeft:TouchButton;
	public var buttonUp:TouchButton;
	public var buttonRight:TouchButton;
	public var buttonDown:TouchButton;
	
	public var buttonExtra:TouchButton = null;
	public var buttonExtra2:TouchButton = null;
	
	public var instance:MobileInputManager;

	public var onButtonDown:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();
	public var onButtonUp:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();

	public var dpadBg:TouchButton;

	public var jumpButton:TouchButton;
	public var powerButton:TouchButton;
	public var backButton:TouchButton;
	public var pauseButton:TouchButton;

	public function new(X:Float, Y:Float)
	{
		super();

		instance = this;

		var color:String;
		switch (ClientPrefs.data.controlsColor) {
			case 'Yellow':
				color = 'yellow';

			case 'Blue':
				color = 'blue';
		}

		var path = Paths.getPath('d-pad_' + color + '.xml', 'mobile');
		var path2 = Paths.getPath('d-pad_' + color + '.png', 'mobile');
		trace(path);
		trace(path2);
		var customFrames = Paths.getSparrowAtlas('d-pad_' + color , 'mobile');

		dpadBg = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			dpadBg.frames = customFrames;
			dpadBg.animation.addByPrefix('idle', 'pad', 0, false);
			dpadBg.animation.play('idle');
		}
		dpadBg.scale.set(0.55, 0.55);
		dpadBg.updateHitbox();
		// dpadBg.scrollFactor.set();
		dpadBg.alpha = ClientPrefs.data.controlsAlpha;
		dpadBg.antialiasing = ClientPrefs.data.antialiasing;
		add(dpadBg);
		
		buttonLeft = createCustomButton(X, Y + 100, 'touch Left', [MobileInputID.GAME_LEFT, MobileInputID.LEFT, MobileInputID.LEFT2], customFrames);
		buttonDown = createCustomButton(X + 100, Y + 200, 'touch Down', [MobileInputID.GAME_DOWN, MobileInputID.DOWN, MobileInputID.DOWN2], customFrames);
		buttonUp = createCustomButton(X + 100, Y, 'touch Up', [MobileInputID.GAME_UP, MobileInputID.UP, MobileInputID.UP2], customFrames);
		buttonRight = createCustomButton(X + 200, Y + 100, 'touch Right', [MobileInputID.GAME_RIGHT, MobileInputID.RIGHT, MobileInputID.RIGHT2], customFrames);

		jumpButton = createCustomButton(FlxG.width - 250, FlxG.height - 150, 'jump Idle', [MobileInputID.JUMP, MobileInputID.Z], customFrames);
		powerButton = createCustomButton(FlxG.width - 330, FlxG.height - 250, 'power Idle', [MobileInputID.POWER, MobileInputID.C], customFrames);
		backButton = createCustomButton(380, 150, 'back', [MobileInputID.BACK_M, MobileInputID.B], customFrames);
		pauseButton = createCustomButton(FlxG.width - 130, 150, 'pause', [MobileInputID.PAUSE, MobileInputID.P], customFrames);

		add(buttonLeft);
		add(buttonDown);
		add(buttonUp);
		add(buttonRight);

		add(jumpButton);
		add(powerButton);
		add(backButton);
		add(pauseButton);

		updateTrackedButtons();
	}

	private function createCustomButton(X:Float, Y:Float, frameName:String, IDs:Array<MobileInputID>, frames:Dynamic):TouchButton
	{
		var button = new TouchButton(X, Y, IDs);
		
		if (frames != null)
		{
			button.frames = frames;
			if (frames.getByName(frameName) != null)
			{
				button.animation.addByPrefix('idle', frameName, 0, false);
				button.animation.play('idle');
			}
			else
			{
				button.animation.addByPrefix('idle', 'touch Idle', 0, false);
				button.animation.play('idle');
			}
		}
		else
		{
			button.loadGraphic(Paths.image('touchpad/bg', "mobile"));
		}

		button.scale.set(0.5, 0.5);
		button.updateHitbox();
		button.scrollFactor.set();
		button.immovable = true;
		button.solid = button.moves = false;
		button.antialiasing = ClientPrefs.data.antialiasing;

		button.onDown.callback = () -> onButtonDown.dispatch(button);
		button.onOut.callback = button.onUp.callback = () -> onButtonUp.dispatch(button);

		return button;
	}

	override public function destroy():Void
	{
		super.destroy();
		onButtonUp.destroy();
		onButtonDown.destroy();
	}
}

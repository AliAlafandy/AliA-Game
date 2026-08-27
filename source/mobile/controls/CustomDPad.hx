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

	public var padBG:TouchButton;
	public var dPad:TouchButton;
	public var arrows:TouchButton;

	public var jumpBG:TouchButton;
	public var jumpPad:TouchButton;

	public var powerBG:TouchButton;
	public var powerPad:TouchButton;

	public var jumpButton:TouchButton;
	public var powerButton:TouchButton;

	public var backButton:TouchButton;
	public var pauseButton:TouchButton;

	public var scale:Float = 0.75;

	public function new(X:Float, Y:Float)
	{
		super();

		instance = this;

		var color:String = 'yellow'; //'blue'

		var path = Paths.getPath('d-pad_' + color + '.xml', 'mobile');
		var path2 = Paths.getPath('d-pad_' + color + '.png', 'mobile');
		trace(path);
		trace(path2);
		var customFrames = Paths.getSparrowAtlas('d-pad_' + color , 'mobile');

		padBG = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			padBG.frames = customFrames;
			padBG.animation.addByPrefix('bg', 'pad0000', 0, false);
			padBG.animation.play('bg');
		}
		padBG.scale.set(scale, scale);
		padBG.updateHitbox();
		// padBG.scrollFactor.set();
		padBG.alpha = ClientPrefs.data.controlsAlpha;
		padBG.antialiasing = ClientPrefs.data.antialiasing;
		add(padBG);

		dPad = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			dPad.frames = customFrames;
			dPad.animation.addByPrefix('idle', 'touch Idle0000', 0, false);
			dPad.animation.addByPrefix('left', 'touch Left0000', 0, false);
			dPad.animation.addByPrefix('down', 'touch Down0000', 0, false);
			dPad.animation.addByPrefix('up', 'touch Up0000', 0, false);
			dPad.animation.addByPrefix('right', 'touch Right0000', 0, false);
			dPad.animation.addByPrefix('ld', 'touch LD0000', 0, false);
			dPad.animation.addByPrefix('lu', 'touch LU0000', 0, false);
			dPad.animation.addByPrefix('ur', 'touch UR0000', 0, false);
			dPad.animation.addByPrefix('dr', 'touch DR0000', 0, false);
			dPad.animation.addByPrefix('du', 'touch DU0000', 0, false);
			dPad.animation.addByPrefix('lr', 'touch LR0000', 0, false);
			dPad.animation.addByPrefix('ldu', 'touch LDU0000', 0, false);
			dPad.animation.addByPrefix('ldr', 'touch LDR0000', 0, false);
			dPad.animation.addByPrefix('lur', 'touch LUR0000', 0, false);
			dPad.animation.addByPrefix('dur', 'touch DUR0000', 0, false);
			dPad.animation.addByPrefix('full', 'touch Full0000', 0, false);
			dPad.animation.play('idle');
		}
		dPad.scale.set(scale, scale);
		dPad.updateHitbox();
		// dPad.scrollFactor.set();
		dPad.alpha = ClientPrefs.data.controlsAlpha;
		dPad.antialiasing = ClientPrefs.data.antialiasing;
		add(dPad);

		arrows = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			arrows.frames = customFrames;
			arrows.animation.addByPrefix('arrows', 'arrows0000', 0, false);
			arrows.animation.play('arrows');
		}
		arrows.scale.set(scale, scale);
		arrows.updateHitbox();
		// arrows.scrollFactor.set();
		arrows.alpha = ClientPrefs.data.controlsAlpha;
		arrows.antialiasing = ClientPrefs.data.antialiasing;
		add(arrows);
		
		buttonLeft = createCustomButton(X, Y + 100, 'null0000', [MobileInputID.GAME_LEFT, MobileInputID.LEFT, MobileInputID.LEFT2], customFrames);
		buttonDown = createCustomButton(X + 100, Y + 200, 'null0000', [MobileInputID.GAME_DOWN, MobileInputID.DOWN, MobileInputID.DOWN2], customFrames);
		buttonUp = createCustomButton(X + 100, Y, 'null0000', [MobileInputID.GAME_UP, MobileInputID.UP, MobileInputID.UP2], customFrames);
		buttonRight = createCustomButton(X + 200, Y + 100, 'null0000', [MobileInputID.GAME_RIGHT, MobileInputID.RIGHT, MobileInputID.RIGHT2], customFrames);

		jumpBG = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			jumpBG.frames = customFrames;
			jumpBG.animation.addByPrefix('bg', 'jump Pad0000', 0, false);
			jumpBG.animation.play('bg');
		}
		jumpBG.scale.set(scale, scale);
		jumpBG.updateHitbox();
		// jumpBG.scrollFactor.set();
		jumpBG.alpha = ClientPrefs.data.controlsAlpha;
		jumpBG.antialiasing = ClientPrefs.data.antialiasing;
		add(jumpBG);

		jumpPad = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			jumpPad.frames = customFrames;
			jumpPad.animation.addByPrefix('idle', 'jump Idle0000', 0, false);
			jumpPad.animation.addByPrefix('press', 'jump Press0000', 0, false);
			jumpPad.animation.play('idle');
		}
		jumpPad.scale.set(scale, scale);
		jumpPad.updateHitbox();
		// jumpPad.scrollFactor.set();
		jumpPad.alpha = ClientPrefs.data.controlsAlpha;
		jumpPad.antialiasing = ClientPrefs.data.antialiasing;
		add(jumpPad);

		powerBG = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			powerBG.frames = customFrames;
			powerBG.animation.addByPrefix('bg', 'power Pad0000', 0, false);
			powerBG.animation.play('bg');
		}
		powerBG.scale.set(scale, scale);
		powerBG.updateHitbox();
		// powerBG.scrollFactor.set();
		powerBG.alpha = ClientPrefs.data.controlsAlpha;
		powerBG.antialiasing = ClientPrefs.data.antialiasing;
		add(powerBG);

		powerPad = new TouchButton(X, Y, []);
		if (customFrames != null)
		{
			powerPad.frames = customFrames;
			powerPad.animation.addByPrefix('idle', 'power Idle0000', 0, false);
			powerPad.animation.addByPrefix('press', 'power Press0000', 0, false);
			powerPad.animation.play('idle');
		}
		powerPad.scale.set(scale, scale);
		powerPad.updateHitbox();
		// powerPad.scrollFactor.set();
		powerPad.alpha = ClientPrefs.data.controlsAlpha;
		powerPad.antialiasing = ClientPrefs.data.antialiasing;
		add(powerPad);

		jumpButton = createCustomButton(FlxG.width - 250, FlxG.height - 150, 'null0000', [MobileInputID.JUMP, MobileInputID.Z], customFrames);
		powerButton = createCustomButton(FlxG.width - 130, FlxG.height - 250, 'null0000', [MobileInputID.POWER, MobileInputID.C], customFrames);

		backButton = createCustomButton(10, 10, 'back0000', [MobileInputID.BACK_M, MobileInputID.B], customFrames);
		pauseButton = createCustomButton(FlxG.width - 10, 10, 'pause0000', [MobileInputID.PAUSE, MobileInputID.P], customFrames);

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
				button.animation.addByPrefix('idle', 'touch Idle0000', 0, false);
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

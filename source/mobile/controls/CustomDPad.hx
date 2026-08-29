package mobile.controls;

import mobile.data.MobileInputManager;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxSignal.FlxTypedSignal;

class CustomDPad extends MobileInputManager implements IMobileControls
{
	public var padBG:TouchButton;
	public var dPad:TouchButton;
	public var arrows:TouchButton;

	public var buttonLeft:TouchButton;
	public var buttonUp:TouchButton;
	public var buttonRight:TouchButton;
	public var buttonDown:TouchButton;

	public var jumpBG:TouchButton;
	public var jumpPad:TouchButton;

	public var powerBG:TouchButton;
	public var powerPad:TouchButton;

	public var backPad:TouchButton;
	public var pausePad:TouchButton;

	public var jumpButton:TouchButton;
	public var powerButton:TouchButton;
	public var backButton:TouchButton;
	public var pauseButton:TouchButton;
	
	public var buttonExtra:TouchButton = null;
	public var buttonExtra2:TouchButton = null;
	
	public var instance:MobileInputManager;

	public var onButtonDown:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();
	public var onButtonUp:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();

	public function new(X:Float, Y:Float)
	{
		super();

		instance = this;

		var color:String; //'yellow' / 'blue'
		if (ClientPrefs.data.controlsColor == 'Yellow') {
			color = 'yellow';
		} else if (ClientPrefs.data.controlsColor == 'Blue') {
			color = 'blue';
		} else {
			color = 'yellow';
		}

		var path = Paths.getPath('d-pad_' + color + '.xml', 'mobile');
		var path2 = Paths.getPath('d-pad_' + color + '.png', 'mobile');
		trace(path);
		trace(path2);
		var customFrames = Paths.getSparrowAtlas('d-pad_' + color , 'mobile');

		var offset:Float = 30;

		var scalePad:Float = 1;
		var scaleAction:Float = scalePad - 0.25;

		padBG = new TouchButton(X + offset - 18, Y + offset + 35, []);
		if (customFrames != null)
		{
			padBG.frames = customFrames;
			padBG.animation.addByPrefix('bg', 'pad0000', 0, false);
			padBG.animation.play('bg');
		}
		padBG.scale.x = scalePad;
		padBG.scale.y = scalePad;
		padBG.updateHitbox();
		padBG.alpha = ClientPrefs.data.controlsAlpha;
		padBG.antialiasing = ClientPrefs.data.antialiasing;
		add(padBG);

		dPad = new TouchButton(padBG.x + offset, padBG.y + offset, []);
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
		dPad.scale.x = scalePad;
		dPad.scale.y = scalePad;
		dPad.updateHitbox();
		dPad.alpha = ClientPrefs.data.controlsAlpha;
		dPad.antialiasing = ClientPrefs.data.antialiasing;
		add(dPad);

		arrows = new TouchButton(dPad.x + offset - 5, dPad.y + offset - 5, []);
		if (customFrames != null)
		{
			arrows.frames = customFrames;
			arrows.animation.addByPrefix('arrows', 'arrows0000', 0, false);
			arrows.animation.play('arrows');
		}
		arrows.scale.x = scalePad;
		arrows.scale.y = scalePad;
		arrows.updateHitbox();
		arrows.alpha = ClientPrefs.data.controlsAlpha;
		arrows.antialiasing = ClientPrefs.data.antialiasing;
		add(arrows);
		
		buttonLeft = createCustomButton(X + 20, Y + 150, 0.5, 0.5, 'null0000', [MobileInputID.GAME_LEFT, MobileInputID.LEFT, MobileInputID.LEFT2], customFrames);
		buttonDown = createCustomButton(X + 100, Y + 235, 0.5, 0.5, 'null0000', [MobileInputID.GAME_DOWN, MobileInputID.DOWN, MobileInputID.DOWN2], customFrames);
		buttonUp = createCustomButton(X + 100, Y + 65, 0.5, 0.5, 'null0000', [MobileInputID.GAME_UP, MobileInputID.UP, MobileInputID.UP2], customFrames);
		buttonRight = createCustomButton(X + 180, Y + 150, 0.5, 0.5, 'null0000', [MobileInputID.GAME_RIGHT, MobileInputID.RIGHT, MobileInputID.RIGHT2], customFrames);

		jumpBG = new TouchButton(FlxG.width - 277 + X, Y + 170, []);
		if (customFrames != null)
		{
			jumpBG.frames = customFrames;
			jumpBG.animation.addByPrefix('bg', 'jump Pad0000', 0, false);
			jumpBG.animation.play('bg');
		}
		jumpBG.scale.x = scaleAction;
		jumpBG.scale.y = scaleAction;
		jumpBG.updateHitbox();
		jumpBG.alpha = ClientPrefs.data.controlsAlpha;
		jumpBG.antialiasing = ClientPrefs.data.antialiasing;
		add(jumpBG);

		jumpPad = new TouchButton(jumpBG.x + offset - 7, jumpBG.y + offset - 7, []);
		if (customFrames != null)
		{
			jumpPad.frames = customFrames;
			jumpPad.animation.addByPrefix('idle', 'jump Idle0000', 0, false);
			jumpPad.animation.addByPrefix('press', 'jump Press0000', 0, false);
			jumpPad.animation.play('idle');
		}
		jumpPad.scale.x = scaleAction;
		jumpPad.scale.y = scaleAction;
		jumpPad.updateHitbox();
		jumpPad.alpha = ClientPrefs.data.controlsAlpha;
		jumpPad.antialiasing = ClientPrefs.data.antialiasing;
		add(jumpPad);

		powerBG = new TouchButton(FlxG.width - 165 + X, Y + 60, []);
		if (customFrames != null)
		{
			powerBG.frames = customFrames;
			powerBG.animation.addByPrefix('bg', 'power Pad0000', 0, false);
			powerBG.animation.play('bg');
		}
		powerBG.scale.x = scaleAction;
		powerBG.scale.y = scaleAction;
		powerBG.updateHitbox();
		powerBG.alpha = ClientPrefs.data.controlsAlpha;
		powerBG.antialiasing = ClientPrefs.data.antialiasing;
		add(powerBG);

		powerPad = new TouchButton(powerBG.x + offset - 10, powerBG.y + offset - 10, []);
		if (customFrames != null)
		{
			powerPad.frames = customFrames;
			powerPad.animation.addByPrefix('idle', 'power Idle0000', 0, false);
			powerPad.animation.addByPrefix('press', 'power Press0000', 0, false);
			powerPad.animation.play('idle');
		}
		powerPad.scale.x = scaleAction;
		powerPad.scale.y = scaleAction;
		powerPad.updateHitbox();
		powerPad.alpha = ClientPrefs.data.controlsAlpha;
		powerPad.antialiasing = ClientPrefs.data.antialiasing;
		add(powerPad);

		backPad = new TouchButton(X - 20, Y - 340, []);
		if (customFrames != null)
		{
			backPad.frames = customFrames;
			backPad.animation.addByPrefix('back', 'back0000', 0, false);
			backPad.animation.play('back');
		}
		backPad.scale.x = scaleAction;
		backPad.scale.y = scaleAction;
		backPad.updateHitbox();
		backPad.alpha = ClientPrefs.data.controlsAlpha;
		backPad.antialiasing = ClientPrefs.data.antialiasing;
		add(backPad);

		pausePad = new TouchButton(FlxG.width - 120 + X, Y - 340, []);
		if (customFrames != null)
		{
			pausePad.frames = customFrames;
			pausePad.animation.addByPrefix('stop', 'pause0000', 0, false);
			pausePad.animation.play('stop');
		}
		pausePad.scale.x = scaleAction;
		pausePad.scale.y = scaleAction;
		pausePad.updateHitbox();
		pausePad.alpha = ClientPrefs.data.controlsAlpha;
		pausePad.antialiasing = ClientPrefs.data.antialiasing;
		add(pausePad);

		jumpButton = createCustomButton(FlxG.width - 200, FlxG.height - 150, 1, 1, 'null0000', [MobileInputID.JUMP, MobileInputID.Z], customFrames);
		powerButton = createCustomButton(FlxG.width - 100, FlxG.height - 260, 1, 1, 'power Idle0000', [MobileInputID.POWER, MobileInputID.C], customFrames);
		backButton = createCustomButton(27, 30, 1, 1, 'null0000', [MobileInputID.BACK_M, MobileInputID.B], customFrames);
		pauseButton = createCustomButton(FlxG.width - 95, 30, 1, 1, 'pause0000', [MobileInputID.PAUSE, MobileInputID.P], customFrames);

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

	override function update(elapsed:Float)
	{
		if (buttonLeft.justPressed || buttonLeft.pressed)
		{
			dPad.animation.play('left');
		} else if (buttonDown.justPressed || buttonDown.pressed) {
			dPad.animation.play('down');
		} else if (buttonUp.justPressed || buttonUp.pressed) {
			dPad.animation.play('up');
		} else if (buttonRight.justPressed || buttonRight.pressed) {
			dPad.animation.play('right');
		} else {
			dPad.animation.play('idle');
		}

		if (jumpButton.justPressed || jumpButton.pressed)
		{
			jumpPad.animation.play('press');
		} else {
			jumpPad.animation.play('idle');
		}

		if (powerButton.justPressed || powerButton.pressed)
		{
			powerPad.animation.play('press');
		} else {
			powerPad.animation.play('idle');
		}

		super.update(elapsed);
	}

	private function createCustomButton(X:Float, Y:Float, Width:Float, Height:Float, frameName:String, IDs:Array<MobileInputID>, frames:Dynamic):TouchButton
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

		button.scale.set(Width, Height);
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

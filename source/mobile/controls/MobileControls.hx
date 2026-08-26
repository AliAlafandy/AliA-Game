package mobile.controls;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxDestroyUtil;

class MobileControls extends FlxTypedSpriteGroup<MobileInputManager>
{
	public var touchPad:Dynamic = null;

	public function new(?forceType:Int, ?extra:Bool = true)
	{
		super();
		MobileData.forcedMode = forceType;
		switch (MobileData.mode)
		{
			case 0:
				initControler(0);
			case 1:
				initControler(1);
			case 2:
				initControler(2);
			case 3:
				initControler(3);
		}
		alpha = ClientPrefs.data.controlsAlpha;
	}

	private function initControler(controlMode:Int = 0, ?extra:Bool = true):Void
	{
		switch (controlMode)
		{
			case 0:
				touchPad = new TouchPad('RIGHT_FULL', 'NONE');
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);
			case 1:
				touchPad = new TouchPad('LEFT_FULL', 'NONE');
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);
			case 2:
				touchPad = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE'));
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);
			case 3:
				var customDPad = new CustomDPad(50, flixel.FlxG.height - 350);
				touchPad = customDPad;
				add(touchPad);
		}
	}

	override public function destroy():Void
	{
		super.destroy();

		if (touchPad != null)
		{
			touchPad = FlxDestroyUtil.destroy(touchPad);
			touchPad = null;
		}
		MobileData.forcedMode = null;
	}
}

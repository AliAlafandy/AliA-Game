package data;

import flixel.FlxSubState;

class GameSubState extends FlxSubState
{
	public static var instance:GameSubState;

	public function new()
	{
		instance = this;
        #if mobile
		controls.isInSubstate = true;
        #end
		super();
	}
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return data.Controls.instance;

    #if mobile
	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String)
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function removeTouchPad()
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}

		if(touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		var isCustomDPad:Bool = false;
	
		switch (MobileData.mode)
		{
			case 0:
				mobileControls = new TouchPad('RIGHT_FULL', 'NONE');
			case 1:
				mobileControls = new TouchPad('LEFT_FULL', 'NONE');
			case 2:
				mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE'));
			case 3:
				mobileControls = new mobile.controls.CustomDPad(50, FlxG.height - 350);
				isCustomDPad = true;
		}

		if (!isCustomDPad && mobileControls != null && mobileControls.instance != null)
		{
			mobileControls.instance = MobileData.setButtonsColors(mobileControls.instance);
		}
	
		mobileControlsCam = new FlxCamera();
		mobileControlsCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);
	
		mobileControls.instance.cameras = [mobileControlsCam];
		mobileControls.instance.visible = false;
		add(mobileControls.instance);
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
		{
			remove(mobileControls.instance);
			mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			mobileControls = null;
		}

		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		if (touchPad != null)
		{
			touchPadCam = new FlxCamera();
			touchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(touchPadCam, defaultDrawTarget);
			touchPad.cameras = [touchPadCam];
		}
	}
    #end

	override function destroy()
	{
        #if mobile
		controls.isInSubstate = false;
		removeTouchPad();
		removeMobileControls();
        #end
		
		super.destroy();
	}

	override function update(elapsed:Float)
	{

		super.update(elapsed);
	}
}

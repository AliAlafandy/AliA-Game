package data.backend;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;

class GameState extends FlxUIState
{
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return data.controls.Controls.instance;
	}

    #if mobile
	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var customDPad:CustomDPad;
	public var customDPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String)
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function addCustomDPad():Void
	{
		customDPad = new CustomDPad(30, FlxG.height - 370);
		customDPad.visible = true;
		add(customDPad);
	}

	public function addCustomDPadCam(defaultDrawTarget:Bool = false):Void
	{
		if (customDPad != null)
		{
			customDPadCam = new FlxCamera();
			customDPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(customDPadCam, defaultDrawTarget);
			customDPad.cameras = [customDPadCam];
		}
	}

	public function removeCustomPad()
	{
		if (customDPad != null)
		{
			remove(customDPad);
			customDPad = FlxDestroyUtil.destroy(customDPad);
		}

		if(customDPadCam != null)
		{
			FlxG.cameras.remove(customDPadCam);
			customDPadCam = FlxDestroyUtil.destroy(customDPadCam);
		}
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
				mobileControls = new CustomDPad(30, FlxG.height - 370);
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
		removeTouchPad();
		removeMobileControls();
		removeCustomPad();
		#end
		super.destroy();
	}


	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.6, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

    public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
        timePassedOnState += elapsed;
		super.update(elapsed);
	}

    public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():GameState {
		return cast (FlxG.state, GameState);
	}
}

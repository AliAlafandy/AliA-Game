package;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import haxe.Timer;

import data.backend.GameState;
import data.backend.GameSubState;

enum abstract InputState(Int)
{
	var IDLE = 0;
	var PRESSED = 1;
	var HELD = 2;
	var RELEASED = 3;
}

class ActionBinding
{
	public var name:String;
	public var keyboardKeys:Array<FlxKey> = [];
	public var gamepadButtons:Array<FlxGamepadInputID> = [];
	#if mobile
	public var mobileButtons:Array<MobileInputID> = [];
	#end
	public var state:InputState = IDLE;
	public var bufferedFrames:Int = 0;
	public var heldTime:Float = 0;
	public var analogAxis:Null<FlxGamepadInputID> = null;
	public var analogThreshold:Float = 0.5;
	public var analogInverted:Bool = false;
	public var contexts:Array<String> = ["gameplay"];
	public var locked:Bool = false;
	public var playerIndex:Int = 0;
	public var lastPressStamp:Float = -1;
	public var doubleTapped:Bool = false;

	public function new(name:String)
	{
		this.name = name;
	}
}

class ComboBinding
{
	public var name:String;
	public var sequence:Array<String>;
	public var windowSeconds:Float;
	public var progress:Int = 0;
	public var lastStepStamp:Float = -1;
	public var onTrigger:Void->Void;

	public function new(name:String, sequence:Array<String>, windowSeconds:Float, onTrigger:Void->Void)
	{
		this.name = name;
		this.sequence = sequence;
		this.windowSeconds = windowSeconds;
		this.onTrigger = onTrigger;
	}
}

typedef RecordedFrame =
{
	frame:Int,
	pressedActions:Array<String>
}

class Controls
{
	public static inline var INPUT_BUFFER_FRAMES:Int = 5;
	public static inline var ANALOG_DEADZONE:Float = 0.18;
	public static inline var DOUBLE_TAP_WINDOW:Float = 0.3;
	public static inline var DEFAULT_CONTEXT:String = "gameplay";

	public var actions:Map<String, ActionBinding> = new Map();
	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	#if mobile
	public var mobileBinds:Map<String, Array<MobileInputID>>;
	#end

	public var controllerMode:Bool = false;
	public var activeGamepad:FlxGamepad;
	public var gamepadsByPlayer:Map<Int, FlxGamepad> = new Map();
	public static var instance:Controls;

	private var contextStack:Array<String> = [DEFAULT_CONTEXT];
	private var combos:Map<String, ComboBinding> = new Map();

	private var isRecording:Bool = false;
	private var isPlaying:Bool = false;
	private var recordBuffer:Array<RecordedFrame> = [];
	private var playbackBuffer:Array<RecordedFrame> = [];
	private var recordFrameIndex:Int = 0;
	private var playbackIndex:Int = 0;
	private var playbackPressedActions:Map<String, Bool> = new Map();

	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var GAME_UP_P(get, never):Bool;
	public var GAME_DOWN_P(get, never):Bool;
	public var GAME_LEFT_P(get, never):Bool;
	public var GAME_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_GAME_UP_P() return justPressed('game_up');
	private function get_GAME_DOWN_P() return justPressed('game_down');
	private function get_GAME_LEFT_P() return justPressed('game_left');
	private function get_GAME_RIGHT_P() return justPressed('game_right');

	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var GAME_UP(get, never):Bool;
	public var GAME_DOWN(get, never):Bool;
	public var GAME_LEFT(get, never):Bool;
	public var GAME_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_GAME_UP() return pressed('game_up');
	private function get_GAME_DOWN() return pressed('game_down');
	private function get_GAME_LEFT() return pressed('game_left');
	private function get_GAME_RIGHT() return pressed('game_right');

	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var GAME_UP_R(get, never):Bool;
	public var GAME_DOWN_R(get, never):Bool;
	public var GAME_LEFT_R(get, never):Bool;
	public var GAME_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_GAME_UP_R() return justReleased('game_up');
	private function get_GAME_DOWN_R() return justReleased('game_down');
	private function get_GAME_LEFT_R() return justReleased('game_left');
	private function get_GAME_RIGHT_R() return justReleased('game_right');

	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');

	#if mobile
	public var isInSubstate:Bool = false;
	public var requestedInstance(get, default):Dynamic;
	public var requestedMobileC(get, default):IMobileControls;
	public var mobileC(get, never):Bool;
	#end

	public function new()
	{
		gamepadBinds = ClientPrefs.gamepadBinds;
		keyboardBinds = ClientPrefs.keyBinds;
		#if mobile mobileBinds = ClientPrefs.mobileBinds; #end

		for (key in keyboardBinds.keys())
			registerAction(key);
	}

	public function registerAction(name:String, ?contexts:Array<String>):ActionBinding
	{
		if (actions.exists(name))
			return actions.get(name);

		var binding = new ActionBinding(name);
		binding.keyboardKeys = keyboardBinds.exists(name) ? keyboardBinds.get(name) : [];
		binding.gamepadButtons = gamepadBinds.exists(name) ? gamepadBinds.get(name) : [];
		#if mobile
		binding.mobileButtons = mobileBinds.exists(name) ? mobileBinds.get(name) : [];
		#end
		if (contexts != null)
			binding.contexts = contexts;

		actions.set(name, binding);
		return binding;
	}

	public function rebindKeyboard(action:String, keys:Array<FlxKey>):Void
	{
		keyboardBinds.set(action, keys);
		if (actions.exists(action))
			actions.get(action).keyboardKeys = keys;
	}

	public function rebindGamepad(action:String, buttons:Array<FlxGamepadInputID>):Void
	{
		gamepadBinds.set(action, buttons);
		if (actions.exists(action))
			actions.get(action).gamepadButtons = buttons;
	}

	public function pushContext(context:String):Void
	{
		contextStack.push(context);
	}

	public function popContext():Void
	{
		if (contextStack.length > 1)
			contextStack.pop();
	}

	public function replaceContext(context:String):Void
	{
		contextStack = [context];
	}

	public function currentContext():String
	{
		return contextStack[contextStack.length - 1];
	}

	public function isActionAllowed(action:String):Bool
	{
		if (!actions.exists(action))
			return true;

		var binding = actions.get(action);
		if (binding.locked)
			return false;

		return binding.contexts.indexOf(currentContext()) != -1;
	}

	public function lockAction(action:String):Void
	{
		if (actions.exists(action))
			actions.get(action).locked = true;
	}

	public function unlockAction(action:String):Void
	{
		if (actions.exists(action))
			actions.get(action).locked = false;
	}

	public function registerCombo(name:String, sequence:Array<String>, windowSeconds:Float, onTrigger:Void->Void):Void
	{
		combos.set(name, new ComboBinding(name, sequence, windowSeconds, onTrigger));
	}

	public function unregisterCombo(name:String):Void
	{
		combos.remove(name);
	}

	public function startRecording():Void
	{
		isRecording = true;
		isPlaying = false;
		recordBuffer = [];
		recordFrameIndex = 0;
	}

	public function stopRecording():Array<RecordedFrame>
	{
		isRecording = false;
		return recordBuffer;
	}

	public function startPlayback(frames:Array<RecordedFrame>):Void
	{
		isPlaying = true;
		isRecording = false;
		playbackBuffer = frames;
		playbackIndex = 0;
		recordFrameIndex = 0;
		playbackPressedActions = new Map();
	}

	public function stopPlayback():Void
	{
		isPlaying = false;
		playbackPressedActions = new Map();
	}

	public function isPlaybackAction(action:String):Bool
	{
		return playbackPressedActions.exists(action) && playbackPressedActions.get(action);
	}

	public function update(elapsed:Float):Void
	{
		if (isPlaying)
			advancePlayback();

		for (binding in actions)
			updateBinding(binding, elapsed);

		updateCombos();

		if (isRecording)
			captureFrame();

		recordFrameIndex++;
	}

	private function captureFrame():Void
	{
		var pressedNow:Array<String> = [];
		for (binding in actions)
			if (binding.state == PRESSED || binding.state == HELD)
				pressedNow.push(binding.name);

		recordBuffer.push({ frame: recordFrameIndex, pressedActions: pressedNow });
	}

	private function advancePlayback():Void
	{
		playbackPressedActions = new Map();

		if (playbackIndex >= playbackBuffer.length)
		{
			stopPlayback();
			return;
		}

		var entry = playbackBuffer[playbackIndex];
		if (entry.frame == recordFrameIndex)
		{
			for (action in entry.pressedActions)
				playbackPressedActions.set(action, true);
			playbackIndex++;
		}
	}

	private function updateBinding(binding:ActionBinding, elapsed:Float):Void
	{
		var allowed = isActionAllowed(binding.name);

		var rawPressed = allowed && rawJustPressed(binding.keyboardKeys, binding.gamepadButtons #if mobile , binding.mobileButtons #end);
		var rawHeld = allowed && rawPressedState(binding.keyboardKeys, binding.gamepadButtons #if mobile , binding.mobileButtons #end);
		var rawReleased = allowed && rawJustReleased(binding.keyboardKeys, binding.gamepadButtons #if mobile , binding.mobileButtons #end);

		if (allowed && binding.analogAxis != null && activeGamepad != null)
		{
			var value = analogValue(binding.analogAxis, binding.analogInverted);
			if (Math.abs(value) >= binding.analogThreshold)
			{
				rawHeld = true;
				controllerMode = true;
			}
		}

		binding.doubleTapped = false;

		if (rawPressed)
		{
			binding.state = PRESSED;
			binding.bufferedFrames = INPUT_BUFFER_FRAMES;
			binding.heldTime = 0;

			var now = Timer.stamp();
			if (binding.lastPressStamp >= 0 && (now - binding.lastPressStamp) <= DOUBLE_TAP_WINDOW)
				binding.doubleTapped = true;

			binding.lastPressStamp = now;
		}
		else if (rawHeld)
		{
			binding.state = HELD;
			binding.heldTime += elapsed;
		}
		else if (rawReleased)
		{
			binding.state = RELEASED;
			binding.heldTime = 0;
		}
		else
		{
			binding.state = IDLE;
		}

		if (binding.bufferedFrames > 0 && !rawPressed)
			binding.bufferedFrames--;
	}

	private function updateCombos():Void
	{
		var now = Timer.stamp();

		for (combo in combos)
		{
			var expectedAction = combo.sequence[combo.progress];

			if (justPressed(expectedAction))
			{
				if (combo.progress > 0 && combo.lastStepStamp >= 0 && (now - combo.lastStepStamp) > combo.windowSeconds)
					combo.progress = 0;

				combo.progress++;
				combo.lastStepStamp = now;

				if (combo.progress >= combo.sequence.length)
				{
					combo.progress = 0;
					if (combo.onTrigger != null)
						combo.onTrigger();
				}
			}
			else if (combo.progress > 0 && combo.lastStepStamp >= 0 && (now - combo.lastStepStamp) > combo.windowSeconds)
			{
				combo.progress = 0;
			}
		}
	}

	public function isDoubleTap(action:String):Bool
	{
		return actions.exists(action) && actions.get(action).doubleTapped;
	}

	public function justPressed(key:String):Bool
	{
		if (isPlaying)
			return isPlaybackAction(key);

		if (!isActionAllowed(key))
			return false;

		var result = FlxG.keys.anyJustPressed(keyboardBinds[key]) == true;
		if (result) controllerMode = false;

		return result || _myGamepadJustPressed(gamepadBinds[key]) == true
			#if mobile || mobileCJustPressed(mobileBinds[key]) == true || touchPadJustPressed(mobileBinds[key]) == true || customDPadJustPressed(mobileBinds[key]) == true #end;
	}

	public function pressed(key:String):Bool
	{
		if (isPlaying)
			return isPlaybackAction(key);

		if (!isActionAllowed(key))
			return false;

		var result = FlxG.keys.anyPressed(keyboardBinds[key]) == true;
		if (result) controllerMode = false;

		return result || _myGamepadPressed(gamepadBinds[key]) == true
			#if mobile || mobileCPressed(mobileBinds[key]) == true || touchPadPressed(mobileBinds[key]) == true || customDPadPressed(mobileBinds[key]) == true #end;
	}

	public function justReleased(key:String):Bool
	{
		if (isPlaying)
			return false;

		if (!isActionAllowed(key))
			return false;

		var result = FlxG.keys.anyJustReleased(keyboardBinds[key]) == true;
		if (result) controllerMode = false;

		return result || _myGamepadJustReleased(gamepadBinds[key]) == true
			#if mobile || mobileCJustReleased(mobileBinds[key]) == true || touchPadJustReleased(mobileBinds[key]) == true || customDPadJustReleased(mobileBinds[key]) == true #end;
	}

	public function isBuffered(action:String):Bool
	{
		return actions.exists(action) && actions.get(action).bufferedFrames > 0;
	}

	public function consumeBuffer(action:String):Bool
	{
		if (!actions.exists(action))
			return false;

		var binding = actions.get(action);
		if (binding.bufferedFrames > 0)
		{
			binding.bufferedFrames = 0;
			return true;
		}
		return false;
	}

	public function heldTimeOf(action:String):Float
	{
		return actions.exists(action) ? actions.get(action).heldTime : 0;
	}

	public function bindAnalog(action:String, axis:FlxGamepadInputID, threshold:Float = 0.5, inverted:Bool = false):Void
	{
		var binding = registerAction(action);
		binding.analogAxis = axis;
		binding.analogThreshold = threshold;
		binding.analogInverted = inverted;
	}

	public function assignGamepadToPlayer(playerIndex:Int, gamepad:FlxGamepad):Void
	{
		gamepadsByPlayer.set(playerIndex, gamepad);
	}

	public function getGamepadForPlayer(playerIndex:Int):FlxGamepad
	{
		return gamepadsByPlayer.exists(playerIndex) ? gamepadsByPlayer.get(playerIndex) : null;
	}

	public function rumble(strength:Float, duration:Float, ?playerIndex:Int = 0):Void
	{
		var gamepad = playerIndex == 0 ? activeGamepad : getGamepadForPlayer(playerIndex);
		if (gamepad == null)
			return;

		gamepad.rumble(strength, strength, Math.round(duration * 1000));
	}

	private function analogValue(axis:FlxGamepadInputID, inverted:Bool):Float
	{
		if (activeGamepad == null)
			return 0;

		var value = activeGamepad.getAxis(axis);
		if (Math.abs(value) < ANALOG_DEADZONE)
			return 0;

		return inverted ? -value : value;
	}

	private function rawJustPressed(keys:Array<FlxKey>, gpButtons:Array<FlxGamepadInputID> #if mobile , mBinds:Array<MobileInputID> #end):Bool
	{
		var result = keys != null && FlxG.keys.anyJustPressed(keys);
		if (result) controllerMode = false;

		return result || _myGamepadJustPressed(gpButtons)
			#if mobile || mobileCJustPressed(mBinds) || touchPadJustPressed(mBinds) || customDPadJustPressed(mBinds) #end;
	}

	private function rawPressedState(keys:Array<FlxKey>, gpButtons:Array<FlxGamepadInputID> #if mobile , mBinds:Array<MobileInputID> #end):Bool
	{
		var result = keys != null && FlxG.keys.anyPressed(keys);
		if (result) controllerMode = false;

		return result || _myGamepadPressed(gpButtons)
			#if mobile || mobileCPressed(mBinds) || touchPadPressed(mBinds) || customDPadPressed(mBinds) #end;
	}

	private function rawJustReleased(keys:Array<FlxKey>, gpButtons:Array<FlxGamepadInputID> #if mobile , mBinds:Array<MobileInputID> #end):Bool
	{
		var result = keys != null && FlxG.keys.anyJustReleased(keys);
		if (result) controllerMode = false;

		return result || _myGamepadJustReleased(gpButtons)
			#if mobile || mobileCJustReleased(mBinds) || touchPadJustReleased(mBinds) || customDPadJustReleased(mBinds) #end;
	}

	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustPressed(key))
				{
					controllerMode = true;
					activeGamepad = FlxG.gamepads.getFirstActiveGamepad();
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyPressed(key))
				{
					controllerMode = true;
					activeGamepad = FlxG.gamepads.getFirstActiveGamepad();
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustReleased(key))
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	#if mobile
	private function customDPadPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedInstance.customDPad != null && requestedInstance.customDPad.anyPressed(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function customDPadJustPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedInstance.customDPad != null && requestedInstance.customDPad.anyJustPressed(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function customDPadJustReleased(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedInstance.customDPad != null && requestedInstance.customDPad.anyJustReleased(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function touchPadPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedInstance.touchPad != null && requestedInstance.touchPad.anyPressed(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function touchPadJustPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedInstance.touchPad != null && requestedInstance.touchPad.anyJustPressed(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function touchPadJustReleased(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedInstance.touchPad != null && requestedInstance.touchPad.anyJustReleased(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function mobileCPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedMobileC != null && requestedMobileC.instance.anyPressed(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function mobileCJustPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedMobileC != null && requestedMobileC.instance.anyJustPressed(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	private function mobileCJustReleased(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedMobileC != null && requestedMobileC.instance.anyJustReleased(keys))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	@:noCompletion
	private function get_requestedInstance():Dynamic
	{
		return isInSubstate ? GameSubState.instance : GameState.getState();
	}

	@:noCompletion
	private function get_requestedMobileC():IMobileControls
	{
		return requestedInstance.mobileControls;
	}

	@:noCompletion
	private function get_mobileC():Bool
	{
		return ClientPrefs.data.controlsAlpha >= 0.1;
	}
	#end
}

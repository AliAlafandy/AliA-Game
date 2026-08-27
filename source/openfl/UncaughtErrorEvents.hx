package openfl.events;

#if !flash
import openfl.events.UncaughtErrorEvent;

/**
	The UncaughtErrorEvents class provides a way to receive uncaught error
	events. An instance of this class dispatches an `uncaughtError` event when
	a runtime error occurs and the error isn't detected and handled in your
	code.

	Use the following properties to access an UncaughtErrorEvents instance:

	* `LoaderInfo.uncaughtErrorEvents`: to detect uncaught errors in code
	defined in the same SWF.
	* `Loader.uncaughtErrorEvents`: to detect uncaught errors in code defined
	in the SWF loaded by a Loader object.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class UncaughtErrorEvents extends EventDispatcher
{
	@:noCompletion private var __enabled:Bool;

	public function new()
	{
		super();
	}

	public override function addEventListener<T>(type:EventType<T>, listener:T->Void, useCapture:Bool = false, priority:Int = 0,
			useWeakReference:Bool = false):Void
	{
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);

		#if !openfl_disable_handle_error
		if (!__enabled && hasEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR))
		{
			__enabled = true;
		}
		#end
	}

	public override function removeEventListener<T>(type:EventType<T>, listener:T->Void, useCapture:Bool = false):Void
	{
		super.removeEventListener(type, listener, useCapture);

		if (__enabled && !hasEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR))
		{
			__enabled = false;
		}
	}
}
#else
typedef UncaughtErrorEvents = flash.events.UncaughtErrorEvents;
#end

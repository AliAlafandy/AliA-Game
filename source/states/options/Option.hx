package states.options;

typedef Keybind = {
	keyboard:String,
	gamepad:String
}

class Option
{
	public var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null;

	public var type(default, set):String = 'bool';

	public var scrollSpeed:Float = 50;
	private var variable:String = null;
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0;
	public var options:Array<String> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;

	public var displayFormat:String = '%v';
	public var description:String = '';
	public var name:String = 'Unknown';

	public var defaultKeys:Keybind = null;
	public var keys:Keybind = null;

	public function new(name:String, description:String = '', variable:String, type:String = 'bool', ?options:Array<String> = null)
	{
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.options = options;

		if (this.type != 'keybind') this.defaultValue = Reflect.getProperty(ClientPrefs.defaultData, variable);

		switch (this.type)
		{
			case 'bool':
				if (defaultValue == null) defaultValue = false;

			case 'int' | 'float':
				if (defaultValue == null) defaultValue = 0;

			case 'percent':
				if (defaultValue == null) defaultValue = 1;
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;

			case 'string':
				if (defaultValue == null) defaultValue = '';
				if (options != null && options.length > 0)
					defaultValue = options[0];

			case 'keybind':
				defaultValue = '';
				defaultKeys = {gamepad: 'NONE', keyboard: 'NONE'};
				keys = {gamepad: 'NONE', keyboard: 'NONE'};
		}

		try
		{
			if (getValue() == null)
			{
				setValue(defaultValue);
			}

			if (this.type == 'string' && options != null)
			{
				var num:Int = options.indexOf(getValue());
				if (num > -1) curOption = num;
			}
		}
		catch (e) {}
	}

	public function change()
	{
		if (onChange != null)
			onChange();
	}

	dynamic public function getValue():Dynamic
	{
		if (type == 'keybind')
			return !Controls.instance.controllerMode ? keys.keyboard : keys.gamepad;

		return Reflect.getProperty(ClientPrefs.data, variable);
	}

	dynamic public function setValue(value:Dynamic):Dynamic
	{
		if (type == 'keybind')
		{
			if (!Controls.instance.controllerMode) keys.keyboard = value;
			else keys.gamepad = value;
			return value;
		}

		if (minValue != null && maxValue != null && (type == 'int' || type == 'float' || type == 'percent'))
		{
			var num:Float = value;
			if (num < (minValue:Float)) value = minValue;
			else if (num > (maxValue:Float)) value = maxValue;
		}

		return Reflect.setProperty(ClientPrefs.data, variable, value);
	}

	private function get_text()
	{
		if (child != null)
			return child.text;
		return null;
	}

	private function set_text(newValue:String = '')
	{
		if (child != null)
			child.text = newValue;
		return null;
	}

	private function set_type(newValue:String):String
	{
		var normalized:String = 'bool';

		switch (newValue.toLowerCase().trim())
		{
			case 'key', 'keybind': normalized = 'keybind';
			case 'int', 'float', 'percent', 'string': normalized = newValue.toLowerCase().trim();
			case 'integer': normalized = 'int';
			case 'str': normalized = 'string';
			case 'fl': normalized = 'float';
		}

		return type = normalized;
	}
}

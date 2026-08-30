package states.editors;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.mouse.FlxMouseButton;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef LevelData =
{
	name:String,
	cols:Int,
	rows:Int,
	tileSize:Int,
	tiles:Array<Array<Int>>
}

enum EditorCommandType
{
	PLACE;
	ERASE;
}

class EditorCommand
{
	public var type:EditorCommandType;
	public var x:Int;
	public var y:Int;
	public var previousValue:Int;
	public var newValue:Int;

	public function new(type:EditorCommandType, x:Int, y:Int, previousValue:Int, newValue:Int)
	{
		this.type = type;
		this.x = x;
		this.y = y;
		this.previousValue = previousValue;
		this.newValue = newValue;
	}
}

class LevelEditorState extends GameState
{
	private static inline var DEFAULT_COLS:Int = 40;
	private static inline var DEFAULT_ROWS:Int = 24;
	private static inline var TILE_SIZE:Int = 32;
	private static inline var PALETTE_SIZE:Int = 6;
	private static inline var CAMERA_SPEED:Float = 480;
	private static inline var ZOOM_STEP:Float = 0.1;
	private static inline var MIN_ZOOM:Float = 0.25;
	private static inline var MAX_ZOOM:Float = 3;

	private var levelName:String = 'untitled';
	private var cols:Int = DEFAULT_COLS;
	private var rows:Int = DEFAULT_ROWS;
	private var tileGrid:Array<Array<Int>>;
	private var tileSprites:FlxTypedGroup<FlxSprite>;
	private var gridOverlay:FlxSprite;
	private var cursor:FlxSprite;
	private var currentTool:Int = 1;
	private var undoStack:Array<EditorCommand> = [];
	private var redoStack:Array<EditorCommand> = [];

	private var hud:FlxText;
	private var toolText:FlxText;
	private var camZoom:Float = 1;

	private static var paletteColors:Array<FlxColor> = [
		FlxColor.TRANSPARENT,
		FlxColor.WHITE,
		FlxColor.LIME,
		FlxColor.CYAN,
		FlxColor.ORANGE,
		FlxColor.MAGENTA
	];

	override public function create():Void
	{
		super.create();

		FlxG.camera.bgColor = 0xFF161616;
		FlxG.mouse.visible = true;

		initGrid();
		buildTileSprites();
		buildGridOverlay();
		buildCursor();
		buildHud();
	}

	private function initGrid():Void
	{
		tileGrid = [];
		for (y in 0...rows)
		{
			var row:Array<Int> = [];
			for (x in 0...cols)
				row.push(0);
			tileGrid.push(row);
		}
	}

	private function buildTileSprites():Void
	{
		tileSprites = new FlxTypedGroup<FlxSprite>();
		add(tileSprites);

		for (y in 0...rows)
		{
			for (x in 0...cols)
			{
				var tile = new FlxSprite(x * TILE_SIZE, y * TILE_SIZE);
				tile.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.TRANSPARENT);
				tile.visible = false;
				tileSprites.add(tile);
			}
		}
	}

	private function buildGridOverlay():Void
	{
		gridOverlay = new FlxSprite(0, 0);
		gridOverlay.makeGraphic(cols * TILE_SIZE, rows * TILE_SIZE, FlxColor.TRANSPARENT, true);

		for (x in 0...cols + 1)
			gridOverlay.pixels.fillRect(new openfl.geom.Rectangle(x * TILE_SIZE, 0, 1, rows * TILE_SIZE), 0x22FFFFFF);

		for (y in 0...rows + 1)
			gridOverlay.pixels.fillRect(new openfl.geom.Rectangle(0, y * TILE_SIZE, cols * TILE_SIZE, 1), 0x22FFFFFF);

		gridOverlay.dirty = true;
		add(gridOverlay);
	}

	private function buildCursor():Void
	{
		cursor = new FlxSprite();
		cursor.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.TRANSPARENT, true);
		cursor.pixels.fillRect(new openfl.geom.Rectangle(0, 0, TILE_SIZE, 2), FlxColor.YELLOW);
		cursor.pixels.fillRect(new openfl.geom.Rectangle(0, TILE_SIZE - 2, TILE_SIZE, 2), FlxColor.YELLOW);
		cursor.pixels.fillRect(new openfl.geom.Rectangle(0, 0, 2, TILE_SIZE), FlxColor.YELLOW);
		cursor.pixels.fillRect(new openfl.geom.Rectangle(TILE_SIZE - 2, 0, 2, TILE_SIZE), FlxColor.YELLOW);
		cursor.dirty = true;
		add(cursor);
	}

	private function buildHud():Void
	{
		hud = new FlxText(4, 4, 400, '', 14);
		hud.scrollFactor.set();
		hud.setFormat(null, 14, FlxColor.WHITE, LEFT);
		add(hud);

		toolText = new FlxText(4, FlxG.height - 28, 600, '', 14);
		toolText.scrollFactor.set();
		toolText.setFormat(null, 14, FlxColor.YELLOW, LEFT);
		add(toolText);

		refreshToolText();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		handleCamera(elapsed);
		handleZoom();
		handleToolSwitch();
		handlePlacement();
		handleUndoRedo();
		handleSaveLoad();
		updateCursorPosition();
		refreshHud();

		if (controls.BACK)
			FlxG.switchState(new EditorState());
	}

	private function handleCamera(elapsed:Float):Void
	{
		var moveX:Float = 0;
		var moveY:Float = 0;

		if (controls.GAME_LEFT) moveX -= 1;
		if (controls.GAME_RIGHT) moveX += 1;
		if (controls.GAME_UP) moveY -= 1;
		if (controls.GAME_DOWN) moveY += 1;

		if (moveX != 0 || moveY != 0)
		{
			var length = Math.sqrt(moveX * moveX + moveY * moveY);
			moveX /= length;
			moveY /= length;

			FlxG.camera.scroll.x += moveX * CAMERA_SPEED * elapsed / camZoom;
			FlxG.camera.scroll.y += moveY * CAMERA_SPEED * elapsed / camZoom;
		}

		if (FlxG.mouse.pressed && FlxG.mouse.justPressedMiddle == false && FlxG.mouse.pressedMiddle)
		{
			FlxG.camera.scroll.x -= FlxG.mouse.deltaScreenX / camZoom;
			FlxG.camera.scroll.y -= FlxG.mouse.deltaScreenY / camZoom;
		}
	}

	private function handleZoom():Void
	{
		if (FlxG.mouse.wheel != 0)
		{
			camZoom = FlxMath.bound(camZoom + (FlxG.mouse.wheel * ZOOM_STEP), MIN_ZOOM, MAX_ZOOM);
			FlxG.camera.zoom = camZoom;
		}
	}

	private function handleToolSwitch():Void
	{
		for (i in 0...PALETTE_SIZE)
		{
			if (FlxG.keys.justPressed.fromString(Std.string(i)))
				currentTool = i;
		}

		refreshToolText();
	}

	private function handlePlacement():Void
	{
		var gridPos = screenToGrid(FlxG.mouse.x, FlxG.mouse.y);
		if (gridPos == null)
			return;

		if (FlxG.mouse.pressedLeft)
			placeTile(gridPos.x, gridPos.y, currentTool);
		else if (FlxG.mouse.pressedRight)
			placeTile(gridPos.x, gridPos.y, 0);
	}

	private function placeTile(x:Int, y:Int, value:Int):Void
	{
		if (x < 0 || y < 0 || x >= cols || y >= rows)
			return;

		var previous = tileGrid[y][x];
		if (previous == value)
			return;

		tileGrid[y][x] = value;
		applyTileVisual(x, y, value);

		var command = new EditorCommand(value == 0 ? ERASE : PLACE, x, y, previous, value);
		undoStack.push(command);
		redoStack = [];
	}

	private function applyTileVisual(x:Int, y:Int, value:Int):Void
	{
		var index = (y * cols) + x;
		var sprite = tileSprites.members[index];
		if (sprite == null)
			return;

		if (value == 0)
		{
			sprite.visible = false;
		}
		else
		{
			sprite.visible = true;
			sprite.makeGraphic(TILE_SIZE, TILE_SIZE, paletteColors[value % paletteColors.length]);
		}
	}

	private function handleUndoRedo():Void
	{
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
			undo();
		else if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y)
			redo();
	}

	private function undo():Void
	{
		if (undoStack.length == 0)
			return;

		var command = undoStack.pop();
		tileGrid[command.y][command.x] = command.previousValue;
		applyTileVisual(command.x, command.y, command.previousValue);
		redoStack.push(command);
	}

	private function redo():Void
	{
		if (redoStack.length == 0)
			return;

		var command = redoStack.pop();
		tileGrid[command.y][command.x] = command.newValue;
		applyTileVisual(command.x, command.y, command.newValue);
		undoStack.push(command);
	}

	private function handleSaveLoad():Void
	{
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveLevel();
		else if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.L)
			loadLevel();
	}

	private function saveLevel():Void
	{
		#if sys
		var data:LevelData = {
			name: levelName,
			cols: cols,
			rows: rows,
			tileSize: TILE_SIZE,
			tiles: tileGrid
		};

		var directory = 'levels';
		if (!FileSystem.exists(directory))
			FileSystem.createDirectory(directory);

		File.saveContent('$directory/$levelName.json', haxe.Json.stringify(data));
		#end
	}

	private function loadLevel():Void
	{
		#if sys
		var path = 'levels/$levelName.bin';
		if (!FileSystem.exists(path))
			return;

		var content = File.getContent(path);
		var data:LevelData = haxe.Json.parse(content);

		cols = data.cols;
		rows = data.rows;
		tileGrid = data.tiles;

		tileSprites.clear();
		buildTileSprites();

		for (y in 0...rows)
			for (x in 0...cols)
				applyTileVisual(x, y, tileGrid[y][x]);
		#end
	}

	private function screenToGrid(screenX:Float, screenY:Float):FlxPoint
	{
		var worldX = FlxG.camera.scroll.x + (screenX / camZoom);
		var worldY = FlxG.camera.scroll.y + (screenY / camZoom);

		var gx = Math.floor(worldX / TILE_SIZE);
		var gy = Math.floor(worldY / TILE_SIZE);

		if (gx < 0 || gy < 0 || gx >= cols || gy >= rows)
			return null;

		return FlxPoint.get(gx, gy);
	}

	private function updateCursorPosition():Void
	{
		var gridPos = screenToGrid(FlxG.mouse.x, FlxG.mouse.y);
		if (gridPos == null)
		{
			cursor.visible = false;
			return;
		}

		cursor.visible = true;
		cursor.x = gridPos.x * TILE_SIZE;
		cursor.y = gridPos.y * TILE_SIZE;
	}

	private function refreshHud():Void
	{
		hud.text = 'LEVEL: $levelName  ${cols}x$rows  ZOOM: ${Math.round(camZoom * 100)}%';
	}

	private function refreshToolText():Void
	{
		toolText.text = 'TOOL: $currentTool   CTRL+S Save   CTRL+L Load   CTRL+Z Undo   CTRL+Y Redo   BACK Exit';
	}
}

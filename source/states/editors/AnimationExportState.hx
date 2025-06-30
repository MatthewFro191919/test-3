package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.PNGEncoderOptions;
import openfl.utils.ByteArray;
import lime.utils.Assets;
import backend.Paths;

class AnimationExportState extends FlxState
{
    var characterList:Array<String> = [];
    var outputPath = "exported_frames/";

    override public function create():Void
    {
        super.create();

        var instructions = new FlxText(0, 20, FlxG.width, "Click a character to export from metadata.
Press ESC or click Exit to return.", 16);
        instructions.setFormat(null, 16, FlxColor.WHITE, "center");
        add(instructions);

        var exitBtn = new FlxButton(FlxG.width - 100, FlxG.height - 40, "Exit", function() FlxG.switchState(new MasterEditorMenu()));
        add(exitBtn);

        var baseDir = "mods/images/characters/";
        if (FileSystem.exists(baseDir))
        {
            for (entry in FileSystem.readDirectory(baseDir))
            {
                var full = baseDir + entry;
                if (FileSystem.isDirectory(full) && FileSystem.exists(full + "/Animation.json"))
                {
                    characterList.push(entry);
                }
            }
        }

        var y:Float = 60;
        for (charName in characterList)
        {
            var name = charName;
            var btn = new FlxButton(50, y, name);
            btn.color = FlxColor.GRAY;
            btn.label.color = FlxColor.WHITE;
            btn.onUp.callback = function() exportCharacter(name);
            add(btn);
            y += 40;
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ESCAPE)
        {
            FlxG.switchState(new MasterEditorMenu());
        }
    }

    function exportCharacter(charName:String):Void
    {
        var basePath = "mods/images/characters/" + charName + "/";
        var jsonPathAnim = basePath + "Animation.json";
        var jsonPathMap = basePath + "spritemap1.json";
        var imagePath = basePath + "spritemap1.png";

        if (!FileSystem.exists(jsonPathAnim) || !FileSystem.exists(jsonPathMap) || !FileSystem.exists(imagePath))
        {
            trace("Missing files for character: " + charName);
            return;
        }

        var image = BitmapData.fromFile(imagePath);
        var mapData:Dynamic = Json.parse(File.getContent(jsonPathMap));
        var animData:Dynamic = Json.parse(File.getContent(jsonPathAnim));

        if (!Reflect.hasField(mapData, "frames") || !Reflect.hasField(animData, "symbols"))
        {
            trace("Missing keys in metadata for: " + charName);
            return;
        }

        var symbols:Array<Dynamic> = cast animData.symbols;
        for (symbol in symbols)
        {
            var symbolName:String = symbol.symbolName;
            var layer = symbol.layers[0];
            var frameCount = layer.frames.length;

            for (i in 0...frameCount)
            {
                var frameName:String = layer.frames[i].ref;
                var frameInfo = Reflect.field(mapData.frames, frameName);
                if (frameInfo == null) continue;

                var x = frameInfo.frame.x;
                var y = frameInfo.frame.y;
                var w = frameInfo.frame.w;
                var h = frameInfo.frame.h;

                var frameBmp = new BitmapData(w, h, true, 0x00000000);
                frameBmp.copyPixels(image, new Rectangle(x, y, w, h), new Point(0, 0));

                var exportDir = outputPath + charName + "/" + symbolName + "/";
                if (!FileSystem.exists(exportDir)) FileSystem.createDirectory(exportDir);
                var filePath = exportDir + "frame" + i + ".png";
                var png:ByteArray = frameBmp.encode(frameBmp.rect, new PNGEncoderOptions());
                File.saveBytes(filePath, png);
                trace("✅ Exported: " + filePath);
            }
        }
    }
}

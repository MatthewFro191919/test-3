
package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.input.keyboard.FlxKey;
import flixel.FlxSubState;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.PNGEncoderOptions;
import openfl.utils.ByteArray;

class AnimationExportState extends FlxState
{
    var jsonPathAnim = "mods/images/characters/Animation.json";
    var jsonPathMap = "mods/images/characters/spritemap1.json";
    var imagePath = "mods/images/characters/spritemap1.png";
    var outputPath = "exported_frames/atlas_character/";

    override public function create():Void
    {
        super.create();

        var instructions = new FlxText(0, 20, FlxG.width, "Press ESC or click to exit
Using Animation.json and spritemap1.json", 16);
        instructions.setFormat(null, 16, FlxColor.WHITE, "center");
        add(instructions);

        var exitBtn = new FlxButton(20, FlxG.height - 40, "Exit", function() FlxG.switchState(new MasterEditorMenu()));
        add(exitBtn);

        exportFromAtlas();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ESCAPE)
        {
            FlxG.switchState(new MasterEditorMenu());
        }
    }

    function exportFromAtlas():Void
    {
        if (!FileSystem.exists(jsonPathMap) || !FileSystem.exists(jsonPathAnim) || !FileSystem.exists(imagePath))
        {
            trace("Required files not found.");
            return;
        }

        var image = BitmapData.load(imagePath);
        var mapData:Dynamic = Json.parse(File.getContent(jsonPathMap));
        var animData:Dynamic = Json.parse(File.getContent(jsonPathAnim));

        if (!Reflect.hasField(mapData, "frames") || !Reflect.hasField(animData, "symbols"))
        {
            trace("Missing frames or symbols data.");
            return;
        }

        for (symbol in animData.symbols)
        {
            var symbolName:String = symbol.symbolName;
            var layer = symbol.layers[0];
            var frameCount = layer.frames.length;

            for (i in 0...frameCount)
            {
                var frameName:String = layer.frames[i].ref;
                var frameInfo = mapData.frames[frameName];
                if (frameInfo == null) continue;

                var x = frameInfo.frame.x;
                var y = frameInfo.frame.y;
                var w = frameInfo.frame.w;
                var h = frameInfo.frame.h;

                var frameBmp = new BitmapData(w, h, true, 0x00000000);
                frameBmp.copyPixels(image, new Rectangle(x, y, w, h), new Point(0, 0));

                var exportDir = outputPath + symbolName + "/";
                if (!FileSystem.exists(exportDir)) FileSystem.createDirectory(exportDir);
                var filePath = exportDir + "frame" + i + ".png";
                var png:ByteArray = frameBmp.encode(frameBmp.rect, new PNGEncoderOptions());
                File.saveBytes(filePath, png);
                trace("Exported: " + filePath);
            }
        }
    }
}

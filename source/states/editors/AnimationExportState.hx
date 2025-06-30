
package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Matrix;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;

class AnimationExportState extends FlxState
{
    override public function create():Void
    {
        super.create();

        var label = new FlxText(0, 20, FlxG.width, "Export Frames (1=BF, 2=DAD, 3=Both)", 20);
        label.setFormat(null, 20, FlxColor.WHITE, "center");
        add(label);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ONE)
            exportChar("boyfriend");
        if (FlxG.keys.justPressed.TWO)
            exportChar("dad");
        if (FlxG.keys.justPressed.THREE)
        {
            exportChar("boyfriend");
            exportChar("dad");
        }
    }

    function exportChar(charName:String):Void
    {
        var char = (charName == "boyfriend") ? PlayState.instance.boyfriend : PlayState.instance.dad;
        if (char == null)
        {
            trace('Character not found: ' + charName);
            return;
        }

        var label = char.curCharacter;
        var basePath = "mods/images/characters/exported_frames/";
        if (!FileSystem.exists(basePath))
            FileSystem.createDirectory(basePath);

        for (anim in char.animation._animations.keys())
        {
            var animObj = char.animation._animations.get(anim);
            var totalFrames = animObj.numFrames;

            for (i in 0...totalFrames)
            {
                char.playAnim(anim, true);
                char.animation.curAnim.curFrame = i;

                // Force redraw
                char.updateHitbox();
                FlxG.game.stage.invalidate();

                // Wait a frame (simulate render delay)
                FlxG.camera.drawFX();
                FlxG.camera.draw();

                var bmp:BitmapData = new BitmapData(Math.ceil(char.frameWidth), Math.ceil(char.frameHeight), true, 0x00000000);
                var mtx = new Matrix();
                mtx.translate(-char.offset.x, -char.offset.y);
                bmp.draw(char, mtx);

                var exportPath = basePath + label + "/" + anim + "/";
                if (!FileSystem.exists(exportPath))
                    FileSystem.createDirectory(exportPath);

                var filePath = exportPath + "frame" + i + ".png";

                try {
                    var png:ByteArray = bmp.encode(bmp.rect, new PNGEncoderOptions());
                    File.saveBytes(filePath, png);
                    trace("✅ Saved " + filePath);
                }
                catch (e)
                {
                    trace("⚠️ Failed to export frame " + i + " of " + anim + " for " + label + ": " + e.message);
                }
            }
        }
    }
}

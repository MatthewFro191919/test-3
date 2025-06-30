
package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Matrix;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;
import states.editors.CharacterEditorState;
import objects.Character;

class AnimationExportState extends FlxState
{
    var characterList:Array<String> = [];

    override public function create():Void
    {
        super.create();

        var instructions = new FlxText(0, 20, FlxG.width, "Select a character to export", 20);
        instructions.setFormat(null, 20, FlxColor.WHITE, "center");
        add(instructions);

        characterList = [];
        var charDir:String = "mods/characters/";
        if (FileSystem.exists(charDir))
        {
            var files:Array<String> = FileSystem.readDirectory(charDir);
            for (file in files)
            {
                if (file.endsWith(".json") && !file.contains("-dead"))
                {
                    var jsonFile = file.split("/").pop();
                    var charName = jsonFile.split(".")[0];
                    characterList.push(charName);
                }
            }
        }

        var yPos:Float = 60;
        for (charName in characterList)
        {
            var name = charName;
            var btn = new FlxButton(50, yPos, name);
            btn.color = FlxColor.GRAY;
            btn.label.color = FlxColor.WHITE;
            btn.onUp.callback = function() exportCharacter(name);
            add(btn);
            yPos += 40;
        }
    }

    function exportCharacter(charName:String):Void
    {
        var tempChar:Character = new Character(0, 0, charName);
        if (tempChar == null)
        {
            trace("❌ Failed to load character: " + charName);
            return;
        }

        var basePath:String = "exported_frames/";
        if (!FileSystem.exists(basePath))
            FileSystem.createDirectory(basePath);

        var animNames:Array<String> = cast tempChar.animation.getNameList();
        for (anim in animNames)
        {
            var animObj = tempChar.animation.getByName(anim);
            var totalFrames:Int = animObj.numFrames;

            for (i in 0...totalFrames)
            {
                tempChar.playAnim(anim, true);
                tempChar.animation.curAnim.curFrame = i;
                tempChar.updateHitbox();

                var bmp:BitmapData = new BitmapData(Math.ceil(tempChar.width), Math.ceil(tempChar.height), true, 0x00000000);
                var mtx:Matrix = new Matrix();
                mtx.translate(-tempChar.offset.x, -tempChar.offset.y);

                try {
                    bmp.draw(tempChar.pixels, mtx);
                } catch (e:Dynamic) {
                    trace("⚠️ draw() failed for frame " + i + " of " + anim + ": " + e);
                    continue;
                }

                var exportPath:String = basePath + charName + "/" + anim + "/";
                if (!FileSystem.exists(exportPath))
                    FileSystem.createDirectory(exportPath);

                var filePath:String = exportPath + "frame" + i + ".png";

                try {
                    var png:ByteArray = bmp.encode(bmp.rect, new PNGEncoderOptions());
                    File.saveBytes(filePath, png);
                    trace("✅ Saved " + filePath);
                }
                catch (e:Dynamic) {
                    trace("⚠️ Failed to export frame " + i + " of " + anim + " for " + charName + ": " + e);
                }
            }
        }
    }
}

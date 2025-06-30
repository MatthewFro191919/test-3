package states.editors;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Matrix;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;

import backend.Paths;
import states.editors.CharacterEditorState;

class AnimationExportState extends FlxState
{
    var characterList:Array<String> = [];
    var buttonGroup:FlxGroup;
    var instructions:FlxText;

    override public function create():Void
    {
        super.create();

        instructions = new FlxText(0, 20, FlxG.width, "Select a character to export", 20);
        instructions.setFormat(null, 20, FlxColor.WHITE, "center");
        add(instructions);

        buttonGroup = new FlxGroup();
        add(buttonGroup);

        characterList = Paths.listFiles("mods/", true, [".json"], function(path) return path.contains("characters") && !path.contains("dead"));

        var yPos:Float = 60;
        for (filePath in characterList)
        {
            var name = filePath.split("/").pop().replace(".json", "");
            var btn = new FlxButton(50, yPos, name, function() exportCharacter(name));
            btn.color = FlxColor.GRAY;
            btn.label.color = FlxColor.WHITE;
            buttonGroup.add(btn);
            yPos += 40;
        }
    }

    function exportCharacter(charName:String):Void
    {
        var tempChar = new CharacterEditorState().loadCharFromFile(charName);
        if (tempChar == null)
        {
            trace("❌ Failed to load character: " + charName);
            return;
        }

        var label = charName;
        var basePath = "exported_frames/";
        if (!FileSystem.exists(basePath))
            FileSystem.createDirectory(basePath);

        for (anim in tempChar.animation.getNameList())
        {
            var totalFrames = tempChar.animation.getByName(anim).numFrames;

            for (i in 0...totalFrames)
            {
                tempChar.playAnim(anim, true);
                tempChar.animation.curAnim.curFrame = i;

                tempChar.updateHitbox();

                var bmp:BitmapData = new BitmapData(Math.ceil(tempChar.width), Math.ceil(tempChar.height), true, 0x00000000);
                var mtx = new Matrix();
                mtx.translate(-tempChar.offset.x, -tempChar.offset.y);

                try {
                    bmp.draw(tempChar.pixels, mtx);
                } catch (e) {
                    trace("⚠️ draw() failed: " + e.message);
                    continue;
                }

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

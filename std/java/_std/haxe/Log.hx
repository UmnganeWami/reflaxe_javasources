package haxe;

import haxe.PosInfos;

class Log {
	public static function formatOutput(v:Dynamic, infos:PosInfos):String {
		var str = Std.string(v);
		var pstr = infos.fileName + ":" + infos.lineNumber;
		if (infos.customParams != null)
			for (v in infos.customParams)
				str += ", " + Std.string(v);
		return pstr + ": " + str;
	}

	public static function trace(v:Dynamic, infos:PosInfos):Void {
		// var arranged:String = infos.className + ":" + infos.lineNumber + ":"
		var arranged = formatOutput(v, infos);
		untyped __javasrc__("System.out.println(arranged)");
	}
}

package javasrccompiler.components;

#if (macro || java_runtime)
import haxe.macro.Type;
import reflaxe.BaseCompiler;
import reflaxe.data.EnumOptionData;
import reflaxe.helpers.OperatorHelper;

/**
 * The component responsible for compiling Haxe enums into Java source.
 */
class JavaEnum extends JavaBase {
	public function getRealPackage(enumType:EnumType, includeClassName:Bool = true):String {
		var className = enumType.name; // classType.pack.join(".");
		var classPath = StringTools.replace(enumType.pack.join(".").toLowerCase(), "_", "");
		var needsDot = classPath != "";
		return JavaCompiler.DEFAULT_PACKAGE
			+ (needsDot || includeClassName ? "." : "")
			+ classPath
			+ (includeClassName ? ((needsDot ? "." : "") + className) : "");
	}

	/**
	 * Implementation of `JavaCompiler.compileEnumImpl`.
	 */
	public function compile(enumType:EnumType, options:Array<EnumOptionData>):Null<String> {
		var enumExport = "package " + getRealPackage(enumType, false) + ";\n";
		enumExport += "enum " + enumType.name + " {\n";
		var i = 0;
		for (option in options) {
			var isLast = i == options.length;
			enumExport += option.name + (isLast ? "" : ",") + "\n";
			i++;
		}
		return return enumExport + "}";
	}
}
#end

package javasrccompiler;

#if (macro || java_runtime)
import reflaxe.ReflectCompiler;

class JavaCompilerInit {
	public static function Start() {
		#if !eval
		Sys.println('JavaCompilerInit.Start can only be called from a macro context.');
		return;
		#end

		#if (haxe_ver < "4.3.0")
		Sys.println('Reflaxe/javasrc requires Haxe version 4.3.0 or greater.');
		return;
		#end

		ReflectCompiler.AddCompiler(new JavaCompiler(), {
			fileOutputExtension: '.java',
			outputDirDefineName: 'javasrc-output',
			fileOutputType: FilePerClass,
			reservedVarNames: reservedNames(),
			targetCodeInjectionName: '__javasrc__',
			smartDCE: false,
			trackUsedTypes: true,
			deleteOldOutput: true
		});
	}

	public static function reservedNames() {
		return ["__THISISTHEVARIBLEWEAREGETTING", "int", "float", "__MYRUNNABLE"];
	}
}
#end

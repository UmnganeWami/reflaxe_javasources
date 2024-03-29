package javasrccompiler.components;

#if (macro || java_runtime)
import haxe.macro.Type;
import haxe.display.Display.MetadataTarget;
import reflaxe.BaseCompiler;
import reflaxe.data.ClassVarData;
import reflaxe.data.ClassFuncData;
import reflaxe.input.ClassHierarchyTracker;

using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;

/**
 * The component responsible for compiling Haxe classes into Java source code.
 */
class JavaClass extends JavaBase {
	/**
	 * The list of variables compiled into Java accumulated while compiling the class.
	 */
	var variables:Array<String> = [];

	/**
	 * The list of functions compiled into Java accumulated while compiling the class.
	 */
	var functions:Array<String> = [];

	/**
	 * Java name of the class currently being compiled.
	 */
	var javaClassName:String = "";

	/**
	 * Java package of the class currently being compiled.
	 */
	var javaPackageName:String = "";

	public function getRealPackage(classType:ClassType, includeClassName:Bool = true):String {
		var className = compiler.compileClassName(classType); // classType.pack.join(".");
		var classPath = StringTools.replace(classType.pack.join(".").toLowerCase(), "_", "");
		var needsDot = classPath != "";
		return JavaCompiler.DEFAULT_PACKAGE
			+ (needsDot || includeClassName ? "." : "")
			+ classPath
			+ (includeClassName ? ((needsDot ? "." : "") + className) : "");
	}

	/**
		Called at the start of a class' compilation to reset the variables.
	**/
	function init(classType:ClassType) {
		variables = [];
		functions = [];

		final className = classType.name;
		javaClassName = compiler.compileClassName(classType);
		javaPackageName = compiler.typeComp.getPackageName(classType);
	}

	/**
		Implementation of `JavaCompiler.compileClassImpl`.
	**/
	public function compile(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>):Null<String> {
		// TODO: Set the output folder for the file this will be generated for
		// compiler.setOutputFileDir("src");

		// Stores all the variables and fields to put together later.
		init(classType);

		var declaration = "package " + getRealPackage(classType, false) + ";\n";

		declaration += JavaCompiler.DefaultImports;

		// Compile metadata (built-in Reflaxe function)
		final clsMeta = compiler.compileMetadata(classType.meta, MetadataTarget.Class) ?? "";
		declaration += clsMeta;

		// Basic declaration
		declaration += "public final class " + javaClassName;
		if (classType.superClass != null) {
			declaration += ": " + compiler.compileClassName(classType.superClass.t.get());
		}

		// Variables
		for (v in varFields) {
			compileVariable(v);
		}

		// Functions
		for (f in funcFields) {
			compileFunction(f, classType);
		}

		// if there are no instance variables or functions,
		// we don't need to generate a class
		if (variables.length <= 0 && functions.length <= 0) {
			return null;
		}

		// Let's put everything together to make the C# class!
		return {
			final content = [];

			if (variables.length > 0) {
				content.push(variables.map(v -> v.tab()).join("\n\n"));
			}

			if (functions.length > 0) {
				content.push(functions.map(v -> v.tab()).join("\n\n"));
			}

			var result = declaration + " {\n";
			result += content.join("\n\n");
			result += "\n}\n";

			// result = compiler.wrapPackage(javaPackageName, result);
			result = compiler.cleanWhiteSpaces(result);

			result;
		}
	}

	/**
		Compiles the class variable.
	**/
	function compileVariable(v:ClassVarData) {
		final field = v.field;

		// Compile name
		final varName = compiler.compileVarName(field.name, null, field);

		// Compile type
		final varType = compiler.compileType(field.type, field.pos);

		// Compile expression
		final e = field.expr();
		final csExpr = if (e != null) {
			compiler.compileClassVarExpr(e);
		} else {
			"";
		}

		// Compile metadata
		final meta = compiler.compileMetadata(field.meta, MetadataTarget.ClassField) ?? "";

		// Put it all together to make C# variable
		final decl = meta
			+ (v.isStatic ? "static " : "")
			+ (varType ?? "var")
			+ " "
			+ varName
			+ (csExpr.length == 0 ? "" : (" = " + csExpr))
			+ ";";
		variables.push(decl);
	}

	/**
		Compiles the class function.
	**/
	function compileFunction(f:ClassFuncData, classType:ClassType) {
		final field:ClassField = f.field;
		if (field.isExtern) {
			return;
		}

		final isConstructor:Bool = (field.name == "new");

		// Compile name
		final name:String = isConstructor ? javaClassName : compiler.compileVarName(field.name);

		// Compile metadata
		final meta:String = compiler.compileMetadata(field.meta, MetadataTarget.ClassField) ?? "";

		// If a dynamic function, we want to compile as function variable.
		if (f.kind == MethDynamic) {
			// `field.expr()` gives an expression of as TypedExprDef.TFunction,
			// so we don't need to do anything special to compile it as a lambda.
			final e = field.expr();
			if (e != null) {
				final callable = compiler.compileClassVarExpr(e);
				final decl = meta + (f.isStatic ? "static " : "") + "void " + name + " = " + callable;
				variables.push(decl);
			}
		} else {
			// Compile arguments
			final arguments = f.args.map(a -> {
				if (a.isFrontOptional())
					compiler.compileFunctionArgument(a.type, a.name, field.pos, false, null);
				else
					compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr);
			});

			// Compile return type
			final ret = isConstructor ? null : compiler.compileType(f.ret, field.pos);

			// Compile expression - Use `data.expr` instead of `field.expr()`
			// since it provides the contents of the function.
			final csExpr = {
				if (f.expr != null) {
					final code = compiler.compileClassFuncExpr(f.expr);
					"{\n" + code.tab() + "\n}";
				} else {
					";";
				}
			}

			// Put it all together to make the C# function
			final props = compileFunctionProperties(f, classType).join(" ");
			final func = meta + props + " " + (!isConstructor ? ret + " " : "") + name + "(" + arguments.join(", ") + ") " + csExpr;
			functions.push(func);

			// Resolve variations
			final variations = f.findAllArgumentVariations(true, true);
			if (variations != null && variations.length > 1) {
				for (v in variations) {
					if (v.args.length < f.args.length) {
						// Compile arguments
						final vArguments = v.args.map(a -> compiler.compileFunctionArgument(a.type, a.name, field.pos, a.opt, a.expr));

						// Compile internal call arguments
						final vCallArgs = f.args.map(a -> {
							var def = true;
							for (arg in v.args) {
								if (arg.name == a.name) {
									def = false;
									break;
								}
							}
							def
							&& a.expr != null ? compiler.compileExpression(a.expr) : a.name;
						});

						// Compile expression
						final csExpr = {
							if (f.expr != null) {
								final code = (ret != "void" ? "return " : "") + name + "(" + vCallArgs.join(", ") + ");";
								"{\n" + code.tab() + "\n}";
							} else {
								";";
							}
						}

						// Put it all together to make the Java function
						final props = compileFunctionProperties(f, classType).join(" ");
						final func = meta + props + " " + ret + " " + name + "(" + vArguments.join(", ") + ") " + csExpr;
						functions.push(func);
					}
				}
			}
		}
	}

	/**
		Returns a list of all the Java properties to be appended to a Java function.
	**/
	function compileFunctionProperties(f:ClassFuncData, classType:ClassType):Array<String> {
		final field = f.field;

		final props = ["public"]; // Always public

		if (f.isStatic) {
			props.push("static");
		} else {
			// Add virtual if @:virtual meta OR has child override
			if (field.hasMeta(":virtual") || ClassHierarchyTracker.funcHasChildOverride(classType, field, false)) {
				props.push("virtual");
			} else if (field.hasMeta(":override") || ClassHierarchyTracker.getParentOverrideChain(f).length > 0) {
				props.push("override");
			}
		}

		return props;
	}
}
#end

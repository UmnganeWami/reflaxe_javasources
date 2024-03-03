package javasrccompiler.components;

import haxe.macro.TypeTools;
#if (macro || java_runtime)
import reflaxe.helpers.Context; // same as haxe.macro.Context
import haxe.macro.Expr;
import haxe.macro.Type;

using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;

/**
	The component responsible for compiling Haxe types into Java source.
**/
class JavaType extends JavaBase {
	public function getRealPackage(classType:AbstractType, includeClassName:Bool = true):String {
		var className = classType.name; // classType.pack.join(".");
		var classPath = StringTools.replace(classType.pack.join(".").toLowerCase(), "_", "");
		var needsDot = classPath != "";
		return JavaCompiler.DEFAULT_PACKAGE
			+ (needsDot || includeClassName ? "." : "")
			+ classPath
			+ (includeClassName ? ((needsDot ? "." : "") + className) : "");
	}

	/**
	 * Generates the Java type code given the Haxe `haxe.macro.Type`.
	 */
	public function compile(type:Type, pos:Position):Null<String> {
		return switch (type) {
			case TMono(refType): {
					final maybeType = refType.get();
					if (maybeType != null) {
						compile(maybeType, pos);
					} else {
						null;
					}
				}
			case TEnum(enumRef, params): {
					withTypeParams(compileEnumName(enumRef.get()), params, pos);
				}
			case TInst(clsRef, params): {
					withTypeParams(compileClassName(clsRef.get()), params, pos);
				}
			case TType(_, _): {
					compile(Context.follow(type), pos);
				}
			case TFun(args, ref): {
					// TODO
					null;
				}
			case TAnonymous(anonRef): {
					// TODO
					// For now, we simply use `Object` type. Might change later
					// var anonType = anonRef.get();
					'HashMap<String, Object>';
				}
			case TDynamic(maybeType): {
					if (maybeType == null)
						return 'Object';
					trace('TDynamic(${maybeType})');
					null;
				}

			case TLazy(callback): {
					compile(callback(), pos);
				}
			case TAbstract(absRef, params): {
					var absType = absRef.get();
					var primitiveType = checkPrimitiveType(absType, params);

					if (primitiveType != null) {
						primitiveType;
					} else if (absType.name == 'Null') {
						if (params != null && params.length > 0 && isValueType(params[0])) {
							nonNullableToNullable(compile(params[0], pos));
						} else {
							compile(params[0], pos);
						}
					} else {
						compile(Context.followWithAbstracts(type), pos);
					}
				}
		}
	}

	/**
	 * If the provided `TAbstract` info should generate a primitive type,
	 * this function compiles and returns the type name.
	 * @returns `null` if the abstract is not a primitive.
	 */
	function checkPrimitiveType(abs:AbstractType, params:Array<Type>):Null<String> {
		var earlyRet = switch (abs.name) {
			case "Class": "Class";
			case _: null;
		}

		if (earlyRet != null) {
			return earlyRet;
		}

		if (params.length > 0 || abs.pack.length > 0) {
			return null;
		}
		return switch (abs.name) {
			case 'Void': 'void';
			case 'Int': 'int';
			case 'UInt': 'uint';
			case 'Float': 'double';
			case 'Bool': 'Boolean';
			case 'string': "String";
			case _: null;
		}
	}

	function nonNullableToNullable(name:String) {
		return switch (name) {
			case "int":
				"Integer";
			case _:
				name;
		}
	}

	/**
	 * A **value type** is either a primitive type or a (C#) struct type.
	 	 * @returns `true` if the given type is a **value type**.
	 */
	function isValueType(type:Type):Bool {
		return switch type {
			case TInst(t, params):
				// TODO classes with @:structAccess
				false;
			case TAbstract(absRef, params):
				final absType = absRef.get();
				final primitiveType = checkPrimitiveType(absType, params);
				if (primitiveType != null) {
					true;
				} else {
					isValueType(Context.followWithAbstracts(type));
				}
			case _:
				false;
		}
	}

	/**
	 * Append type parameters to the compiled type.
	 */
	function withTypeParams(name:String, params:Array<Type>, pos:Position):String {
		switch (name) {
			case "Array":
				var types = params.map(p -> compile(p, pos));
				var lastType = types[types.length - 1];
				types.remove(lastType);
				var arraysDefs = "[]";
				for (i in 0...types.length) {
					arraysDefs += "[]";
				}
				return lastType + arraysDefs;
		}
		return name + (params.length > 0 ? '<${params.map(p -> compile(p, pos)).join(', ')}>' : '');
	}

	/**
	 * Generate Java output for `ModuleType` used in an expression
	 * (i.e. for cast or static access).
	 */
	public function compileModuleExpression(moduleType:ModuleType):String {
		return switch (moduleType) {
			case TClassDecl(clsRef):
				compileClassName(clsRef.get(), true);
			case _:
				moduleType.getNameOrNative();
		}
	}

	/**
	 * Get the name of the `ClassType` as it should appear in
	 * the C# output.
	 */
	public function compileClassName(classType:ClassType, withPack:Bool = false):String {
		return (withPack) ? '${getPackageName(classType)}.${classType.getNameOrNative()}' : classType.getNameOrNative();
	}

	/**
	 * Get the name of the `EnumType` as it should appear in
	 * the C# output.
	 */
	public function compileEnumName(enumType:EnumType, withPack:Bool = false):String {
		return if (withPack) {
			'${getPackageName(enumType)}.${enumType.getNameOrNative()}';
		} else {
			enumType.getNameOrNative();
		}
	}

	/**
	 * Get a Java package name for the given package
	 */
	public function getPackageName(baseType:BaseType):String {
		final pack = getPackWithoutModule(baseType);
		return pack.length > 0 ? pack.join('.') : JavaCompiler.DEFAULT_PACKAGE;
	}

	/**
	 * Get copy of `pack` from a `BaseType` with the module name removed.
	 */
	public function getPackWithoutModule(baseType:BaseType):Array<String> {
		final pack = baseType.pack.copy();

		if (pack.length > 0) {
			inline function shouldExcludeLastPackItem(item:String):Bool {
				return item.toLowerCase() != item;
			}

			while (pack.length > 0 && shouldExcludeLastPackItem(pack[pack.length - 1])) {
				pack.pop();
			}
		}

		return pack;
	}
}
#end

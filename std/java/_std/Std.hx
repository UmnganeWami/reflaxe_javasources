/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#if !(core_api || cross || eval)
#error "Please don't add haxe/std to your classpath, instead set HAXE_STD_PATH env var"
#end
import Enum;

/**
	The Std class provides standard methods for manipulating basic types.
**/
class Std {
	/**
		DEPRECATED. Use `Std.isOfType(v, t)` instead.

		Tells if a value `v` is of the type `t`. Returns `false` if `v` or `t` are null.

		If `t` is a class or interface with `@:generic` meta, the result is `false`.
	**/
	@:deprecated('Std.is is deprecated. Use Std.isOfType instead.')
	public static function is(v:Dynamic, t:Class<Dynamic>):Bool {
		return isOfType(v, t);
	};

	/**
		Tells if a value `v` is of the type `t`. Returns `false` if `v` or `t` are null.

		If `t` is a class or interface with `@:generic` meta, the result is `false`.
	**/
	public static function isOfType(type1:Dynamic, type2:Class<Dynamic>):Bool {
		/*var vClass:Dynamic = v.getClass();
			var tClass:Dynamic = t.getClass();
			if (untyped __javasrc__("(vClass instanceof Class)")) {
				vClass = v;
			}
			if (untyped __javasrc__("(tClass instanceof Class)")) {
				tClass = t;
			}
			return vClass.equals(tClass); */
		return untyped __javasrc__("type2.isInstance(type1)");
	};

	/**
		Checks if object `value` is an instance of class or interface `c`.

		Compiles only if the type specified by `c` can be assigned to the type
		of `value`.

		This method checks if a downcast is possible. That is, if the runtime
		type of `value` is assignable to the type specified by `c`, `value` is
		returned. Otherwise null is returned.

		This method is not guaranteed to work with core types such as `String`,
		`Array` and `Date`.

		If `value` is null, the result is null. If `c` is null, the result is
		unspecified.
	**/
	extern inline public static function downcast<T:{}, S:T>(value:T, c:Class<S>):S {
		return untyped __javasrc__("(c)t");
	};

	@:deprecated('Std.instance() is deprecated. Use Std.downcast() instead.')
	extern inline public static function instance<T:{}, S:T>(value:T, c:Class<S>):S {
		return downcast(value, c);
	};

	/**
		Converts any value to a String.

		If `s` is of `String`, `Int`, `Float` or `Bool`, its value is returned.

		If `s` is an instance of a class and that class or one of its parent classes has
		a `toString` method, that method is called. If no such method is present, the result
		is unspecified.

		If `s` is an enum constructor without argument, the constructor's name is returned. If
		arguments exists, the constructor's name followed by the String representations of
		the arguments is returned.

		If `s` is a structure, the field names along with their values are returned. The field order
		and the operator separating field names and values are unspecified.

		If s is null, "null" is returned.
	**/
	public static function string(s:Dynamic):String {
		/*if (untyped __javasrc__("s instanceof java.lang.Enum")) {
			s = untyped __javasrc__("((Enum)s).ordinal()");
		}*/
		if (s is Enum) {
			s = untyped __javasrc__("((Enum)s).name()");
		}
		if (untyped __javasrc__("s instanceof Integer")) {
			s = untyped __javasrc__("s.toString()");
		}
		var str:String = untyped __javasrc__("(String)s");
		return str;
	};

	/**
		Converts a `Float` to an `Int`, rounded towards 0.

		If `x` is outside of the signed Int32 range, or is `NaN`, `NEGATIVE_INFINITY` or `POSITIVE_INFINITY`, the result is unspecified.
	**/
	public static function int(x:Float):Int {
		var intVal:Int = untyped __javasrc__("(int)x");
		return intVal;
	};

	/**
		Converts a `String` to an `Int`.

		Leading whitespaces are ignored.

		`x` may optionally start with a + or - to denote a postive or negative value respectively.

		If the optional sign is followed 0x or 0X, hexadecimal notation is recognized where the following
		digits may contain 0-9 and A-F. Both the prefix and digits are case insensitive.

		Otherwise `x` is read as decimal number with 0-9 being allowed characters. Octal and binary
		notations are not supported.

		Parsing continues until an invalid character is detected, in which case the result up to
		that point is returned. Scientific notation is not supported. That is `Std.parseInt('10e2')` produces `10`.

		If `x` is `null`, the result is `null`.
		If `x` cannot be parsed as integer or is empty, the result is `null`.

		If `x` starts with a hexadecimal prefix which is not followed by at least one valid hexadecimal
		digit, the result is unspecified.
	**/
	public static function parseInt(x:String):Null<Int> {
		var intVal:Int = untyped __javasrc__("Integer.valueOf(x)");
		return intVal;
	};

	/**
		Converts a `String` to a `Float`.

		The parsing rules for `parseInt` apply here as well, with the exception of invalid input
		resulting in a `NaN` value instead of `null`. Also, hexadecimal support is **not** specified.

		Additionally, decimal notation may contain a single `.` to denote the start of the fractions.

		It may also end with `e` or `E` followed by optional minus or plus sign and a sequence of
		digits (defines exponent to base 10).
	**/
	public static function parseFloat(x:String):Float {
		var floatVal:Float = untyped __javasrc__("Float.parseFloat(x)");
		return floatVal;
	};

	/**
		Return a random integer between 0 included and `x` excluded.

		If `x <= 1`, the result is always 0.
	**/
	public static function random(x:Int):Int {
		untyped __javasrc__("java.util.Random rnd = new java.util.Random()");
		var randNum:Int = untyped __javasrc__("rnd.nextInt(x)");
		return randNum;
	};
}

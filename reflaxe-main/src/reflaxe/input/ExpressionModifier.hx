// =======================================================
// * ExpressionModifier
//
// Sometimes a specific expression or expression pattern
// needs to be modified pre-typing to function with
// the compiler target.
//
// This class can be used in an initialization macro
// to set up @:build macros to modify the desired expression.
// =======================================================

package reflaxe.input;

#if (macro || reflaxe_runtime)

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

class ExpressionModifier {
	static var modifications: Array<(Expr) -> Null<Expr>> = [];

	public static function mod(exprFunc: (Expr) -> Null<Expr>): Void {
		if(modifications.length == 0) {
			Compiler.addGlobalMetadata("", "@:build(reflaxe.input.ExpressionModifier.applyMods())");
		}

		modifications.push(exprFunc);
	}

	public static function applyMods(): Null<Array<Field>> {
		final fields = Context.getBuildFields();

		for(i in 0...fields.length) {
			final f = fields[i];
			switch(f.kind) {
				case FFun(fun): {
					if(fun.expr != null) {
						fun.expr = applyModsToExpr(fun.expr);
					}
				}
				case _:
			}
		}

		return fields;
	}

	static function applyModsToExpr(e: Expr): Expr {

		var currentExpr = e;
		for(mod in modifications) {
			final result = mod(e);
			if(result != null) {
				currentExpr = result;
			}
		}
		return haxe.macro.ExprTools.map(currentExpr, applyModsToExpr);
	}
}

#end

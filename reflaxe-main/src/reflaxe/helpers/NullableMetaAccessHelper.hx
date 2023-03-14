// =======================================================
// * NullableMetaAccessHelper
//
// MetaAccess can be annoying sometimes because the
// functions themselves may be null. These helper
// functions wrap around the normal MetaAccess functions
// and ensure they are not null before calling.
// =======================================================

package reflaxe.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using reflaxe.helpers.DynamicHelper;

class NullableMetaAccessHelper {
	public static function maybeHas(m: Null<MetaAccess>, name: String): Bool {
		return m != null && m.has != null && m.has(name);
	}

	public static function maybeExtract(m: Null<MetaAccess>, name: String): Array<MetadataEntry> {
		if(m == null || m.extract == null) return [];
		return m.extract(name);
	}

	public static function maybeAdd(m: Null<MetaAccess>, name: String, params: Array<Expr>, pos: Position): Void {
		if(m != null && m.add != null) {
			m.add(name, params, pos);
		}
	}

	// Extracts and formats content of @:meta metadata.
	// Can be used as easy method for retrieving metadata that should be generated in output.
	public static function extractNativeMeta(metaAccess: Null<MetaAccess>, allowMultiParam: Bool = true): Null<Array<String>> {
		if(metaAccess == null || metaAccess.extract == null) {
			return null;
		}
		final result = [];
		final meta = metaAccess.extract(":meta");
		for(m in meta) {
			if(m.params == null || m.params.length == 0) {
				Context.error("Native meta expression expected as parameter.", m.pos);
			}
			if(!allowMultiParam && m.params.length > 1) {
				Context.error("Only one expression should be supplied for native meta.", m.pos);
			}
			for(param in m.params) {
				result.push(haxe.macro.ExprTools.toString(param));
			}
		}
		return result;
	}

	// ------------------------
	// String paramter extractors
	// ------------------------

	public static function extractStringFromFirstMeta(metaAccess: Null<MetaAccess>, metaName: String, index: Int = 0): Null<String> {
		final result = extractPrimtiveFromFirstMeta(metaAccess, metaName, index);
		return if(result != null && result.isString()) result;
		else null;
	}

	public static function extractPrimtiveFromFirstMeta(metaAccess: Null<MetaAccess>, metaName: String, index: Int = 0): Null<Dynamic> {
		if(metaAccess == null) return null;
		final metaList = maybeExtract(metaAccess, metaName);
		for(m in metaList) {
			final result = extractPrimitiveFromEntry(m, index);
			if(result != null) return result;
		}
		return null;
	}

	public static function extractPrimtiveFromAllMeta(metaAccess: Null<MetaAccess>, metaName: String, index: Int = 0): Array<Dynamic> {
		if(metaAccess == null) return [];
		final result = [];
		final metaList = maybeExtract(metaAccess, metaName);
		for(m in metaList) {
			final prim = extractPrimitiveFromEntry(m, index);
			if(result != null) result.push(prim);
		}
		return result;
	}

	public static function extractParamsFromFirstMeta(metaAccess: Null<MetaAccess>, metaName: String): Null<Array<Dynamic>> {
		if(metaAccess == null) return null;
		final metaList = maybeExtract(metaAccess, metaName);
		if(metaList.length > 0) {
			final result = [];
			final m = metaList[0];
			for(i in 0...m.params.length) {
				result.push(extractPrimitiveFromEntry(m, i));
			}
			return result;
		}
		return null;
	}

	public static function extractParamsFromAllMeta(metaAccess: Null<MetaAccess>, metaName: String): Array<Array<Dynamic>> {
		if(metaAccess == null) return null;
		final metaList = maybeExtract(metaAccess, metaName);
		final result = [];
		for(m in metaList) {
			final params = [];
			for(i in 0...m.params.length) {
				params.push(extractPrimitiveFromEntry(m, i));
			}
			result.push(params);
		}
		return result;
	}

	private static function extractPrimitiveFromEntry(entry: MetadataEntry, index: Int = 0): Null<Dynamic> {
		return if(entry.params.length > index) {
			switch(entry.params[index].expr) {
				case EConst(CInt(v)): Std.string(v);
				case EConst(CFloat(f)): Std.string(f);
				case EConst(CString(s, _)): s;
				case EConst(CIdent(s)): {
					if(s == "true") true;
					else if(s == "false") false;
					else s;
				}
				case EConst(CRegexp(r, opt)): "/" + r + "/" + opt;
				case _: null;
			}
		} else {
			null;
		}
	}
}

#end

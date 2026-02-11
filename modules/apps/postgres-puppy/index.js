// @bun
// GENERATED, do not edit
var __create = Object.create;
var __getProtoOf = Object.getPrototypeOf;
var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __toESM = (mod, isNodeMode, target) => {
  target = mod != null ? __create(__getProtoOf(mod)) : {};
  const to = isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target;
  for (let key of __getOwnPropNames(mod))
    if (!__hasOwnProp.call(to, key))
      __defProp(to, key, {
        get: () => mod[key],
        enumerable: true
      });
  return to;
};
var __commonJS = (cb, mod) => () => (mod || cb((mod = { exports: {} }).exports, mod), mod.exports);
var __require = import.meta.require;

// node_modules/@1password/sdk-core/nodejs/core.js
var require_core = __commonJS((exports, module) => {
  var imports = {};
  imports["__wbindgen_placeholder__"] = exports;
  var wasm;
  var { TextDecoder: TextDecoder2, TextEncoder: TextEncoder2 } = __require("util");
  var cachedTextDecoder = new TextDecoder2("utf-8", { ignoreBOM: true, fatal: true });
  cachedTextDecoder.decode();
  var cachedUint8ArrayMemory0 = null;
  function getUint8ArrayMemory0() {
    if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
      cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
    }
    return cachedUint8ArrayMemory0;
  }
  function getStringFromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
  }
  function addToExternrefTable0(obj) {
    const idx = wasm.__externref_table_alloc();
    wasm.__wbindgen_export_2.set(idx, obj);
    return idx;
  }
  function handleError(f, args) {
    try {
      return f.apply(this, args);
    } catch (e) {
      const idx = addToExternrefTable0(e);
      wasm.__wbindgen_exn_store(idx);
    }
  }
  function isLikeNone(x) {
    return x === undefined || x === null;
  }
  var WASM_VECTOR_LEN = 0;
  var cachedTextEncoder = new TextEncoder2("utf-8");
  var encodeString = typeof cachedTextEncoder.encodeInto === "function" ? function(arg, view) {
    return cachedTextEncoder.encodeInto(arg, view);
  } : function(arg, view) {
    const buf = cachedTextEncoder.encode(arg);
    view.set(buf);
    return {
      read: arg.length,
      written: buf.length
    };
  };
  function passStringToWasm0(arg, malloc, realloc) {
    if (realloc === undefined) {
      const buf = cachedTextEncoder.encode(arg);
      const ptr2 = malloc(buf.length, 1) >>> 0;
      getUint8ArrayMemory0().subarray(ptr2, ptr2 + buf.length).set(buf);
      WASM_VECTOR_LEN = buf.length;
      return ptr2;
    }
    let len = arg.length;
    let ptr = malloc(len, 1) >>> 0;
    const mem = getUint8ArrayMemory0();
    let offset = 0;
    for (;offset < len; offset++) {
      const code = arg.charCodeAt(offset);
      if (code > 127)
        break;
      mem[ptr + offset] = code;
    }
    if (offset !== len) {
      if (offset !== 0) {
        arg = arg.slice(offset);
      }
      ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
      const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
      const ret = encodeString(arg, view);
      offset += ret.written;
      ptr = realloc(ptr, len, offset, 1) >>> 0;
    }
    WASM_VECTOR_LEN = offset;
    return ptr;
  }
  var cachedDataViewMemory0 = null;
  function getDataViewMemory0() {
    if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer) {
      cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
    }
    return cachedDataViewMemory0;
  }
  var CLOSURE_DTORS = typeof FinalizationRegistry === "undefined" ? { register: () => {}, unregister: () => {} } : new FinalizationRegistry((state) => {
    wasm.__wbindgen_export_5.get(state.dtor)(state.a, state.b);
  });
  function makeMutClosure(arg0, arg1, dtor, f) {
    const state = { a: arg0, b: arg1, cnt: 1, dtor };
    const real = (...args) => {
      state.cnt++;
      const a = state.a;
      state.a = 0;
      try {
        return f(a, state.b, ...args);
      } finally {
        if (--state.cnt === 0) {
          wasm.__wbindgen_export_5.get(state.dtor)(a, state.b);
          CLOSURE_DTORS.unregister(state);
        } else {
          state.a = a;
        }
      }
    };
    real.original = state;
    CLOSURE_DTORS.register(real, state, state);
    return real;
  }
  function debugString(val) {
    const type = typeof val;
    if (type == "number" || type == "boolean" || val == null) {
      return `${val}`;
    }
    if (type == "string") {
      return `"${val}"`;
    }
    if (type == "symbol") {
      const description = val.description;
      if (description == null) {
        return "Symbol";
      } else {
        return `Symbol(${description})`;
      }
    }
    if (type == "function") {
      const name = val.name;
      if (typeof name == "string" && name.length > 0) {
        return `Function(${name})`;
      } else {
        return "Function";
      }
    }
    if (Array.isArray(val)) {
      const length = val.length;
      let debug = "[";
      if (length > 0) {
        debug += debugString(val[0]);
      }
      for (let i = 1;i < length; i++) {
        debug += ", " + debugString(val[i]);
      }
      debug += "]";
      return debug;
    }
    const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
    let className;
    if (builtInMatches && builtInMatches.length > 1) {
      className = builtInMatches[1];
    } else {
      return toString.call(val);
    }
    if (className == "Object") {
      try {
        return "Object(" + JSON.stringify(val) + ")";
      } catch (_) {
        return "Object";
      }
    }
    if (val instanceof Error) {
      return `${val.name}: ${val.message}
${val.stack}`;
    }
    return className;
  }
  exports.init_client = function(config) {
    const ptr0 = passStringToWasm0(config, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ret = wasm.init_client(ptr0, len0);
    return ret;
  };
  exports.invoke = function(parameters) {
    const ptr0 = passStringToWasm0(parameters, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ret = wasm.invoke(ptr0, len0);
    return ret;
  };
  function takeFromExternrefTable0(idx) {
    const value = wasm.__wbindgen_export_2.get(idx);
    wasm.__externref_table_dealloc(idx);
    return value;
  }
  exports.invoke_sync = function(parameters) {
    let deferred3_0;
    let deferred3_1;
    try {
      const ptr0 = passStringToWasm0(parameters, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
      const len0 = WASM_VECTOR_LEN;
      const ret = wasm.invoke_sync(ptr0, len0);
      var ptr2 = ret[0];
      var len2 = ret[1];
      if (ret[3]) {
        ptr2 = 0;
        len2 = 0;
        throw takeFromExternrefTable0(ret[2]);
      }
      deferred3_0 = ptr2;
      deferred3_1 = len2;
      return getStringFromWasm0(ptr2, len2);
    } finally {
      wasm.__wbindgen_free(deferred3_0, deferred3_1, 1);
    }
  };
  exports.release_client = function(client_id) {
    const ptr0 = passStringToWasm0(client_id, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len0 = WASM_VECTOR_LEN;
    const ret = wasm.release_client(ptr0, len0);
    if (ret[1]) {
      throw takeFromExternrefTable0(ret[0]);
    }
  };
  function __wbg_adapter_30(arg0, arg1) {
    wasm._dyn_core__ops__function__FnMut_____Output___R_as_wasm_bindgen__closure__WasmClosure___describe__invoke__h4fa304e9a7297dba(arg0, arg1);
  }
  function __wbg_adapter_33(arg0, arg1, arg2) {
    wasm.closure2484_externref_shim(arg0, arg1, arg2);
  }
  function __wbg_adapter_156(arg0, arg1, arg2, arg3) {
    wasm.closure2632_externref_shim(arg0, arg1, arg2, arg3);
  }
  var __wbindgen_enum_RequestCache = ["default", "no-store", "reload", "no-cache", "force-cache", "only-if-cached"];
  var __wbindgen_enum_RequestCredentials = ["omit", "same-origin", "include"];
  var __wbindgen_enum_RequestMode = ["same-origin", "no-cors", "cors", "navigate"];
  exports.__wbg_abort_410ec47a64ac6117 = function(arg0, arg1) {
    arg0.abort(arg1);
  };
  exports.__wbg_abort_775ef1d17fc65868 = function(arg0) {
    arg0.abort();
  };
  exports.__wbg_append_8c7dd8d641a5f01b = function() {
    return handleError(function(arg0, arg1, arg2, arg3, arg4) {
      arg0.append(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
    }, arguments);
  };
  exports.__wbg_arrayBuffer_d1b44c4390db422f = function() {
    return handleError(function(arg0) {
      const ret = arg0.arrayBuffer();
      return ret;
    }, arguments);
  };
  exports.__wbg_buffer_609cc3eee51ed158 = function(arg0) {
    const ret = arg0.buffer;
    return ret;
  };
  exports.__wbg_call_672a4d21634d4a24 = function() {
    return handleError(function(arg0, arg1) {
      const ret = arg0.call(arg1);
      return ret;
    }, arguments);
  };
  exports.__wbg_call_7cccdd69e0791ae2 = function() {
    return handleError(function(arg0, arg1, arg2) {
      const ret = arg0.call(arg1, arg2);
      return ret;
    }, arguments);
  };
  exports.__wbg_clearTimeout_42d9ccd50822fd3a = function(arg0) {
    const ret = clearTimeout(arg0);
    return ret;
  };
  exports.__wbg_crypto_86f2631e91b51511 = function(arg0) {
    const ret = arg0.crypto;
    return ret;
  };
  exports.__wbg_done_769e5ede4b31c67b = function(arg0) {
    const ret = arg0.done;
    return ret;
  };
  exports.__wbg_fetch_509096533071c657 = function(arg0, arg1) {
    const ret = arg0.fetch(arg1);
    return ret;
  };
  exports.__wbg_fetch_6bbc32f991730587 = function(arg0) {
    const ret = fetch(arg0);
    return ret;
  };
  exports.__wbg_getFullYear_17d3c9e4db748eb7 = function(arg0) {
    const ret = arg0.getFullYear();
    return ret;
  };
  exports.__wbg_getRandomValues_b3f15fcbfabb0f8b = function() {
    return handleError(function(arg0, arg1) {
      arg0.getRandomValues(arg1);
    }, arguments);
  };
  exports.__wbg_getTimezoneOffset_6b5752021c499c47 = function(arg0) {
    const ret = arg0.getTimezoneOffset();
    return ret;
  };
  exports.__wbg_get_67b2ba62fc30de12 = function() {
    return handleError(function(arg0, arg1) {
      const ret = Reflect.get(arg0, arg1);
      return ret;
    }, arguments);
  };
  exports.__wbg_has_a5ea9117f258a0ec = function() {
    return handleError(function(arg0, arg1) {
      const ret = Reflect.has(arg0, arg1);
      return ret;
    }, arguments);
  };
  exports.__wbg_headers_9cb51cfd2ac780a4 = function(arg0) {
    const ret = arg0.headers;
    return ret;
  };
  exports.__wbg_instanceof_Response_f2cc20d9f7dfd644 = function(arg0) {
    let result;
    try {
      result = arg0 instanceof Response;
    } catch (_) {
      result = false;
    }
    const ret = result;
    return ret;
  };
  exports.__wbg_instanceof_Window_def73ea0955fc569 = function(arg0) {
    let result;
    try {
      result = arg0 instanceof Window;
    } catch (_) {
      result = false;
    }
    const ret = result;
    return ret;
  };
  exports.__wbg_instanceof_WorkerGlobalScope_dbdbdea7e3b56493 = function(arg0) {
    let result;
    try {
      result = arg0 instanceof WorkerGlobalScope;
    } catch (_) {
      result = false;
    }
    const ret = result;
    return ret;
  };
  exports.__wbg_iterator_9a24c88df860dc65 = function() {
    const ret = Symbol.iterator;
    return ret;
  };
  exports.__wbg_languages_2420955220685766 = function(arg0) {
    const ret = arg0.languages;
    return ret;
  };
  exports.__wbg_languages_d8dad509faf757df = function(arg0) {
    const ret = arg0.languages;
    return ret;
  };
  exports.__wbg_length_a446193dc22c12f8 = function(arg0) {
    const ret = arg0.length;
    return ret;
  };
  exports.__wbg_msCrypto_d562bbe83e0d4b91 = function(arg0) {
    const ret = arg0.msCrypto;
    return ret;
  };
  exports.__wbg_navigator_0a9bf1120e24fec2 = function(arg0) {
    const ret = arg0.navigator;
    return ret;
  };
  exports.__wbg_navigator_1577371c070c8947 = function(arg0) {
    const ret = arg0.navigator;
    return ret;
  };
  exports.__wbg_new0_f788a2397c7ca929 = function() {
    const ret = new Date;
    return ret;
  };
  exports.__wbg_new_018dcc2d6c8c2f6a = function() {
    return handleError(function() {
      const ret = new Headers;
      return ret;
    }, arguments);
  };
  exports.__wbg_new_23a2665fac83c611 = function(arg0, arg1) {
    try {
      var state0 = { a: arg0, b: arg1 };
      var cb0 = (arg02, arg12) => {
        const a = state0.a;
        state0.a = 0;
        try {
          return __wbg_adapter_156(a, state0.b, arg02, arg12);
        } finally {
          state0.a = a;
        }
      };
      const ret = new Promise(cb0);
      return ret;
    } finally {
      state0.a = state0.b = 0;
    }
  };
  exports.__wbg_new_31a97dac4f10fab7 = function(arg0) {
    const ret = new Date(arg0);
    return ret;
  };
  exports.__wbg_new_405e22f390576ce2 = function() {
    const ret = new Object;
    return ret;
  };
  exports.__wbg_new_a12002a7f91c75be = function(arg0) {
    const ret = new Uint8Array(arg0);
    return ret;
  };
  exports.__wbg_new_e25e5aab09ff45db = function() {
    return handleError(function() {
      const ret = new AbortController;
      return ret;
    }, arguments);
  };
  exports.__wbg_newnoargs_105ed471475aaf50 = function(arg0, arg1) {
    const ret = new Function(getStringFromWasm0(arg0, arg1));
    return ret;
  };
  exports.__wbg_newwithbyteoffsetandlength_d97e637ebe145a9a = function(arg0, arg1, arg2) {
    const ret = new Uint8Array(arg0, arg1 >>> 0, arg2 >>> 0);
    return ret;
  };
  exports.__wbg_newwithlength_a381634e90c276d4 = function(arg0) {
    const ret = new Uint8Array(arg0 >>> 0);
    return ret;
  };
  exports.__wbg_newwithstrandinit_06c535e0a867c635 = function() {
    return handleError(function(arg0, arg1, arg2) {
      const ret = new Request(getStringFromWasm0(arg0, arg1), arg2);
      return ret;
    }, arguments);
  };
  exports.__wbg_next_25feadfc0913fea9 = function(arg0) {
    const ret = arg0.next;
    return ret;
  };
  exports.__wbg_next_6574e1a8a62d1055 = function() {
    return handleError(function(arg0) {
      const ret = arg0.next();
      return ret;
    }, arguments);
  };
  exports.__wbg_node_e1f24f89a7336c2e = function(arg0) {
    const ret = arg0.node;
    return ret;
  };
  exports.__wbg_now_807e54c39636c349 = function() {
    const ret = Date.now();
    return ret;
  };
  exports.__wbg_now_d18023d54d4e5500 = function(arg0) {
    const ret = arg0.now();
    return ret;
  };
  exports.__wbg_parse_def2e24ef1252aff = function() {
    return handleError(function(arg0, arg1) {
      const ret = JSON.parse(getStringFromWasm0(arg0, arg1));
      return ret;
    }, arguments);
  };
  exports.__wbg_process_3975fd6c72f520aa = function(arg0) {
    const ret = arg0.process;
    return ret;
  };
  exports.__wbg_queueMicrotask_97d92b4fcc8a61c5 = function(arg0) {
    queueMicrotask(arg0);
  };
  exports.__wbg_queueMicrotask_d3219def82552485 = function(arg0) {
    const ret = arg0.queueMicrotask;
    return ret;
  };
  exports.__wbg_randomFillSync_f8c153b79f285817 = function() {
    return handleError(function(arg0, arg1) {
      arg0.randomFillSync(arg1);
    }, arguments);
  };
  exports.__wbg_require_b74f47fc2d022fd6 = function() {
    return handleError(function() {
      const ret = module.require;
      return ret;
    }, arguments);
  };
  exports.__wbg_resolve_4851785c9c5f573d = function(arg0) {
    const ret = Promise.resolve(arg0);
    return ret;
  };
  exports.__wbg_self_b29ea9f89ecb0567 = function() {
    return handleError(function() {
      const ret = self.self;
      return ret;
    }, arguments);
  };
  exports.__wbg_setTimeout_4ec014681668a581 = function(arg0, arg1) {
    const ret = setTimeout(arg0, arg1);
    return ret;
  };
  exports.__wbg_set_65595bdd868b3009 = function(arg0, arg1, arg2) {
    arg0.set(arg1, arg2 >>> 0);
  };
  exports.__wbg_setbody_5923b78a95eedf29 = function(arg0, arg1) {
    arg0.body = arg1;
  };
  exports.__wbg_setcache_12f17c3a980650e4 = function(arg0, arg1) {
    arg0.cache = __wbindgen_enum_RequestCache[arg1];
  };
  exports.__wbg_setcredentials_c3a22f1cd105a2c6 = function(arg0, arg1) {
    arg0.credentials = __wbindgen_enum_RequestCredentials[arg1];
  };
  exports.__wbg_setheaders_834c0bdb6a8949ad = function(arg0, arg1) {
    arg0.headers = arg1;
  };
  exports.__wbg_setmethod_3c5280fe5d890842 = function(arg0, arg1, arg2) {
    arg0.method = getStringFromWasm0(arg1, arg2);
  };
  exports.__wbg_setmode_5dc300b865044b65 = function(arg0, arg1) {
    arg0.mode = __wbindgen_enum_RequestMode[arg1];
  };
  exports.__wbg_setsignal_75b21ef3a81de905 = function(arg0, arg1) {
    arg0.signal = arg1;
  };
  exports.__wbg_signal_aaf9ad74119f20a4 = function(arg0) {
    const ret = arg0.signal;
    return ret;
  };
  exports.__wbg_static_accessor_GLOBAL_88a902d13a557d07 = function() {
    const ret = typeof global === "undefined" ? null : global;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
  };
  exports.__wbg_static_accessor_GLOBAL_THIS_56578be7e9f832b0 = function() {
    const ret = typeof globalThis === "undefined" ? null : globalThis;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
  };
  exports.__wbg_static_accessor_SELF_37c5d418e4bf5819 = function() {
    const ret = typeof self === "undefined" ? null : self;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
  };
  exports.__wbg_static_accessor_WINDOW_5de37043a91a9c40 = function() {
    const ret = typeof window === "undefined" ? null : window;
    return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
  };
  exports.__wbg_static_accessor_performance_da77b3a901a72934 = function() {
    const ret = performance;
    return ret;
  };
  exports.__wbg_status_f6360336ca686bf0 = function(arg0) {
    const ret = arg0.status;
    return ret;
  };
  exports.__wbg_stringify_f7ed6987935b4a24 = function() {
    return handleError(function(arg0) {
      const ret = JSON.stringify(arg0);
      return ret;
    }, arguments);
  };
  exports.__wbg_subarray_aa9065fa9dc5df96 = function(arg0, arg1, arg2) {
    const ret = arg0.subarray(arg1 >>> 0, arg2 >>> 0);
    return ret;
  };
  exports.__wbg_then_44b73946d2fb3e7d = function(arg0, arg1) {
    const ret = arg0.then(arg1);
    return ret;
  };
  exports.__wbg_then_48b406749878a531 = function(arg0, arg1, arg2) {
    const ret = arg0.then(arg1, arg2);
    return ret;
  };
  exports.__wbg_toLocaleDateString_e5424994746e8415 = function(arg0, arg1, arg2, arg3) {
    const ret = arg0.toLocaleDateString(getStringFromWasm0(arg1, arg2), arg3);
    return ret;
  };
  exports.__wbg_url_ae10c34ca209681d = function(arg0, arg1) {
    const ret = arg1.url;
    const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
  };
  exports.__wbg_value_cd1ffa7b1ab794f1 = function(arg0) {
    const ret = arg0.value;
    return ret;
  };
  exports.__wbg_values_99f7a68c7f313d66 = function(arg0) {
    const ret = arg0.values();
    return ret;
  };
  exports.__wbg_versions_4e31226f5e8dc909 = function(arg0) {
    const ret = arg0.versions;
    return ret;
  };
  exports.__wbg_window_aa5515e600e96252 = function() {
    return handleError(function() {
      const ret = window.window;
      return ret;
    }, arguments);
  };
  exports.__wbindgen_cb_drop = function(arg0) {
    const obj = arg0.original;
    if (obj.cnt-- == 1) {
      obj.a = 0;
      return true;
    }
    const ret = false;
    return ret;
  };
  exports.__wbindgen_closure_wrapper9169 = function(arg0, arg1, arg2) {
    const ret = makeMutClosure(arg0, arg1, 2463, __wbg_adapter_30);
    return ret;
  };
  exports.__wbindgen_closure_wrapper9209 = function(arg0, arg1, arg2) {
    const ret = makeMutClosure(arg0, arg1, 2485, __wbg_adapter_33);
    return ret;
  };
  exports.__wbindgen_debug_string = function(arg0, arg1) {
    const ret = debugString(arg1);
    const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    const len1 = WASM_VECTOR_LEN;
    getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
  };
  exports.__wbindgen_init_externref_table = function() {
    const table = wasm.__wbindgen_export_2;
    const offset = table.grow(4);
    table.set(0, undefined);
    table.set(offset + 0, undefined);
    table.set(offset + 1, null);
    table.set(offset + 2, true);
    table.set(offset + 3, false);
  };
  exports.__wbindgen_is_function = function(arg0) {
    const ret = typeof arg0 === "function";
    return ret;
  };
  exports.__wbindgen_is_object = function(arg0) {
    const val = arg0;
    const ret = typeof val === "object" && val !== null;
    return ret;
  };
  exports.__wbindgen_is_string = function(arg0) {
    const ret = typeof arg0 === "string";
    return ret;
  };
  exports.__wbindgen_is_undefined = function(arg0) {
    const ret = arg0 === undefined;
    return ret;
  };
  exports.__wbindgen_memory = function() {
    const ret = wasm.memory;
    return ret;
  };
  exports.__wbindgen_number_new = function(arg0) {
    const ret = arg0;
    return ret;
  };
  exports.__wbindgen_string_get = function(arg0, arg1) {
    const obj = arg1;
    const ret = typeof obj === "string" ? obj : undefined;
    var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
    var len1 = WASM_VECTOR_LEN;
    getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
    getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
  };
  exports.__wbindgen_string_new = function(arg0, arg1) {
    const ret = getStringFromWasm0(arg0, arg1);
    return ret;
  };
  exports.__wbindgen_throw = function(arg0, arg1) {
    throw new Error(getStringFromWasm0(arg0, arg1));
  };
  var path = __require("path").join("./", "core_bg.wasm");
  var bytes = __require("fs").readFileSync(path);
  var wasmModule = new WebAssembly.Module(bytes);
  var wasmInstance = new WebAssembly.Instance(wasmModule, imports);
  wasm = wasmInstance.exports;
  exports.__wasm = wasm;
  wasm.__wbindgen_start();
});

// node_modules/@1password/sdk/dist/types.js
var require_types = __commonJS((exports) => {
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.ReplacerFunc = exports.ReviverFunc = exports.UPDATE_ITEM_HISTORY = exports.UPDATE_ITEMS = exports.SEND_ITEMS = exports.REVEAL_ITEM_PASSWORD = exports.RECOVER_VAULT = exports.READ_ITEMS = exports.PRINT_ITEMS = exports.NO_ACCESS = exports.MANAGE_VAULT = exports.IMPORT_ITEMS = exports.EXPORT_ITEMS = exports.DELETE_ITEMS = exports.CREATE_ITEMS = exports.ARCHIVE_ITEMS = exports.WordListType = exports.SeparatorType = exports.VaultType = exports.AllowedRecipientType = exports.AllowedType = exports.ItemShareDuration = exports.ItemState = exports.AutofillBehavior = exports.ItemFieldType = exports.ItemCategory = exports.VaultAccessorType = exports.GroupState = exports.GroupType = undefined;
  var GroupType;
  (function(GroupType2) {
    GroupType2["Owners"] = "owners";
    GroupType2["Administrators"] = "administrators";
    GroupType2["Recovery"] = "recovery";
    GroupType2["ExternalAccountManagers"] = "externalAccountManagers";
    GroupType2["TeamMembers"] = "teamMembers";
    GroupType2["UserDefined"] = "userDefined";
    GroupType2["Unsupported"] = "unsupported";
  })(GroupType || (exports.GroupType = GroupType = {}));
  var GroupState;
  (function(GroupState2) {
    GroupState2["Active"] = "active";
    GroupState2["Deleted"] = "deleted";
    GroupState2["Unsupported"] = "unsupported";
  })(GroupState || (exports.GroupState = GroupState = {}));
  var VaultAccessorType;
  (function(VaultAccessorType2) {
    VaultAccessorType2["User"] = "user";
    VaultAccessorType2["Group"] = "group";
  })(VaultAccessorType || (exports.VaultAccessorType = VaultAccessorType = {}));
  var ItemCategory;
  (function(ItemCategory2) {
    ItemCategory2["Login"] = "Login";
    ItemCategory2["SecureNote"] = "SecureNote";
    ItemCategory2["CreditCard"] = "CreditCard";
    ItemCategory2["CryptoWallet"] = "CryptoWallet";
    ItemCategory2["Identity"] = "Identity";
    ItemCategory2["Password"] = "Password";
    ItemCategory2["Document"] = "Document";
    ItemCategory2["ApiCredentials"] = "ApiCredentials";
    ItemCategory2["BankAccount"] = "BankAccount";
    ItemCategory2["Database"] = "Database";
    ItemCategory2["DriverLicense"] = "DriverLicense";
    ItemCategory2["Email"] = "Email";
    ItemCategory2["MedicalRecord"] = "MedicalRecord";
    ItemCategory2["Membership"] = "Membership";
    ItemCategory2["OutdoorLicense"] = "OutdoorLicense";
    ItemCategory2["Passport"] = "Passport";
    ItemCategory2["Rewards"] = "Rewards";
    ItemCategory2["Router"] = "Router";
    ItemCategory2["Server"] = "Server";
    ItemCategory2["SshKey"] = "SshKey";
    ItemCategory2["SocialSecurityNumber"] = "SocialSecurityNumber";
    ItemCategory2["SoftwareLicense"] = "SoftwareLicense";
    ItemCategory2["Person"] = "Person";
    ItemCategory2["Unsupported"] = "Unsupported";
  })(ItemCategory || (exports.ItemCategory = ItemCategory = {}));
  var ItemFieldType;
  (function(ItemFieldType2) {
    ItemFieldType2["Text"] = "Text";
    ItemFieldType2["Concealed"] = "Concealed";
    ItemFieldType2["CreditCardType"] = "CreditCardType";
    ItemFieldType2["CreditCardNumber"] = "CreditCardNumber";
    ItemFieldType2["Phone"] = "Phone";
    ItemFieldType2["Url"] = "Url";
    ItemFieldType2["Totp"] = "Totp";
    ItemFieldType2["Email"] = "Email";
    ItemFieldType2["Reference"] = "Reference";
    ItemFieldType2["SshKey"] = "SshKey";
    ItemFieldType2["Menu"] = "Menu";
    ItemFieldType2["MonthYear"] = "MonthYear";
    ItemFieldType2["Address"] = "Address";
    ItemFieldType2["Date"] = "Date";
    ItemFieldType2["Unsupported"] = "Unsupported";
  })(ItemFieldType || (exports.ItemFieldType = ItemFieldType = {}));
  var AutofillBehavior;
  (function(AutofillBehavior2) {
    AutofillBehavior2["AnywhereOnWebsite"] = "AnywhereOnWebsite";
    AutofillBehavior2["ExactDomain"] = "ExactDomain";
    AutofillBehavior2["Never"] = "Never";
  })(AutofillBehavior || (exports.AutofillBehavior = AutofillBehavior = {}));
  var ItemState;
  (function(ItemState2) {
    ItemState2["Active"] = "active";
    ItemState2["Archived"] = "archived";
  })(ItemState || (exports.ItemState = ItemState = {}));
  var ItemShareDuration;
  (function(ItemShareDuration2) {
    ItemShareDuration2["OneHour"] = "OneHour";
    ItemShareDuration2["OneDay"] = "OneDay";
    ItemShareDuration2["SevenDays"] = "SevenDays";
    ItemShareDuration2["FourteenDays"] = "FourteenDays";
    ItemShareDuration2["ThirtyDays"] = "ThirtyDays";
  })(ItemShareDuration || (exports.ItemShareDuration = ItemShareDuration = {}));
  var AllowedType;
  (function(AllowedType2) {
    AllowedType2["Authenticated"] = "Authenticated";
    AllowedType2["Public"] = "Public";
  })(AllowedType || (exports.AllowedType = AllowedType = {}));
  var AllowedRecipientType;
  (function(AllowedRecipientType2) {
    AllowedRecipientType2["Email"] = "Email";
    AllowedRecipientType2["Domain"] = "Domain";
  })(AllowedRecipientType || (exports.AllowedRecipientType = AllowedRecipientType = {}));
  var VaultType;
  (function(VaultType2) {
    VaultType2["Personal"] = "personal";
    VaultType2["Everyone"] = "everyone";
    VaultType2["Transfer"] = "transfer";
    VaultType2["UserCreated"] = "userCreated";
    VaultType2["Unsupported"] = "unsupported";
  })(VaultType || (exports.VaultType = VaultType = {}));
  var SeparatorType;
  (function(SeparatorType2) {
    SeparatorType2["Digits"] = "digits";
    SeparatorType2["DigitsAndSymbols"] = "digitsAndSymbols";
    SeparatorType2["Spaces"] = "spaces";
    SeparatorType2["Hyphens"] = "hyphens";
    SeparatorType2["Underscores"] = "underscores";
    SeparatorType2["Periods"] = "periods";
    SeparatorType2["Commas"] = "commas";
  })(SeparatorType || (exports.SeparatorType = SeparatorType = {}));
  var WordListType;
  (function(WordListType2) {
    WordListType2["FullWords"] = "fullWords";
    WordListType2["Syllables"] = "syllables";
    WordListType2["ThreeLetters"] = "threeLetters";
  })(WordListType || (exports.WordListType = WordListType = {}));
  exports.ARCHIVE_ITEMS = 256;
  exports.CREATE_ITEMS = 128;
  exports.DELETE_ITEMS = 512;
  exports.EXPORT_ITEMS = 4194304;
  exports.IMPORT_ITEMS = 2097152;
  exports.MANAGE_VAULT = 2;
  exports.NO_ACCESS = 0;
  exports.PRINT_ITEMS = 8388608;
  exports.READ_ITEMS = 32;
  exports.RECOVER_VAULT = 1;
  exports.REVEAL_ITEM_PASSWORD = 16;
  exports.SEND_ITEMS = 1048576;
  exports.UPDATE_ITEMS = 64;
  exports.UPDATE_ITEM_HISTORY = 1024;
  var ReviverFunc = (key, value) => {
    if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/.test(value) && (key === "createdAt" || key === "updatedAt")) {
      return new Date(value);
    }
    if (Array.isArray(value) && value.every((v) => Number.isInteger(v) && v >= 0 && v <= 255) && value.length > 0) {
      return new Uint8Array(value);
    }
    return value;
  };
  exports.ReviverFunc = ReviverFunc;
  var ReplacerFunc = (key, value) => {
    if (value instanceof Date) {
      return value.toISOString();
    }
    if (value instanceof Uint8Array) {
      return Array.from(value);
    }
    return value;
  };
  exports.ReplacerFunc = ReplacerFunc;
});

// node_modules/@1password/sdk/dist/errors.js
var require_errors = __commonJS((exports) => {
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.throwError = exports.RateLimitExceededError = exports.DesktopSessionExpiredError = undefined;

  class DesktopSessionExpiredError extends Error {
    constructor(message) {
      super();
      this.message = message;
    }
  }
  exports.DesktopSessionExpiredError = DesktopSessionExpiredError;

  class RateLimitExceededError extends Error {
    constructor(message) {
      super();
      this.message = message;
    }
  }
  exports.RateLimitExceededError = RateLimitExceededError;
  var throwError = (errString) => {
    let err;
    try {
      err = JSON.parse(errString);
    } catch (e) {
      throw new Error(errString);
    }
    switch (err.name) {
      case "DesktopSessionExpired":
        throw new DesktopSessionExpiredError(err.message);
      case "RateLimitExceeded":
        throw new RateLimitExceededError(err.message);
      default:
        throw new Error(err.message);
    }
  };
  exports.throwError = throwError;
});

// node_modules/@1password/sdk/dist/core.js
var require_core2 = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.InnerClient = exports.SharedCore = exports.WasmCore = undefined;
  var sdk_core_1 = require_core();
  var types_1 = require_types();
  var errors_1 = require_errors();
  var messageLimit = 50 * 1024 * 1024;

  class WasmCore {
    initClient(config) {
      return __awaiter(this, undefined, undefined, function* () {
        try {
          return yield (0, sdk_core_1.init_client)(config);
        } catch (e) {
          (0, errors_1.throwError)(e);
        }
      });
    }
    invoke(config) {
      return __awaiter(this, undefined, undefined, function* () {
        try {
          return yield (0, sdk_core_1.invoke)(config);
        } catch (e) {
          (0, errors_1.throwError)(e);
        }
      });
    }
    releaseClient(clientId) {
      try {
        (0, sdk_core_1.release_client)(clientId);
      } catch (e) {
        console.warn("failed to release client:", e);
      }
    }
  }
  exports.WasmCore = WasmCore;

  class SharedCore {
    constructor() {
      this.inner = new WasmCore;
    }
    setInner(core) {
      this.inner = core;
    }
    initClient(config) {
      return __awaiter(this, undefined, undefined, function* () {
        const serializedConfig = JSON.stringify(config);
        return this.inner.initClient(serializedConfig);
      });
    }
    invoke(config) {
      return __awaiter(this, undefined, undefined, function* () {
        const serializedConfig = JSON.stringify(config, types_1.ReplacerFunc);
        if (new TextEncoder().encode(serializedConfig).length > messageLimit) {
          (0, errors_1.throwError)(`message size exceeds the limit of ${messageLimit} bytes, please contact 1Password at support@1password.com or https://developer.1password.com/joinslack if you need help."`);
        }
        return this.inner.invoke(serializedConfig);
      });
    }
    invoke_sync(config) {
      const serializedConfig = JSON.stringify(config, types_1.ReplacerFunc);
      if (new TextEncoder().encode(serializedConfig).length > messageLimit) {
        (0, errors_1.throwError)(`message size exceeds the limit of ${messageLimit} bytes, please contact 1Password at support@1password.com or https://developer.1password.com/joinslack if you need help.`);
      }
      return (0, sdk_core_1.invoke_sync)(serializedConfig);
    }
    releaseClient(clientId) {
      const serializedId = JSON.stringify(clientId);
      this.inner.releaseClient(serializedId);
    }
  }
  exports.SharedCore = SharedCore;

  class InnerClient {
    constructor(id, core, config) {
      this.id = id;
      this.core = core;
      this.config = config;
    }
    invoke(config) {
      return __awaiter(this, undefined, undefined, function* () {
        try {
          return yield this.core.invoke(config);
        } catch (err) {
          if (err instanceof errors_1.DesktopSessionExpiredError) {
            const newId = yield this.core.initClient(this.config);
            this.id = parseInt(newId, 10);
            config.invocation.clientId = this.id;
            return yield this.core.invoke(config);
          }
          throw err;
        }
      });
    }
  }
  exports.InnerClient = InnerClient;
});

// node_modules/@1password/sdk/dist/version.js
var require_version = __commonJS((exports) => {
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.SDK_BUILD_NUMBER = exports.SDK_VERSION = undefined;
  exports.SDK_VERSION = "0.4.0";
  exports.SDK_BUILD_NUMBER = "0040003";
});

// node_modules/@1password/sdk/dist/configuration.js
var require_configuration = __commonJS((exports) => {
  var __importDefault = exports && exports.__importDefault || function(mod) {
    return mod && mod.__esModule ? mod : { default: mod };
  };
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.getOsName = exports.clientAuthConfig = exports.DesktopAuth = exports.VERSION = exports.LANGUAGE = undefined;
  var os_1 = __importDefault(__require("os"));
  var version_js_1 = require_version();
  exports.LANGUAGE = "JS";
  exports.VERSION = version_js_1.SDK_BUILD_NUMBER;

  class DesktopAuth {
    constructor(accountName) {
      this.accountName = accountName;
    }
  }
  exports.DesktopAuth = DesktopAuth;
  var clientAuthConfig = (userConfig) => {
    const defaultOsVersion = "0.0.0";
    let serviceAccountToken;
    let accountName;
    if (typeof userConfig.auth === "string") {
      serviceAccountToken = userConfig.auth;
    } else if (userConfig.auth instanceof DesktopAuth) {
      accountName = userConfig.auth.accountName;
    }
    return {
      serviceAccountToken: serviceAccountToken !== null && serviceAccountToken !== undefined ? serviceAccountToken : "",
      accountName,
      programmingLanguage: exports.LANGUAGE,
      sdkVersion: exports.VERSION,
      integrationName: userConfig.integrationName,
      integrationVersion: userConfig.integrationVersion,
      requestLibraryName: "Fetch API",
      requestLibraryVersion: "Fetch API",
      os: (0, exports.getOsName)(),
      osVersion: defaultOsVersion,
      architecture: os_1.default.arch()
    };
  };
  exports.clientAuthConfig = clientAuthConfig;
  var getOsName = () => {
    const os_name = os_1.default.type().toLowerCase();
    if (os_name === "windows_nt") {
      return "windows";
    }
    return os_name;
  };
  exports.getOsName = getOsName;
});

// node_modules/@1password/sdk/dist/secrets.js
var require_secrets = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  var __classPrivateFieldSet = exports && exports.__classPrivateFieldSet || function(receiver, state, value, kind, f) {
    if (kind === "m")
      throw new TypeError("Private method is not writable");
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value), value;
  };
  var __classPrivateFieldGet = exports && exports.__classPrivateFieldGet || function(receiver, state, kind, f) {
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
  };
  var _Secrets_inner;
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.Secrets = undefined;
  var core_js_1 = require_core2();
  var types_js_1 = require_types();

  class Secrets {
    constructor(inner) {
      _Secrets_inner.set(this, undefined);
      __classPrivateFieldSet(this, _Secrets_inner, inner, "f");
    }
    resolve(secretReference) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Secrets_inner, "f").id,
            parameters: {
              name: "SecretsResolve",
              parameters: {
                secret_reference: secretReference
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Secrets_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    resolveAll(secretReferences) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Secrets_inner, "f").id,
            parameters: {
              name: "SecretsResolveAll",
              parameters: {
                secret_references: secretReferences
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Secrets_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    static validateSecretReference(secretReference) {
      const sharedCore = new core_js_1.SharedCore;
      const invocationConfig = {
        invocation: {
          parameters: {
            name: "ValidateSecretReference",
            parameters: {
              secret_reference: secretReference
            }
          }
        }
      };
      sharedCore.invoke_sync(invocationConfig);
    }
    static generatePassword(recipe) {
      const sharedCore = new core_js_1.SharedCore;
      const invocationConfig = {
        invocation: {
          parameters: {
            name: "GeneratePassword",
            parameters: {
              recipe
            }
          }
        }
      };
      return JSON.parse(sharedCore.invoke_sync(invocationConfig), types_js_1.ReviverFunc);
    }
  }
  exports.Secrets = Secrets;
  _Secrets_inner = new WeakMap;
});

// node_modules/@1password/sdk/dist/items_shares.js
var require_items_shares = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  var __classPrivateFieldSet = exports && exports.__classPrivateFieldSet || function(receiver, state, value, kind, f) {
    if (kind === "m")
      throw new TypeError("Private method is not writable");
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value), value;
  };
  var __classPrivateFieldGet = exports && exports.__classPrivateFieldGet || function(receiver, state, kind, f) {
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
  };
  var _ItemsShares_inner;
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.ItemsShares = undefined;
  var types_js_1 = require_types();

  class ItemsShares {
    constructor(inner) {
      _ItemsShares_inner.set(this, undefined);
      __classPrivateFieldSet(this, _ItemsShares_inner, inner, "f");
    }
    getAccountPolicy(vaultId, itemId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _ItemsShares_inner, "f").id,
            parameters: {
              name: "ItemsSharesGetAccountPolicy",
              parameters: {
                vault_id: vaultId,
                item_id: itemId
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _ItemsShares_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    validateRecipients(policy, recipients) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _ItemsShares_inner, "f").id,
            parameters: {
              name: "ItemsSharesValidateRecipients",
              parameters: {
                policy,
                recipients
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _ItemsShares_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    create(item, policy, params) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _ItemsShares_inner, "f").id,
            parameters: {
              name: "ItemsSharesCreate",
              parameters: {
                item,
                policy,
                params
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _ItemsShares_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
  }
  exports.ItemsShares = ItemsShares;
  _ItemsShares_inner = new WeakMap;
});

// node_modules/@1password/sdk/dist/items_files.js
var require_items_files = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  var __classPrivateFieldSet = exports && exports.__classPrivateFieldSet || function(receiver, state, value, kind, f) {
    if (kind === "m")
      throw new TypeError("Private method is not writable");
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value), value;
  };
  var __classPrivateFieldGet = exports && exports.__classPrivateFieldGet || function(receiver, state, kind, f) {
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
  };
  var _ItemsFiles_inner;
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.ItemsFiles = undefined;
  var types_js_1 = require_types();

  class ItemsFiles {
    constructor(inner) {
      _ItemsFiles_inner.set(this, undefined);
      __classPrivateFieldSet(this, _ItemsFiles_inner, inner, "f");
    }
    attach(item, fileParams) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _ItemsFiles_inner, "f").id,
            parameters: {
              name: "ItemsFilesAttach",
              parameters: {
                item,
                file_params: fileParams
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _ItemsFiles_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    read(vaultId, itemId, attr) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _ItemsFiles_inner, "f").id,
            parameters: {
              name: "ItemsFilesRead",
              parameters: {
                vault_id: vaultId,
                item_id: itemId,
                attr
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _ItemsFiles_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    delete(item, sectionId, fieldId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _ItemsFiles_inner, "f").id,
            parameters: {
              name: "ItemsFilesDelete",
              parameters: {
                item,
                section_id: sectionId,
                field_id: fieldId
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _ItemsFiles_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    replaceDocument(item, docParams) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _ItemsFiles_inner, "f").id,
            parameters: {
              name: "ItemsFilesReplaceDocument",
              parameters: {
                item,
                doc_params: docParams
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _ItemsFiles_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
  }
  exports.ItemsFiles = ItemsFiles;
  _ItemsFiles_inner = new WeakMap;
});

// node_modules/@1password/sdk/dist/items.js
var require_items = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  var __classPrivateFieldSet = exports && exports.__classPrivateFieldSet || function(receiver, state, value, kind, f) {
    if (kind === "m")
      throw new TypeError("Private method is not writable");
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value), value;
  };
  var __classPrivateFieldGet = exports && exports.__classPrivateFieldGet || function(receiver, state, kind, f) {
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
  };
  var _Items_inner;
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.Items = undefined;
  var types_js_1 = require_types();
  var items_shares_js_1 = require_items_shares();
  var items_files_js_1 = require_items_files();

  class Items {
    constructor(inner) {
      _Items_inner.set(this, undefined);
      __classPrivateFieldSet(this, _Items_inner, inner, "f");
      this.shares = new items_shares_js_1.ItemsShares(inner);
      this.files = new items_files_js_1.ItemsFiles(inner);
    }
    create(params) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsCreate",
              parameters: {
                params
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    createAll(vaultId, params) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsCreateAll",
              parameters: {
                vault_id: vaultId,
                params
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    get(vaultId, itemId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsGet",
              parameters: {
                vault_id: vaultId,
                item_id: itemId
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    getAll(vaultId, itemIds) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsGetAll",
              parameters: {
                vault_id: vaultId,
                item_ids: itemIds
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    put(item) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsPut",
              parameters: {
                item
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    delete(vaultId, itemId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsDelete",
              parameters: {
                vault_id: vaultId,
                item_id: itemId
              }
            }
          }
        };
        yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig);
      });
    }
    deleteAll(vaultId, itemIds) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsDeleteAll",
              parameters: {
                vault_id: vaultId,
                item_ids: itemIds
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    archive(vaultId, itemId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsArchive",
              parameters: {
                vault_id: vaultId,
                item_id: itemId
              }
            }
          }
        };
        yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig);
      });
    }
    list(vaultId, ...filters) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Items_inner, "f").id,
            parameters: {
              name: "ItemsList",
              parameters: {
                vault_id: vaultId,
                filters
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Items_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
  }
  exports.Items = Items;
  _Items_inner = new WeakMap;
});

// node_modules/@1password/sdk/dist/vaults.js
var require_vaults = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  var __classPrivateFieldSet = exports && exports.__classPrivateFieldSet || function(receiver, state, value, kind, f) {
    if (kind === "m")
      throw new TypeError("Private method is not writable");
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value), value;
  };
  var __classPrivateFieldGet = exports && exports.__classPrivateFieldGet || function(receiver, state, kind, f) {
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
  };
  var _Vaults_inner;
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.Vaults = undefined;
  var types_js_1 = require_types();

  class Vaults {
    constructor(inner) {
      _Vaults_inner.set(this, undefined);
      __classPrivateFieldSet(this, _Vaults_inner, inner, "f");
    }
    create(params) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsCreate",
              parameters: {
                params
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    list(params) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsList",
              parameters: {
                params
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    getOverview(vaultId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsGetOverview",
              parameters: {
                vault_id: vaultId
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    get(vaultId, vaultParams) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsGet",
              parameters: {
                vault_id: vaultId,
                vault_params: vaultParams
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    update(vaultId, params) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsUpdate",
              parameters: {
                vault_id: vaultId,
                params
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
    delete(vaultId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsDelete",
              parameters: {
                vault_id: vaultId
              }
            }
          }
        };
        yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig);
      });
    }
    grantGroupPermissions(vaultId, groupPermissionsList) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsGrantGroupPermissions",
              parameters: {
                vault_id: vaultId,
                group_permissions_list: groupPermissionsList
              }
            }
          }
        };
        yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig);
      });
    }
    updateGroupPermissions(groupPermissionsList) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsUpdateGroupPermissions",
              parameters: {
                group_permissions_list: groupPermissionsList
              }
            }
          }
        };
        yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig);
      });
    }
    revokeGroupPermissions(vaultId, groupId) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Vaults_inner, "f").id,
            parameters: {
              name: "VaultsRevokeGroupPermissions",
              parameters: {
                vault_id: vaultId,
                group_id: groupId
              }
            }
          }
        };
        yield __classPrivateFieldGet(this, _Vaults_inner, "f").invoke(invocationConfig);
      });
    }
  }
  exports.Vaults = Vaults;
  _Vaults_inner = new WeakMap;
});

// node_modules/@1password/sdk/dist/groups.js
var require_groups = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  var __classPrivateFieldSet = exports && exports.__classPrivateFieldSet || function(receiver, state, value, kind, f) {
    if (kind === "m")
      throw new TypeError("Private method is not writable");
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value), value;
  };
  var __classPrivateFieldGet = exports && exports.__classPrivateFieldGet || function(receiver, state, kind, f) {
    if (kind === "a" && !f)
      throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver))
      throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
  };
  var _Groups_inner;
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.Groups = undefined;
  var types_js_1 = require_types();

  class Groups {
    constructor(inner) {
      _Groups_inner.set(this, undefined);
      __classPrivateFieldSet(this, _Groups_inner, inner, "f");
    }
    get(groupId, groupParams) {
      return __awaiter(this, undefined, undefined, function* () {
        const invocationConfig = {
          invocation: {
            clientId: __classPrivateFieldGet(this, _Groups_inner, "f").id,
            parameters: {
              name: "GroupsGet",
              parameters: {
                group_id: groupId,
                group_params: groupParams
              }
            }
          }
        };
        return JSON.parse(yield __classPrivateFieldGet(this, _Groups_inner, "f").invoke(invocationConfig), types_js_1.ReviverFunc);
      });
    }
  }
  exports.Groups = Groups;
  _Groups_inner = new WeakMap;
});

// node_modules/@1password/sdk/dist/client.js
var require_client = __commonJS((exports) => {
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.Client = undefined;
  var secrets_js_1 = require_secrets();
  var items_js_1 = require_items();
  var vaults_js_1 = require_vaults();
  var groups_js_1 = require_groups();

  class Client {
    constructor(innerClient) {
      this.secrets = new secrets_js_1.Secrets(innerClient);
      this.items = new items_js_1.Items(innerClient);
      this.vaults = new vaults_js_1.Vaults(innerClient);
      this.groups = new groups_js_1.Groups(innerClient);
    }
  }
  exports.Client = Client;
});

// node_modules/@1password/sdk/dist/shared_lib_core.js
var require_shared_lib_core = __commonJS((exports) => {
  var __createBinding = exports && exports.__createBinding || (Object.create ? function(o, m, k, k2) {
    if (k2 === undefined)
      k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() {
        return m[k];
      } };
    }
    Object.defineProperty(o, k2, desc);
  } : function(o, m, k, k2) {
    if (k2 === undefined)
      k2 = k;
    o[k2] = m[k];
  });
  var __setModuleDefault = exports && exports.__setModuleDefault || (Object.create ? function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
  } : function(o, v) {
    o["default"] = v;
  });
  var __importStar = exports && exports.__importStar || function() {
    var ownKeys = function(o) {
      ownKeys = Object.getOwnPropertyNames || function(o2) {
        var ar = [];
        for (var k in o2)
          if (Object.prototype.hasOwnProperty.call(o2, k))
            ar[ar.length] = k;
        return ar;
      };
      return ownKeys(o);
    };
    return function(mod) {
      if (mod && mod.__esModule)
        return mod;
      var result = {};
      if (mod != null) {
        for (var k = ownKeys(mod), i = 0;i < k.length; i++)
          if (k[i] !== "default")
            __createBinding(result, mod, k[i]);
      }
      __setModuleDefault(result, mod);
      return result;
    };
  }();
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.SharedLibCore = undefined;
  var fs = __importStar(__require("fs"));
  var os = __importStar(__require("os"));
  var path = __importStar(__require("path"));
  var errors_1 = require_errors();
  var find1PasswordLibPath = () => {
    const platform = os.platform();
    const appRoot = path.dirname(process.execPath);
    let searchPaths = [];
    switch (platform) {
      case "darwin":
        searchPaths = [
          "/Applications/1Password.app/Contents/Frameworks/libop_sdk_ipc_client.dylib",
          path.join(os.homedir(), "/Applications/1Password.app/Contents/Frameworks/libop_sdk_ipc_client.dylib")
        ];
        break;
      case "linux":
        searchPaths = [
          "/usr/bin/1password/libop_sdk_ipc_client.so",
          "/opt/1Password/libop_sdk_ipc_client.so",
          "/snap/bin/1password/libop_sdk_ipc_client.so"
        ];
        break;
      case "win32":
        searchPaths = [
          path.join(os.homedir(), "/AppData/Local/1Password/op_sdk_ipc_client.dll"),
          "C:/Program Files/1Password/app/8/op_sdk_ipc_client.dll",
          "C:/Program Files (x86)/1Password/app/8/op_sdk_ipc_client.dll",
          path.join(os.homedir(), "/AppData/Local/1Password/app/8/op_sdk_ipc_client.dll")
        ];
        break;
      default:
        throw new Error(`Unsupported platform: ${platform}`);
    }
    for (const addonPath of searchPaths) {
      if (fs.existsSync(addonPath)) {
        return addonPath;
      }
    }
    throw new Error("1Password desktop application not found");
  };

  class SharedLibCore {
    constructor(accountName) {
      this.lib = null;
      try {
        const libPath = find1PasswordLibPath();
        const moduleStub = { exports: {} };
        process.dlopen(moduleStub, libPath);
        if (typeof moduleStub === "object" && moduleStub !== null && typeof moduleStub.exports === "object" && moduleStub.exports !== null && "sendMessage" in moduleStub.exports && typeof moduleStub.exports.sendMessage === "function") {
          this.lib = moduleStub.exports;
        } else {
          throw new Error("Failed to initialize native library: sendMessage function not found on module.");
        }
      } catch (e) {
        console.error("A critical error occurred while loading the native addon:", e);
        this.lib = null;
      }
      this.acccountName = accountName;
    }
    callSharedLibrary(input, operation_type) {
      return __awaiter(this, undefined, undefined, function* () {
        if (!this.lib) {
          throw new Error("Native library is not available.");
        }
        if (!input || input.length === 0) {
          throw new Error("internal: empty input");
        }
        const inputEncoded = Buffer.from(input, "utf8").toString("base64");
        const req = {
          account_name: this.acccountName,
          kind: operation_type,
          payload: inputEncoded
        };
        const inputBuf = Buffer.from(JSON.stringify(req), "utf8");
        const nativeResponse = yield this.lib.sendMessage(inputBuf);
        if (!(nativeResponse instanceof Uint8Array)) {
          throw new Error(`Native function returned an unexpected type. Expected Uint8Array, got ${typeof nativeResponse}`);
        }
        const respString = new TextDecoder().decode(nativeResponse);
        const response = JSON.parse(respString);
        if (response.success) {
          const decodedPayload = Buffer.from(response.payload).toString("utf8");
          return decodedPayload;
        } else {
          const errorMessage = Array.isArray(response.payload) ? String.fromCharCode(...response.payload) : JSON.stringify(response.payload);
          (0, errors_1.throwError)(errorMessage);
        }
      });
    }
    initClient(config) {
      return __awaiter(this, undefined, undefined, function* () {
        return this.callSharedLibrary(config, "init_client");
      });
    }
    invoke(invokeConfigBytes) {
      return __awaiter(this, undefined, undefined, function* () {
        return this.callSharedLibrary(invokeConfigBytes, "invoke");
      });
    }
    releaseClient(clientId) {
      this.callSharedLibrary(clientId, "release_client").catch((err) => {
        console.warn("failed to release client:", err);
      });
    }
  }
  exports.SharedLibCore = SharedLibCore;
});

// node_modules/@1password/sdk/dist/client_builder.js
var require_client_builder = __commonJS((exports) => {
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.createClientWithCore = undefined;
  var core_js_1 = require_core2();
  var configuration_js_1 = require_configuration();
  var client_js_1 = require_client();
  var shared_lib_core_js_1 = require_shared_lib_core();
  var finalizationRegistry = new FinalizationRegistry((heldClient) => {
    heldClient.core.releaseClient(heldClient.id);
  });
  var createClientWithCore = (config, core) => __awaiter(undefined, undefined, undefined, function* () {
    const authConfig = (0, configuration_js_1.clientAuthConfig)(config);
    if (authConfig.accountName) {
      core.setInner(new shared_lib_core_js_1.SharedLibCore(authConfig.accountName));
    }
    const clientId = yield core.initClient(authConfig);
    const inner = new core_js_1.InnerClient(parseInt(clientId, 10), core, authConfig);
    const client = new client_js_1.Client(inner);
    finalizationRegistry.register(client, inner);
    return client;
  });
  exports.createClientWithCore = createClientWithCore;
});

// node_modules/@1password/sdk/dist/sdk.js
var require_sdk = __commonJS((exports) => {
  var __createBinding = exports && exports.__createBinding || (Object.create ? function(o, m, k, k2) {
    if (k2 === undefined)
      k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() {
        return m[k];
      } };
    }
    Object.defineProperty(o, k2, desc);
  } : function(o, m, k, k2) {
    if (k2 === undefined)
      k2 = k;
    o[k2] = m[k];
  });
  var __exportStar = exports && exports.__exportStar || function(m, exports2) {
    for (var p in m)
      if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports2, p))
        __createBinding(exports2, m, p);
  };
  var __awaiter = exports && exports.__awaiter || function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
  Object.defineProperty(exports, "__esModule", { value: true });
  exports.createClient = exports.DesktopAuth = exports.Secrets = exports.DEFAULT_INTEGRATION_VERSION = exports.DEFAULT_INTEGRATION_NAME = undefined;
  var core_js_1 = require_core2();
  var client_builder_js_1 = require_client_builder();
  exports.DEFAULT_INTEGRATION_NAME = "Unknown";
  exports.DEFAULT_INTEGRATION_VERSION = "Unknown";
  var secrets_js_1 = require_secrets();
  Object.defineProperty(exports, "Secrets", { enumerable: true, get: function() {
    return secrets_js_1.Secrets;
  } });
  var configuration_js_1 = require_configuration();
  Object.defineProperty(exports, "DesktopAuth", { enumerable: true, get: function() {
    return configuration_js_1.DesktopAuth;
  } });
  __exportStar(require_client(), exports);
  __exportStar(require_errors(), exports);
  __exportStar(require_types(), exports);
  var createClient = (config) => __awaiter(undefined, undefined, undefined, function* () {
    return (0, client_builder_js_1.createClientWithCore)(config, new core_js_1.SharedCore);
  });
  exports.createClient = createClient;
});

// index.ts
var import_sdk = __toESM(require_sdk(), 1);
var {$ } = globalThis.Bun;
var VAULT_ID = "q63632lctm4by3clskcul4gmf4";
var TAG = "MagicBox Postgres";
if (!process.env.OP_SERVICE_ACCOUNT_TOKEN)
  throw "No 1Password auth provided";
var client = await import_sdk.default.createClient({
  auth: process.env.OP_SERVICE_ACCOUNT_TOKEN,
  integrationName: "Postgres Puppy",
  integrationVersion: "v1.0.0"
});
function generateNewPassword() {
  return import_sdk.default.Secrets.generatePassword({
    type: "Random",
    parameters: {
      includeDigits: true,
      includeSymbols: true,
      length: 20
    }
  }).password;
}
if (!Bun.argv[2])
  throw "No input parameter provided";
var input = JSON.parse(Bun.argv[2]);
var postgresItemOverviews = (await client.items.list(VAULT_ID)).filter((item) => item.category === "Database" && item.tags.includes(TAG));
var postgresItems = await Promise.all(postgresItemOverviews.map((overview) => client.items.get(overview.vaultId, overview.id)));
for (let postgresDatabase of input) {
  let item = postgresItems.find((postgresItem) => postgresItem.fields.find((field) => field.id === "database" && field.value === postgresDatabase.name));
  if (!item) {
    item = await client.items.create({
      title: postgresDatabase.name + " Postgres",
      vaultId: VAULT_ID,
      category: import_sdk.default.ItemCategory.Database,
      tags: [TAG],
      fields: [
        {
          id: "database_type",
          title: "type",
          fieldType: import_sdk.default.ItemFieldType.Text,
          value: "postgresql"
        },
        {
          id: "database",
          title: "database",
          fieldType: import_sdk.default.ItemFieldType.Text,
          value: postgresDatabase.name
        },
        {
          id: "username",
          title: "username",
          fieldType: import_sdk.default.ItemFieldType.Text,
          value: postgresDatabase.name
        },
        {
          id: "password",
          title: "password",
          fieldType: import_sdk.default.ItemFieldType.Concealed,
          value: generateNewPassword()
        }
      ]
    });
  }
  let databasePassword = item.fields.find((field) => field.id === "password")?.value;
  if (!databasePassword) {
    databasePassword = generateNewPassword();
    const updatedItem = { ...item, fields: [...item.fields, {
      id: "password",
      title: "password",
      fieldType: import_sdk.default.ItemFieldType.Concealed,
      value: generateNewPassword()
    }] };
    await client.items.put(updatedItem);
  }
  console.log(`Creating database ${postgresDatabase.name} if it doesn't exist`);
  await $`docker exec -i postgres psql -U postgres <<SQL
		CREATE USER IF NOT EXISTS ${postgresDatabase.name};
		ALTER USER ${postgresDatabase.name} WITH PASSWORD '${databasePassword}';
		SELECT 'CREATE DATABASE ${postgresDatabase.name} OWNER ${postgresDatabase.name}'
            WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${postgresDatabase.name}')\\gexec
	SQL`;
}
console.log("All Postgres databases updated");

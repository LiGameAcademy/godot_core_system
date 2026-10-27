#include <windows.h>
#include <stdlib.h>
#include <stdint.h>
#include <wchar.h>
#include "vendor/gdextension_interface.h"

/* Godot String and StringName are pointer-sized on the supported Windows x64 ABI. */
typedef union { void *alignment; unsigned char bytes[8]; } GodotString;
typedef enum { RESULT_OK = 0, RESULT_FAILED = 1, RESULT_UNAVAILABLE = 2,
    RESULT_OUT_OF_MEMORY = 6, RESULT_NOT_FOUND = 7, RESULT_PERMISSION = 10,
    RESULT_IN_USE = 11, RESULT_BAD_PARAMETER = 31 } Result;

static GDExtensionClassLibraryPtr library;
static GDExtensionInterfaceGetProcAddress get_proc;
static GDExtensionInterfaceStringToUtf16Chars to_utf16;
static GDExtensionInterfaceVariantGetType variant_type;
static GDExtensionTypeFromVariantConstructorFunc from_variant;
static GDExtensionVariantFromTypeConstructorFunc to_variant;
static GDExtensionPtrDestructor destroy_string;
static GDExtensionPtrDestructor destroy_name;
static GodotString class_name;

static int windows_error(DWORD error) {
    switch (error) {
        case ERROR_FILE_NOT_FOUND: case ERROR_PATH_NOT_FOUND: return RESULT_NOT_FOUND;
        case ERROR_ACCESS_DENIED: return RESULT_PERMISSION;
        case ERROR_SHARING_VIOLATION: case ERROR_LOCK_VIOLATION: return RESULT_IN_USE;
        case ERROR_NOT_ENOUGH_MEMORY: case ERROR_OUTOFMEMORY: return RESULT_OUT_OF_MEMORY;
        default: return RESULT_FAILED;
    }
}

static wchar_t *path_from_string(const void *string) {
    GDExtensionInt length = to_utf16(string, NULL, 0);
    if (length <= 0 || length > 32760) return NULL;
    wchar_t *path = calloc((size_t)length + 1, sizeof(wchar_t));
    if (!path) return NULL;
    to_utf16(string, (char16_t *)path, length);
    for (GDExtensionInt i = 0; i < length; ++i) {
        if (!path[i]) { free(path); return NULL; }
    }
    int drive = length > 2 && path[1] == L':' && (path[2] == L'\\' || path[2] == L'/');
    int unc = length > 3 && path[0] == L'\\' && path[1] == L'\\';
    if ((!drive && !unc) || wcsncmp(path, L"\\\\.\\", 4) == 0) { free(path); return NULL; }
    DWORD needed = GetFullPathNameW(path, 0, NULL, NULL);
    if (!needed || needed > 32760) { free(path); return NULL; }
    wchar_t *full = calloc(needed, sizeof(wchar_t));
    if (!full) { free(path); return NULL; }
    DWORD written = GetFullPathNameW(path, needed, full, NULL);
    free(path);
    if (!written || written >= needed) { free(full); return NULL; }
    return full;
}

static int replace_paths(const void *from, const void *to) {
    wchar_t *source = path_from_string(from);
    wchar_t *target = path_from_string(to);
    int result = RESULT_BAD_PARAMETER;
    if (!source || !target) goto done;
    wchar_t *source_leaf = wcsrchr(source, L'\\');
    wchar_t *target_leaf = wcsrchr(target, L'\\');
    if (!source_leaf || !target_leaf || !source_leaf[1] || !target_leaf[1]) goto done;
    size_t source_directory = (size_t)(source_leaf - source);
    size_t target_directory = (size_t)(target_leaf - target);
    if (source_directory != target_directory || _wcsnicmp(source, target, source_directory) != 0 || _wcsicmp(source, target) == 0) goto done;
    DWORD attributes = GetFileAttributesW(source);
    if (attributes == INVALID_FILE_ATTRIBUTES) { result = windows_error(GetLastError()); goto done; }
    if (attributes & (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT)) goto done;
    attributes = GetFileAttributesW(target);
    if (attributes != INVALID_FILE_ATTRIBUTES && (attributes & (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT))) goto done;
    HANDLE file = CreateFileW(source, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) { result = windows_error(GetLastError()); goto done; }
    BOOL flushed = FlushFileBuffers(file);
    DWORD flush_error = flushed ? ERROR_SUCCESS : GetLastError();
    CloseHandle(file);
    if (!flushed) { result = windows_error(flush_error); goto done; }
    /* No delete-before-move and no cross-volume copy fallback. */
    if (MoveFileExW(source, target, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) result = RESULT_OK;
    else result = windows_error(GetLastError());
done:
    free(source);
    free(target);
    return result;
}

static void call_replace(void *userdata, GDExtensionClassInstancePtr instance,
    const GDExtensionConstVariantPtr *args, GDExtensionInt count,
    GDExtensionVariantPtr result, GDExtensionCallError *error) {
    (void)userdata; (void)instance;
    int64_t code = RESULT_BAD_PARAMETER;
    error->error = GDEXTENSION_CALL_OK;
    if (count != 2) {
        error->error = count < 2 ? GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS : GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
        error->expected = 2;
    } else {
        for (int i = 0; i < 2; ++i) {
            if (variant_type(args[i]) != GDEXTENSION_VARIANT_TYPE_STRING) {
                error->error = GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;
                error->argument = i;
                error->expected = GDEXTENSION_VARIANT_TYPE_STRING;
                to_variant(result, &code);
                return;
            }
        }
        GodotString source, target;
        from_variant(&source, (GDExtensionVariantPtr)args[0]);
        from_variant(&target, (GDExtensionVariantPtr)args[1]);
        code = replace_paths(&source, &target);
        destroy_string(&source);
        destroy_string(&target);
    }
    to_variant(result, &code);
}

static void ptrcall_replace(void *userdata, GDExtensionClassInstancePtr instance,
    const GDExtensionConstTypePtr *args, GDExtensionTypePtr result) {
    (void)userdata; (void)instance;
    *(int64_t *)result = replace_paths(args[0], args[1]);
}

static void free_instance(void *userdata, GDExtensionClassInstancePtr instance) {
    (void)userdata; (void)instance;
}

static void initialize(void *userdata, GDExtensionInitializationLevel level) {
    (void)userdata;
    if (level != GDEXTENSION_INITIALIZATION_SCENE) return;
    GDExtensionInterfaceStringNameNewWithUtf8Chars new_name = (GDExtensionInterfaceStringNameNewWithUtf8Chars)get_proc("string_name_new_with_utf8_chars");
    GDExtensionInterfaceStringNewWithUtf8Chars new_string = (GDExtensionInterfaceStringNewWithUtf8Chars)get_proc("string_new_with_utf8_chars");
    GDExtensionInterfaceClassdbRegisterExtensionClass6 register_class = (GDExtensionInterfaceClassdbRegisterExtensionClass6)get_proc("classdb_register_extension_class6");
    GDExtensionInterfaceClassdbRegisterExtensionClassMethod register_method = (GDExtensionInterfaceClassdbRegisterExtensionClassMethod)get_proc("classdb_register_extension_class_method");
    GodotString parent, method_name, empty_name, empty_string, source_name, target_name;
    new_name(&class_name, "CoreAtomicFile"); new_name(&parent, "Object");
    new_name(&method_name, "replace"); new_name(&empty_name, "");
    new_name(&source_name, "source"); new_name(&target_name, "target");
    new_string(&empty_string, "");
    GDExtensionClassCreationInfo6 info = {0};
    info.is_abstract = 1; info.is_exposed = 1; info.free_instance_func = free_instance;
    register_class(library, &class_name, &parent, &info);
    GDExtensionPropertyInfo returned = {GDEXTENSION_VARIANT_TYPE_INT, &empty_name, &empty_name, 0, &empty_string, 6};
    GDExtensionPropertyInfo arguments[2] = {
        {GDEXTENSION_VARIANT_TYPE_STRING, &source_name, &empty_name, 0, &empty_string, 6},
        {GDEXTENSION_VARIANT_TYPE_STRING, &target_name, &empty_name, 0, &empty_string, 6}
    };
    GDExtensionClassMethodArgumentMetadata metadata[2] = {0, 0};
    GDExtensionClassMethodInfo method = {0};
    method.name = &method_name; method.call_func = call_replace; method.ptrcall_func = ptrcall_replace;
    method.method_flags = GDEXTENSION_METHOD_FLAG_NORMAL | GDEXTENSION_METHOD_FLAG_STATIC;
    method.has_return_value = 1; method.return_value_info = &returned;
    method.return_value_metadata = GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT64;
    method.argument_count = 2; method.arguments_info = arguments; method.arguments_metadata = metadata;
    register_method(library, &class_name, &method);
    destroy_name(&parent); destroy_name(&method_name); destroy_name(&empty_name);
    destroy_name(&source_name); destroy_name(&target_name); destroy_string(&empty_string);
}

static void deinitialize(void *userdata, GDExtensionInitializationLevel level) {
    (void)userdata;
    if (level != GDEXTENSION_INITIALIZATION_SCENE) return;
    GDExtensionInterfaceClassdbUnregisterExtensionClass unregister_class = (GDExtensionInterfaceClassdbUnregisterExtensionClass)get_proc("classdb_unregister_extension_class");
    unregister_class(library, &class_name);
    destroy_name(&class_name);
}

__declspec(dllexport) GDExtensionBool core_atomic_file_init(
    GDExtensionInterfaceGetProcAddress get_address, GDExtensionClassLibraryPtr class_library,
    GDExtensionInitialization *initialization) {
    if (sizeof(void *) != 8) return 0;
    get_proc = get_address; library = class_library;
    if (!get_proc("classdb_register_extension_class6")) return 0;
    to_utf16 = (GDExtensionInterfaceStringToUtf16Chars)get_proc("string_to_utf16_chars");
    variant_type = (GDExtensionInterfaceVariantGetType)get_proc("variant_get_type");
    GDExtensionInterfaceGetVariantToTypeConstructor get_to = (GDExtensionInterfaceGetVariantToTypeConstructor)get_proc("get_variant_to_type_constructor");
    GDExtensionInterfaceGetVariantFromTypeConstructor get_from = (GDExtensionInterfaceGetVariantFromTypeConstructor)get_proc("get_variant_from_type_constructor");
    GDExtensionInterfaceVariantGetPtrDestructor get_destructor = (GDExtensionInterfaceVariantGetPtrDestructor)get_proc("variant_get_ptr_destructor");
    from_variant = get_to(GDEXTENSION_VARIANT_TYPE_STRING);
    to_variant = get_from(GDEXTENSION_VARIANT_TYPE_INT);
    destroy_string = get_destructor(GDEXTENSION_VARIANT_TYPE_STRING);
    destroy_name = get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME);
    initialization->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
    initialization->initialize = initialize; initialization->deinitialize = deinitialize;
    initialization->userdata = NULL;
    return 1;
}

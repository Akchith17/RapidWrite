// Native IO implementation stub: localStorage not available on native
// Falls back to null — the caller (ProfileStorageService) handles file I/O on non-web

String? localStorageGet(String key) => null;

void localStorageSet(String key, String value) {}

void localStorageRemove(String key) {}


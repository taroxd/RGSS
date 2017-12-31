
#include <Windows.h>
int main(int argc, char *argv[]) {
    HINSTANCE hDllInst = LoadLibrary(L"msvcrt-ruby220.dll");

    typedef int(*rb_init)();
    typedef int(*rb_eval_string_protect)(const char*, int*);
    typedef int(*rb_finalize)();
    rb_init ruby_init = (rb_init)GetProcAddress(hDllInst, "ruby_init");
    rb_eval_string_protect ruby_eval_string_protect = (rb_eval_string_protect)GetProcAddress(hDllInst, "rb_eval_string_protect");
    rb_finalize ruby_finalize = (rb_finalize)GetProcAddress(hDllInst, "ruby_finalize");

    ruby_init();
    ruby_eval_string_protect(argv[1], NULL);
    ruby_finalize();

    FreeLibrary(hDllInst);
}
#include <alloca.h>

int bar(int n)
{
    int x = 4;
    // int array[n];
    // unsigned char* b = (unsigned char*)alloca(n);

    return x;
}

int foo()
{
    int a[64];
    return /* foo() + */ bar(9001) + a[0];
}

int foobar()
{
    int b[8];
    return foo() + bar(8024) + b[0];
}

int dynamic(void)
{
    return foo();
}

int external_symbol(void);
int foo2(void)
{
    int x[128];
    return x[0] + external_symbol();
}


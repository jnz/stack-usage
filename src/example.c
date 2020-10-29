int bar()
{
    int x = 4;
    return x;
}

int foo()
{
    int a[64];
    return /* foo() + */ bar() + a[0];
}

int foobar()
{
    int b[8];
    return foo() + bar() + b[0];
}

int main(void)
{
    return foo();
}

int external_symbol(void);
int foo2(void)
{
    int x[128];
    return x[0] + external_symbol();
}


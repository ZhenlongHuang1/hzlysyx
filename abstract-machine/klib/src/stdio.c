#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <stdio.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
int intcatstr(char *str,int num);
int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
    char *ptr=(char *)fmt;
    int num=0,tmp;
    char *string;
    va_list ap;
    va_start(ap,fmt);
    while(*ptr){
        switch (*ptr) {
            case '%':{
                ptr++;
                switch (*ptr) {
                    case 'd':tmp=va_arg(ap,int);
                             num+=intcatstr(out+num,tmp);
                             break;
                    case 's':string=va_arg(ap,char*);
                             strcat(out+num,string);
                             num+=strlen(string);
                             break;
                    case '%':out[num++]='%';
                    default:assert(0);
                
                }
            }break;
            default:out[num++]=*(ptr);break;
        }
        ptr++;
    }
    out[num++]='\0';
    va_end(ap);
    return num;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}
int intcatstr(char *str,int num){
    int i=0,j=0,count=0;
    if(num<0){
        *(str++)='-';
        num=-num;
        count++;
    }else if(num==0){
        *(str)='0';
        return 1;
    }
    char buf[10];
    while(num>0){
        buf[i++]=num%10+'0';
        num=num/10;
        count++;
    }
    for(j=i-1;j>=0;j--){
        *(str++)=buf[j];
    }
    return count;
}
#endif

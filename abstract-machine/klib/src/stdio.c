#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <stdio.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
int intcatstr(char *str,int num);
int printf(const char *fmt, ...) {
    va_list ap;
    va_start(ap,fmt);
    char str[1024];
    int i=0;
    int num=vsprintf(str,fmt,ap);
    for(i=0;str[i];i++){
        putch(str[i]);
    }
    va_end(ap);
    return num;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
    char *ptr=(char *)fmt;
    int num=0,tmp;
    char *string;
    while(*ptr){
        switch (*ptr) {
            case '%':{
                ptr++;
                switch (*ptr) {
                    case 'd':tmp=va_arg(ap,int);
                             num+=intcatstr(out+num,tmp);
                             break;
                    case 's':string=va_arg(ap,char*);
                             strcpy(out+num,string);
                             num+=strlen(string);
                             break;
                    case '%':out[num++]='%';break;
                    default:assert(0);
                
                }
            }break;
            default:out[num++]=*(ptr);break;
        }
        ptr++;
    }
    out[num]='\0';
    return num;

}

int sprintf(char *out, const char *fmt, ...) {
    int num=0;
    va_list ap;
    va_start(ap,fmt);
    num=vsprintf(out,fmt,ap);
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
    unsigned int unum;
    if(num<0){
        *(str++)='-';
        unum=(unsigned int)-(num+1)+1;
        count++;
    }else if(num==0){
        *(str)='0';
        return 1;
    }else{
        unum=(unsigned int)num;
    }
    char buf[12];
    while(unum>0){
        buf[i++]=unum%10+'0';
        unum=unum/10;
        count++;
    }
    for(j=i-1;j>=0;j--){
        *(str++)=buf[j];
    }
    return count;
}
#endif

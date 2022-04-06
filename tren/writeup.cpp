#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace sio{
	int open(const char *filename, char *buffer){
		FILE *f = fopen(filename,"rb");
		fseek(f,0,SEEK_END);
		int len = ftell(f);
		rewind(f);
		fread(buffer,len,1,f);
		fclose(f);
		return len;
	}
	void save(const char *filename, char *buffer, int length){
		FILE *f = fopen(filename,"wb");
		fwrite(buffer,length,1,f);
		fclose(f);
	}
}

char zakon[0x8000000];
char zakonopisac[0x28000000];
int sigo;

inline void putin(const char* ubacaj){
	int josi=strlen(ubacaj);
	memcpy(zakonopisac+sigo,ubacaj,josi);
	sigo+=josi;
}

inline int novokvir(int star, int novo){
	switch(star*3+novo){
		case 1: // 0 u 1
		case 3: // 1 u 0
			putin("'");
			break;
		case 2: // 0 u 2
		case 6: // 2 u 0
			putin("\"");
			break;
		case 5: // 1 u 2
			putin("'\"");
			break;
		case 7: // 2 u 1
			putin("\"'");
			break;
	}
	return novo;
}

#define novo(x) okvir=novokvir(okvir,x)
void pisi(){
	sigo=0;
	putin("#!/bin/bash\n\nprintf ");
	int okvir=0;
	char tc[2]={0,0};
	
	for(int i=0;true;++i){
		tc[0]=zakon[i];
		switch(tc[0]){
			case 0: goto nap;
			case '\n':
				if(okvir==0)
					novo(2);
				putin("\\n");
				break;
			case '\t':
				if(okvir==0)
					novo(2);
				putin("\\t");
				break;
			case '$':
				novo(2);
				putin("\\$");
				break;
			case '\'':
				novo(2);
				putin("\'");
				break;
			case '"':
				switch(okvir){
					case 0:
						novo(1);
					case 1:
						putin("\"");
						break;
					case 2:
						putin("\\\"");
						break;
				}
				break;
			case '\\':
				switch(okvir){
					case 0:
						novo(1);
					case 1:
						putin("\\\\");
						break;
					case 2:
						putin("\\\\\\\\");
						break;
				}
				break;
			case '%':
				if(okvir==0)
					novo(2);
				putin("%%");
				break;
			case '#':
				if(zakon[i+1]=='!'){
					if(zakon[i+2]==' ')
						{if(okvir==0)novo(2);}
					else novo(1);
					putin("#!");
					++i;
				}
				else{
					if(okvir==0)
						novo(2);
					putin(tc);
				}
				break;
			case '!':
				if(zakon[i+1]==' ')
					{if(okvir==0)novo(2);}
				else novo(1);
				putin("!");
				break;
			default:
				novo(2);
				putin(tc);
				break;
		}
	}
	nap:;
	
	novo(0);
	putin("\n");
}
#undef novo

int main(int argc, char* argv[]){
	if(argc!=3){
		printf("si ti retardiran?\n");
		return 69;
	}
	sio::open(argv[1],zakon);
	pisi();
	sio::save(argv[2],zakonopisac,strlen(zakonopisac));
	return 0;
}

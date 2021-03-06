[build-menu]
FT_00_LB=_Compile
FT_00_CM=g++ "%f" -o "%e" -pipe -fwrapv -fno-plt -fno-semantic-interposition -std=c++20 -mcmodel=large -maddress-mode=long -march=x86-64 -m64 -mtune=generic -Wshadow -Wno-unused-result -Wall -O3 -L /usr/lib -Wl,--as-needed -lm -lz -lpthread -lutil -ldl -lrt -lcrypt -lgcrypt -Wl,-Bstatic -ltomcrypt -ltfm -Wl,-Bdynamic
FT_00_WD=
FT_01_LB=_Build
FT_01_CM=g++ "%f" -o "%e" -pipe -fwrapv -fno-plt -fno-semantic-interposition -std=c++20 -mcmodel=large -maddress-mode=long -march=x86-64 -m64 -mtune=generic -Wshadow -Wno-unused-result -Wall -g -fsanitize=address -fsanitize=undefined -D_GLIBCXX_DEBUG -L /usr/lib -Wl,--as-needed -lm -lz -lpthread -lutil -ldl -lrt -lcrypt -lgcrypt -Wl,-Bstatic -ltomcrypt -ltfm -Wl,-Bdynamic
FT_01_WD=
FT_02_LB=_Lint
FT_02_CM=cppcheck --language=c++ --enable=warning,style --template=gcc "%f"
FT_02_WD=

[build-menu]
FT_00_LB=_Compile
FT_00_CM=g++ "%f" -o "%e" -pipe -fwrapv -fno-plt -fno-semantic-interposition -std=gnu++23 -mcmodel=large -maddress-mode=long -march=x86-64 -m64 -mtune=generic -mlzcnt -mpopcnt -mmovbe -Wshadow -Wno-unused-result -Wall -O3 -I/usr/local/include/mylib -I/usr/include/python3.10 -L/usr/lib -Wl,--as-needed -lpython3.10 -lm -lz -lpthread -lutil -ldl -lrt -lcrypt -lgcrypt -lcurl -lncurses -Wl,-Bstatic -ltomcrypt -ltfm -Wl,-Bdynamic
FT_00_WD=
FT_01_LB=_Build
FT_01_CM=g++ "%f" -o "%e" -pipe -fwrapv -fno-plt -fno-semantic-interposition -std=gnu++23 -mcmodel=large -maddress-mode=long -march=x86-64 -m64 -mtune=generic -mlzcnt -mpopcnt -mmovbe -Wshadow -Wno-unused-result -Wall -g -fsanitize=address -fsanitize=undefined -D_GLIBCXX_DEBUG -I/usr/local/include/mylib -I/usr/include/python3.10 -L/usr/lib -Wl,--as-needed -lpython3.10 -lm -lz -lpthread -lutil -ldl -lrt -lcrypt -lgcrypt -lcurl -lncurses -Wl,-Bstatic -ltomcrypt -ltfm -Wl,-Bdynamic
FT_01_WD=

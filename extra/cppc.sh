cppc() {
  local CPPC_CMD=("g++")
  local CPPC_CONST="-pipe -std=gnu++23 -mcmodel=large -maddress-mode=long -m64"
  local -a CPPC_ARCH
  local -a CPPC_I_PATHS
  local -a CPPC_L_PATHS
  local -a CPPC_LIBS
  local -a CPPC_LIBS_STATIC
  local -a CPPC_DEFINES

  local CPPC_F=("-fwrapv" "-fno-plt" "-fno-semantic-interposition")
  local CPPC_WARNINGS="-Wshadow -Wno-unused-result -Wall"

  CPPC_ARCH+=("-march=native" "-mtune=native") # optimize for local machine
# CPPC_ARCH+=("-mabm") # ABM support
# CPPC_ARCH+=("-mbmi") # BMI support
# CPPC_ARCH+=("-mbmi2") # BMI2 support
# CPPC_ARCH+=("-mmovbe") # forcing MOV's

  CPPC_LIBS+=("-lm") # math.h
  CPPC_LIBS+=("-lz") # zlib
  CPPC_LIBS+=("-lrt") # shm_open
  CPPC_LIBS+=("-lcurl") # curl
  CPPC_LIBS+=("-lncurses") # ncurses
# CPPC_LIBS+=("-ljpgd" "-ljpge") # jpg
# CPPC_LIBS+=("-lX11" "-lXext" "-lXrender") # X
# CPPC_LIBS_STATIC+=("-ltomcrypt" "-ltfm") # tomcrypt
# python "3.10
# CPPC_I_PATHS+=("-I/usr/include/python3.10"); CPPC_LIBS+=("-lpython3.10")
# magick
# CPPC_I_PATHS+=("-I/usr/include/ImageMagick-7"); CPPC_LIBS+=("-lMagick++-7.Q16HDRI" "-lMagickCore-7.Q16HDRI" "-lMagickWand-7.Q16HDRI")
# mylib
# CPPC_I_PATHS+=("-I/usr/local/include/mylib"); CPPC_L_PATHS+=("-L/usr/local/include/mylib/shared")

  local CPPC_MODE_DEBUG=0
  local CPPC_MODE_OBJECT=0
  local CPPC_SOURCE=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d) CPPC_MODE_DEBUG=1;;
      -o) CPPC_MODE_OBJECT=1;;
      -do) CPPC_MODE_DEBUG=1; CPPC_MODE_OBJECT=1;;
      -od) CPPC_MODE_OBJECT=1; CPPC_MODE_DEBUG=1;;
      *) if [[ "$1" == "-D"* ]]; then
           CPPC_DEFINES+=("$1")
         else
           if [ -z "$CPPC_SOURCE" ]; then
             CPPC_SOURCE="$1"
           else
             echo "Unknown option: \`$1\`"
             return 2
           fi
         fi
         ;;
    esac
    shift
  done
  if [ -z "$CPPC_SOURCE" ]; then
    echo "No source file provided."
    return 1
  fi
  if [[ "$CPPC_SOURCE" == *.cpp ]]; then
    CPPC_SOURCE="${CPPC_SOURCE:0:-4}"
  fi
  if [ $CPPC_MODE_OBJECT -eq 1 ]; then
    CPPC_F+=("-fPIC")
    CPPC_CMD+=("-c" "\"${CPPC_SOURCE}.cpp\"" "-o" "\"${CPPC_SOURCE}.o\"")
  else
    CPPC_CMD+=("\"${CPPC_SOURCE}.cpp\"" "-o" "\"$CPPC_SOURCE\"")
  fi
  if [ $CPPC_MODE_DEBUG -eq 1 ]; then
    CPPC_CMD+=("-g")
    CPPC_F+=("-fsanitize=address" "-fsanitize=undefined")
    CPPC_DEFINES+=("-D_GLIBCXX_DEBUG")
  else
    CPPC_CMD+=("-O3")
  fi
  CPPC_CMD+=("${CPPC_DEFINES[@]}")
  CPPC_CMD+=("$CPPC_CONST")
  CPPC_CMD+=("${CPPC_ARCH[@]}")
  CPPC_CMD+=("${CPPC_F[@]}")
  CPPC_CMD+=("$CPPC_WARNINGS")
  CPPC_CMD+=("${CPPC_I_PATHS[@]}")
  if [ ${#CPPC_LIBS[@]} -gt 0 ] || [ ${#CPPC_LIBS_STATIC[@]} -gt 0 ]; then
    CPPC_CMD+=("${CPPC_L_PATHS[@]}")
    CPPC_CMD+=("-L/usr/lib" "-Wl,--as-needed")
    CPPC_CMD+=("${CPPC_LIBS[@]}")
    if [ ${#CPPC_LIBS_STATIC[@]} -gt 0 ]; then
      CPPC_CMD+=("-Wl,-Bstatic")
      CPPC_CMD+=("${CPPC_LIBS_STATIC[@]}")
      CPPC_CMD+=("-Wl,-Bdynamic")
    fi
  fi
  echo "${CPPC_CMD[@]}"
}
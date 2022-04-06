#!/bin/bash

printf '#!'"/bin/bash\n\npsd\ncd /home/username/.config/psd\nxcn=0\nwhile :; do\n  if [ -f psd.conf ]; then\n    sed -i 's/^.*USE_BACKUPS=\\\\\"yes\\\\\".*\$/USE_BACKUPS=\\\\\"no\\\\\"/' psd.conf\n    break\n  else\n    xcn=\$(( \$xcn + 1 ))\n    if [ \$xcn = 400 ]; then break; fi\n    sleep 0.3\n  fi\ndone\nsystemctl --user enable psd\nsystemctl --user start psd\nrm -rf /tmp/psdconf.sh\n"

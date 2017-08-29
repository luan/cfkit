# CFKit

Currently only runs on macOS.

## Quick Start

There are 3 scripts available to get started quickly:

```
scripts/regenerate-creds # generate credentials / .envrc for talking to BOSH
scripts/run              # starts the linuxkit VM with BOSH in it, sets up networking
                         # be sure to look at /var/vcap/log/*.log in the tty to track progress of BOSH booting up
scripts/deploy           # deploys CF to the newly created BOSH
```

At this point your usual bosh-lite.com URL should be working to push apps to CF.

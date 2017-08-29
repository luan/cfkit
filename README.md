# CFKit

Currently only runs on macOS.

## Dependencies

To run CFKit you need:

 * [BOSH CLI](https://bosh.io/docs/cli-v2.html) installed as either `bosh` or
   `gobosh` in your `PATH`
 * [Moby](http://mobyproject.org/) - Available as a brew formula
   (_linuxkit/linuxkit/moby_) or via `go get github.com/moby/tool/cmd/moby`
 * [LinuxKit](https://github.com/linuxkit/linuxkit) - Available as a brew
   formula (_linuxkit/linuxkit/linuxkit_) or via `go get
   github.com/linuxkit/linuxkit/src/cmd/linuxkit`
   * See their [getting started](https://github.com/linuxkit/linuxkit#getting-started)
 * [HyperKit](https://github.com/moby/hyperkit) and
   [VPNKit](https://github.com/moby/vpnkit) -- Not super easy to install
   standalone at the moment, maybe at some point there will be a [brew package
   for them](https://github.com/linuxkit/homebrew-linuxkit/issues/3). At the
   moment having [docker for mac](https://www.docker.com/docker-mac) installed
   will actually provide those dependencies to CFKit


## Quick Start

There are 3 scripts available to get started quickly:

```
scripts/regenerate-creds # generate credentials / .envrc for talking to BOSH
scripts/run              # starts the linuxkit VM with BOSH in it, sets up networking
                         # be sure to look at /var/vcap/log/*.log in the tty to track progress of BOSH booting up
scripts/deploy           # deploys CF to the newly created BOSH
```

At this point your usual bosh-lite.com URL should be working to push apps to CF.

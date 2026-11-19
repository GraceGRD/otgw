# VS Code devcontainer

Open this repository in VS Code and run **Dev Containers: Reopen in Container**.
The image uses Ubuntu 26.04 and builds gputils 1.5.2 and gpsim 0.32.1 from
source, matching the CI toolchain. Docker caches the toolchain build layers.
The tools are installed in `/opt/otgw-toolchain`, with the compiler, library,
and pkg-config paths configured for the firmware and simulator module.

Container setup builds `chmodule` automatically. Run the **firmware: build**
task to build `gateway.hex`, `diagnose.hex`, and `interface.hex`, or run
**firmware: build + validate** to also run the simulator test suite.
The same checks can be run in a terminal:

```sh
make gateway.hex diagnose.hex interface.hex
bash tools/validate-gpsim.sh
```

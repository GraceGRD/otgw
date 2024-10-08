# Itho WPU 5G
This readme page is intended to reverse-engineer the undocumented OpenTherm features of the Itho heat-pump.

## My system:
* Itho WPU5G (WPU45 I-5G)
  * HW version: 69
  * FW version: 34
* Itho WPV 200L 3G
* Itho Spider WP
* [OpenTherm Gateway][otgw] by Schelte Bron.
* [ithowifi module][ithowifi] by Arjen Hiemstra.

```
                                 +----------+
                                 | ithowifi |        +------+
                                 +----------+       /        \
                                      |            |          |
  +--------+       +------+       +--------+       | WPV 200L |
  | Spider |<----->| OTGW |<----->| WPU 5G |<----->|    3G    |
  +--------+       +------+       +--------+       +----------+
```

## Supported OTGW features:
Some functionality to control the heatpump is already supported by the OTGW here is a short list:
- `HW=0` DHW to economy mode
- `HW=1` DHW to comfort mode
- `SW=60` DHW daily temperature setpoint (except boost / legionella prevention cycles)
This commands modifies setting `Setpoint DHW daily_MFT LT (°C)` and has a range between 50 and 65 °C (verified using [ithowifi]).

## Installation:
1. Download the latest gateway.hex file from the [releases](https://github.com/GraceGRD/otgw/releases) page.
2. Flash the firmware using [otmonitor](https://otgw.tclcode.com/otmonitor.html#upgrade).

## Message ID 130 (DHW control):
The thermostat can control the boiler through Message ID 130, which represent Domestic Hot Water (DHW) comfort used exclusively in **Boost**, **Off** and **Stand-by** modes. 

Other modes such as **Eco** HW=1 and **Comfort** modes are controlled via the hot water commands `HW=state`.

This is implemented as command `QH=m` where `m` is one of the following three modes:
1. `QH=C` DHW cycle
Mimics the thermostat `Boost` functionality which directly heats up the hot water to ~62°C.
2. `QH=B` DHW block
Mimics the thermostat `Off` functionality which disables the boiler entirely (including legionella prevention).
3. `QH=S` DHW standby
Mimic the thermostat `Stand-by` functionality which disables the boiler partially (excluding weekly legionella prevention).

Any other argument will disable the `QH` override.

##### Communication:

```                               
14:58:06.896924  T80820400  Read-Data   Message ID 130 (MsgID=130): 1024
14:58:06.992620  B4082044D  Read-Ack    Message ID 130 (MsgID=130): 1101

Message ID 130 bit structure:
    0b xxxx tttt bbbb xxxx 
    0b      tttt            -> Thermostat control bits
    0b           bbbb       -> Boiler status bits
    0b xxxx           xxxx  -> Don't care

Thermostat control / Boiler status bits:
    0b 0001 -> Boost
    0b 0010 -> Unknown
    0b 0100 -> Block
    0b 1000 -> Standby
```

**DHW Boost handshake:**
````
    T: 0b xxxx 0001 0000 xxxx -> Thermostat DHW mode set to Boost
    B: 0b xxxx 0001 0000 xxxx
    T: 0b xxxx 0001 0000 xxxx
    B: 0b xxxx 0001 0001 xxxx -> Boiler acknowledges DHW Boost mode (boiler is on)
    ...
    T: 0b xxxx 0001 0000 xxxx
    B: 0b xxxx 0001 0000 xxxx -> Boiler acknowledges DHW Boost mode is done (boiler is off)
````

**DHW Off handshake:**
````
    T: 0b xxxx 0100 0000 xxxx -> Thermostat DHW mode set to Off
    B: 0b xxxx 0100 0000 xxxx
    T: 0b xxxx 0100 0000 xxxx
    B: 0b xxxx 0100 0100 xxxx -> Boiler acknowledges DHW off mode
````

**DHW Stand-by handshake:**
````
    T: 0b xxxx 1000 0000 xxxx -> Thermostat DHW mode set to Stand-by
    B: 0b xxxx 1000 0000 xxxx
    T: 0b xxxx 1000 0000 xxxx
    B: 0b xxxx 1000 1000 xxxx -> Boiler acknowledges DHW Stand-by mode
````

## Message ID 133 (DHW time)
The heat pump stores the value associated with Message ID 133, which represents the Domestic Hot Water (DHW) time used exclusively in **Eco** mode. The thermostat can overwrite this value by sending a write request to Message ID 133, allowing it to adjust the DHW time for the boiler in this mode.

This is implemented as command `QI=hh:mm` where hh:mm is the time format e.g. `QI=19:05` will set the DHW time to 19:05.

##### Communication:
```
09:54:59.536607  T9085B305  Write-Data  Message ID 133 (MsgID=133): 45829
09:54:59.644733  B5085B305  Write-Ack   Message ID 133 (MsgID=133): 45829
09:59:52.923827  T9085B609  Write-Data  Message ID 133 (MsgID=133): 46601
09:59:53.025945  B5085B609  Write-Ack   Message ID 133 (MsgID=133): 46601

Examples:
0xB305 ->   0b 1011 0011 0000 0101  -> Set DHW time to 19:05 (QI=19:05)
            0b 101                  -> Fixed   (t.b.d.)
            0b    1 0011            -> Hours   (19)
            0b           0000 0101  -> Minutes (5)

0xB609 ->   0b 1011 0110 0000 1001  -> Set DHW time to 22:09 (QI=22:09)
            0b 101                  -> Fixed   (t.b.d.)
            0b    1 0110            -> Hours   (22)
            0b           0000 1001  -> Minutes (9)
```

## TODO:

- Figure out how to control heatpump heating/cooling

[otgw]: https://otgw.tclcode.com
[ithowifi]: https://github.com/arjenhiemstra/ithowifi

Requirements
============

The provided files are intended to be used together with the gputils tools.
At least version 1.5.0 is required.
The gputils tools can be downloaded from https://gputils.sourceforge.io/
On many linux distributions the gputils package can be installed via the
package manager, although some may be too old. In that case, it will need to
be installed from source.

The OTGW source tarball includes a Makefile to simplify building the OTGW
firmware. To be able to use it, the GNU make command must be available.

A Tcl interpreter is also needed to regenerate the "build.asm" file. This can
either be tclsh or a tclkit/tclkitsh.

To be able to run the test-suite, several additional packages are needed:

RPM based systems
-----------------
Required packages:
tcl subversion make libtool flex bison
popt-devel glib2-devel readline-devel

Optional packages:
gtk2-devel (gui), lyx (doc)

Debian based systems
--------------------
Required packages:
tcl subversion make libtool flex bison
libpopt-dev libglib2.0-dev libreadline-dev

Optional packages:
libgtk2.0-dev (gui), lyx (doc)

Pacman based systems
--------------------
Required packages:
tcl subversion gcc make autoconf automake libtool pkgconfig flex bison
popt glib2 readline

Optional packages:
gtk2 (gui), lyx (doc)


Compiling
=========

To create a hex file that can be loaded into the PIC16F1847 using OTmonitor
or a PIC programmer, follow these steps:
- Unpack the tarball in a convenient location:
    wget -qO- https://otgw.tclcode.com/download/otgw-6.5.tgz | tar xzv
- Go to the otgw-6.5 directory: cd otgw-6.5
- Run: make

The "build.asm" file is supposed to be auto-generated at the start of every
build. The included "build.tcl" script takes care of that. It is executed by
tclsh. If the tclsh executable is not in your PATH, pass the location to the
make command:
    make TCLSH=/path/to/tclsh

To build the diagnose firmware:
    make diagnose.hex

To build the interface firmware:
    make interface.hex


Testing
=======

A test suite is provided. Running it will verify that the covered features
are still working after a code change. The test suite relies on the open
source PIC simulator project gpsim [http://gpsim.sourceforge.net/].

Support for the PIC16F1847 used in the OTGW was added in version 0.32.1.
Building gpsim requires some resources to be available. On linux these can
be installed using the package manager.

This is how to build gpsim 0.32.1:
    wget -qO- https://sourceforge.net/projects/gpsim/files/gpsim/0.32.0/gpsim-0.32.1.tar.gz | tar xzv
    cd gpsim-0.32.1
    ./configure --disable-gui
    make -j4
Then as root:
    make install

The test suite also needs a simulated central heating system to test the
OTGW code against. This is provided in the form of a gpsim module, available
in the gpsim subdirectory of the source tarball. To build it, use a similar
procedure as above:
    cd chmodule
    ./autogen.sh
    ./configure
    make -j4
Then as root:
    make install

If the configure command fails to find (the correct) gpsim headers, you can
help it by providing the --with-gpsim=/usr/local/include/gpsim option.

Each test is defined in a file in the tests directory. The complete test
suite can be executed using:
    make test

Specific tests may be selected by passing the TESTFLAGS variable to the make
command. For example, to run only the thermostat and standalone tests:
    make test TESTFLAGS="-match 'thermostat-* standalone-*'"


Alternative setup
=================

If you are unable or unwilling to use root permissions to install gpsim, or
gputils if you need it, it is possible to install things in a different
location. The file-hierarchy man page suggests to use ~/.local for user-
installed applications.

To limit the places where you have to modify the location you have chosen,
the description below uses the PREFIX variable. Set that variable to the
desired installation location. For example:
    PREFIX=$HOME/.local

gputils:
    wget -qO- https://sourceforge.net/projects/gputils/files/gputils/1.5.0/gputils-1.5.2.tar.bz2 | tar xjv
    cd gputils-1.5.2
    ./configure --prefix=$PREFIX
    make -j4
    make install
    cd ..

gpsim:
    svn checkout svn://svn.code.sf.net/p/gpsim/code/branches/p16f1847 gpsim
    cd gpsim
    ./autogen.sh
    ./configure --prefix=$PREFIX --disable-gui
    make -j4
    make install
    cd ..

otgw-6.5:
    wget -qO- https://otgw.tclcode.com/download/otgw-6.5.tgz | tar xzv
    cd otgw-6.5
    make
    # Or, if $PREFIX/bin is not in your PATH:
    PATH=$PREFIX/bin:$PATH make

chmodule:
    cd chmodule
    ./autogen.sh
    ./configure --with-gpsim=$PREFIX/include/gpsim --prefix=$PREFIX
    make -j4
    make install
    cd ..


Customizing
===========

The provided Makefile allows for some customization via a Makefile-local.mk
file. It is advised to put any customizations in this file rather than
editing the Makefile, because then your changes will not be lost when the
sources are updated to a new version. In the Makefile-local.mk file you can
do things like specifying variables for the used binaries, if they are not
on your default PATH. By putting this in the Makefile-local.mk file, you
don't have to remember to pass variables to the make command each time.

For example, with the following lines in Makefile-local.mk, the make command
can be invoked normally and it will find the tools that were installed under
~/usr/local:

  USERBIN = $(HOME)/usr/local/bin
  GPASM = $(USERBIN)/gpasm
  GPLINK = $(USERBIN)/gplink
  GPSIM = $(USERBIN)/gpsim

  test: export LD_LIBRARY_PATH = $(HOME)/usr/local/lib

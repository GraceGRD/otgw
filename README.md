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

## Message ID 134 (TBD)

## Message ID 135 (TBD)

## Message ID 141 (WIP ?Thermostat heating/cooling/dhw icons?)
Decoding  of this message id is still work-in-progress.
```
Cooling -> 0x0108   0b 0000 0001 0000 1000
Boiler  -> 0x0104   0b 0000 0001 0000 0100 after boiler boost button pressed
Boiler  -> 0x012c   0b 0000 0001 0010 1100 during boiler seq
Boiler  -> 0x0008   0b 0000 0000 0000 1000 seq done, cooling again
Cooling -> 0x0000   0b 0000 0000 0000 0000 decreased setpoint cooling icon went off
Cooling -> 0x0008   0b 0000 0000 0000 1000 increased setpoint cooling icon went on
                    0b         1           -> DHW temp low / DHW disabled (after ECO mode has passed and temp is low)     (assumed)
                    0b             1       -> DHW Active        (partially-confirmed / similar to bit 4)
                    0b                1    -> Cooling Active    (confirmed)
                    0b                 1   -> DHW Active        (partially-confirmed)
```

## Message ID 142 (Min room temp thermostat (°C))
Represents WPU setting `Min room temp thermostat (°C)`.

## Message ID 143 (Max room temp thermostat (°C))
Represents WPU setting `Max room temp thermostat (°C)`.

## Message ID 146 (Offset cooling (K))
Represents WPU setting `Offset cooling (K)`.

## Message ID 151 (Blocking time heating to cooling (uur))
Represents WPU setting `Blocking time heating to cooling (uur)`.

## Message ID 154 (Differential for free cooling mode (K))
Represents WPU setting `Differential for free cooling mode (K)`.

## Message ID 159 (Blocking time cooling to heating (uur))
Represents WPU setting `Blocking time cooling to heating (uur)`.

## Message ID 160 (Minimum outside temp cooling (°C))
Represents WPU setting `Minimum outside temp cooling (°C)`.


## TODO:

- Figure out how to control heatpump heating/cooling

[otgw]: https://otgw.tclcode.com
[ithowifi]: https://github.com/arjenhiemstra/ithowifi

## Building and testing

For requirements, build instructions, testing, and customization, see the
[original OTGW readme](readme.txt).

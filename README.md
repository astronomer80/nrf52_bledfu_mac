# nrfDFU
OSX command line application for performing an nRF52 device firmware update for softdevice 2.0.0 and Nordic SDK v11

This is a simple command line program wrote based on Nordic's documentation and their 
RF Toolbox https://github.com/NordicSemiconductor/IOS-nRF-Toolbox sample app.

The goal was to better understand the nRF52 DFU process and to have a simple command 
line program I could use from build scripts to update projects of mine during development and testing.

For anyone interested in using this as a starting point for their own learning, main.c and NDDFUSampleController 
are what you would replace with your own OSX or iOS application. Those files are mostly concerned with
parsing command line arguments, selecting the BLE device to update and printing status.

The interesting code from a DFU perspective (and the code intended to be reused) is pretty much all in
NDDFUDevice and NDDFUFirmware. 

The code doesn't support SoftDevice or Bootloader updates yet, and things like app version, device ID and version
and the required SoftDevice ID are currently hardcoded.

The plan is to further clean up the code, which I expect will be mostly driven by my plan to include it in
an iOS app that I've written that talks to an nRF52 based board of mine.

Issues and especially pull requests welcome!

For Windows or Linux here other repos:
Linux application: https://github.com/astronomer80/ota-dfu-python/tree/buttonless
Windows Application: https://github.com/astronomer80/nrf52_bledfu_win/tree/consoleapp


<b>DFU Procedure performed by this application:</b>

1)Send 'START DFU' opcode + Application Command (0x0104)

2)Send the image size

3)Send 'INIT DFU' Command (0x0200): Called in the controlPoint_CalueChanged event invoked when the BLE device replies after sending the image size.

4)Transmit the Init image (The file DAT content) (DOING...)

5)Send 'INIT DFU' + Complete Command (0x0201)

6)Send packet receipt notification interval (currently 10)

7)Send 'RECEIVE FIRMWARE IMAGE' command to set DFU in firmware receive state. (0x0300)

8)Send bin array contents as a series of packets (burst mode). Each segment is pkt_payload_size bytes long. For every packet send, wait for notification.

9)Send Validate Command (0x0400)

10)Send Activate and Reset Command (0x0500)



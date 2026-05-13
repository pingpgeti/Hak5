# USB Rubber Ducky payload

Project using Hak5 tool [USB Rubber Ducky](#introduction), made for KN Ping.

## Disclaimer

This project was created entirely in educational purposes.\
All use of [USB Rubber Ducky](#introduction) was within the bounds of law.

## Introduction

**USB Rubber Ducky** is a popular hacking tool developed by Hack5. Designed to appear as a harmless USB flash drive, in reality functions as a Human Interface Device (HID).
By tricking the computer to recognise it as a keyboard, it allows for rapid keystroke injection attacks, or automation of mundane repetitive tasks.

## Description

This project utilise [USB Rubber Ducky](#introduction) to steal password protected pdf files from source directory of `Windows` operated machines.

Upon pluging in the device starts in `STORAGE` mode. In this configuration it functions as normal USB flash drive. Wait approximately 3s. You should see external drive labeled "DUCKY".\
Now sqeeze the device gently to press the button under the case. Your device should enter `HID STORAGE` mode and start the attack. It will open powershell command prompt and execute [payload.ps1](#payloadps1) stored on the device.
The script first creates a directory with the name of machine it has been pluged into.
Then it is searching target location looking for encrypted pdf files.\
For convinience the target location is defined by [target.txt](#targettxt).
So you do not have to manually change it inside the script.\
When an encrypted pdf file is found, it is copied into prior created folder.
Afterwords the script cover it's tracks by deleting history of recently accesed files and commands started via run window.\
Lastly the script will signalize end of the task by turning `CAPSLOCK` key on and off three times.

## How to use

1. Visit [Payload Studio](https://payloadstudio.hak5.org/community/) and using [payload.txt](#payloadtxt) generate inject.bin file.
2. Plug in your [USB Rubber Ducky](#introduction).
    1. If you can not see it as drive squeeze it gently to switch it to `STORAGE` mode.
3. Drag and paste inject.bin, [payload.ps1](#payloadps1) and [target.txt](#targettxt) onto your device.
4. Define path to source dir in [target.txt](#targettxt).
5. Eject and remove the device.
6. You are good to go!

## Components

The project consist of three components:

- [payload.txt](#payloadtxt)
- [payload.ps1](#payloadps1)
- [target.txt](#targettxt)

### payload.txt

A DuckySript script responsible for configuration of [USB Rubber Ducky](#introduction), and setting of [payload.ps1](#payloadps1). To generate inject.bin visit [Payload Studio](https://payloadstudio.hak5.org/community/).

### payload.ps1

Main component of the project. It contains three main functionalities:

- Locating encrypted pdf files within source directory defined by [target.txt](#targettxt).
- Copying above-mentioned files on to the [USB Rubber Ducky](#introduction).
- Covering tracks. Clearing history of used files and ran commands.

### target.txt

Defines the source directory in which the [payload.ps1](#payloadps1) will look for files.
If [target.txt](#targettxt) or indicated directory does not exist the [payload.ps1](#payloadps1) by default assumes `$env:USERPROFILE\Downloads` as source directory.

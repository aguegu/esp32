PORT := /dev/ttyUSB0

flash-firmware:
	esptool.py --port ${PORT} write_flash -e -fm dio 0 ./firmware.bin

.PHONY: flash-firmware

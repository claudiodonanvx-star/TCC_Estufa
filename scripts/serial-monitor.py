import argparse
import sys
import time

import serial


def main() -> int:
    parser = argparse.ArgumentParser(description="Simple serial monitor for ESP32/Arduino boards.")
    parser.add_argument("--port", default="COM5", help="Serial port, for example COM5")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate")
    parser.add_argument("--raw", action="store_true", help="Do not prefix timestamps")
    args = parser.parse_args()

    try:
        with serial.Serial(args.port, args.baud, timeout=0.5) as connection:
            print(f"Connected to {args.port} at {args.baud} baud. Press Ctrl+C to stop.")
            time.sleep(2)
            connection.reset_input_buffer()

            while True:
                line = connection.readline()
                if not line:
                    continue

                text = line.decode("utf-8", errors="replace").rstrip("\r\n")
                if args.raw:
                    print(text)
                else:
                    timestamp = time.strftime("%H:%M:%S")
                    print(f"[{timestamp}] {text}")
    except serial.SerialException as error:
        print(f"Failed to open serial port {args.port}: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nSerial monitor stopped.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
#!/bin/bash
# upload_srec.sh - Upload Enhanced BASIC S-record to MVME167

SREC_FILE="build/enhanced_basic_ram.srec"

if [ ! -f "$SREC_FILE" ]; then
    echo "Error: S-record file not found: $SREC_FILE"
    echo "Run 'make' first to build the project"
    exit 1
fi

echo "Enhanced BASIC S-Record Upload"
echo "=============================="
echo ""
echo "File to upload: $SREC_FILE"
ls -lh "$SREC_FILE"
echo ""

# Find available serial ports
echo "Available serial ports:"
PORTS=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null)
if [ -z "$PORTS" ]; then
    echo "No serial ports found!"
    echo "Check your USB adapter connection."
    exit 1
fi

echo "$PORTS"
echo ""

# Let user select port
PS3="Select serial port (number): "
select PORT in $PORTS; do
    if [ -n "$PORT" ]; then
        break
    else
        echo "Invalid selection"
    fi
done

echo ""
echo "Using port: $PORT"
echo "Baud rate: 9600"
echo ""
echo "Next steps:"
echo "1. In MVME167 monitor, type: LOAD"
echo "2. Monitor will wait for S-records"
echo "3. Press Enter to send S-records..."
read -p "Press Enter when ready: "

echo ""
echo "Sending S-record file..."
cat "$SREC_FILE" > "$PORT"

echo "Upload complete!"
echo ""
echo "In MVME167 monitor, you should see:"
echo "  [S-records received]"
echo "  > (prompt returns)"
echo ""
echo "To run Enhanced BASIC, type:"
echo "  > GO 400400"
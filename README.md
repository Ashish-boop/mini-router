The project is based on a router, which is a Layer 3 device in the OSI model that forwards data packets between computer networks. It directs each incoming packet to the correct output channel based on the destination address in the packet header.
The Router 1x3 design operates on a packet-based protocol. It receives packets from a source LAN through the data_in line, byte by byte, on the rising edge of the clock. The signal resetn serves as an active-low synchronous reset.
- The start of a packet is indicated when pkt_valid is asserted, and the end of the packet is marked when pkt_valid is de-asserted.
- Incoming packets are stored in one of three FIFOs, chosen according to the packet’s destination address.
- During packet retrieval, each destination LAN monitors its corresponding vld_out_x signal (where x = 0, 1, or 2). When valid data is available, the LAN asserts read_enb_x to read the packet through its respective data_out_x channel.
The router can sometimes enter a busy state, signaled by busy. When this happens, the source LAN must pause and wait before sending the next byte.
To ensure packet integrity, the router performs a parity check. It compares the parity byte sent by the source with the internally calculated parity. If there is a mismatch, the router asserts an error signal, notifying the source LAN to resend the packet.
This design supports one packet reception at a time, but allows simultaneous reading of up to three packets by the destination LANs.
The top module consists of 3 fifo's, one finite state machine, one register, and one synchroniser.

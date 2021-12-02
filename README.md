# Huffmans_encoder_VHDL
A generic static huffmans encoder implementation written in VHDL.
The src folder contains the sorting cell and block as well as the state machine which genrates the huffman table for a given set of data.
The sim folder contains a testbench file used for simulation which shows an example of the componeant working.



The interface to the block requires a clock and reset signal. The reset is assumed to be assereted on the negative edge.
The ```write_data``` input allows data written to the ```data_in``` input to be written to some block RAM and increments
the occurance of that byte in another memory.
The ```start_huff``` input blocks new values being written into the memory and then starts the generation of the huffman
tree and table.
The ```done``` and ```some_out``` outputs are currently not used.

This project is still under development and has only been tested in simulation and not in hardware.

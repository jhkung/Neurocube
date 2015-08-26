function [ SRAM ] = SRAM_construct( )
%% Constructor for SRAM (shared by multiple MACs)

global NETWORK;
num_SRAMs       = NETWORK.num_rows * NETWORK.num_cols;

field1      = 'latency';        latency     = 1;
field2      = 'packet';         null_data   = zeros(1,6);
field3      = 'ptr';            cache_ptr   = 0;
field4      = 'capacity';       capacity    = 1024;
field5      = 'boundCap';       boundCap    = 0;
field6      = 'tempBuffer';


for idx = 1:num_SRAMs
    value1{1,idx}   = latency;
    value2{1,idx}   = null_data;        % [src, dst, gen_time, packetID, data_type, arr_time]
    value3{1,idx}   = cache_ptr;
    value4{1,idx}   = capacity;
    value5{1,idx}   = boundCap;
    value6{1,idx}   = null_data;
end


SRAM = struct(field1,value1, field2,value2, field3,value3, field4,value4, field5,value5,  field6,value6);

end



function [ ROUTER ] = ROUTER_construct( )
%% Constructor for ROUTER depending on a given architecture

global NETWORK;

null_data   = zeros(NETWORK.buffer_size,6);

for buf_idx = 1:length(NETWORK.buffer_arr)
    for router_idx = 1:(NETWORK.num_rows*NETWORK.num_cols)
        
        ROUTER(router_idx,buf_idx).packet   = null_data;    % [src, dst, gen_time, packetID, data_type, arr_time]
        ROUTER(router_idx,buf_idx).buf_ptr  = 0;
        ROUTER(router_idx,buf_idx).full     = 0;
        ROUTER(router_idx).stall            = 0;
        ROUTER(router_idx).latency          = 1;            % router data transfer latency
        ROUTER(router_idx).directionLUT     = ROUTER_dirGen(router_idx);   % depending on router_idx   
        
    end
end


end


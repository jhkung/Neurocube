function [ ROUTER ] = ROUTER_construct( )
%% Constructor for ROUTER depending on a given architecture

global NETWORK;

null_data   = zeros(NETWORK.buffer_size,4);

for buf_idx = 1:length(NETWORK.buffer_arr)
    for router_idx = 1:(NETWORK.num_rows*NETWORK.num_cols)
        
        ROUTER(router_idx,buf_idx).data     = null_data;
        ROUTER(router_idx,buf_idx).buf_ptr  = 0;
        ROUTER(router_idx,buf_idx).full     = 0;
        ROUTER(router_idx,buf_idx).stall    = 0;       
        ROUTER(router_idx).latency          = 1;        % router data transfer latency
        
    end
end


end


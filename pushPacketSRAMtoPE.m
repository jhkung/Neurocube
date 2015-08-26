function [outPackets] = pushPacketSRAMtoPE()
% push packet that has been failed to fetched due to filled buffer

global pushedPackets;
global ROUTER;      global NETWORK;
buf_idx     = 1;
pushedPackets(:,6) = pushedPackets(:,6) + 1;        % increase 'arr_t' by one
neighbor_pe_idx    = pushedPackets(1,1);

if (~ROUTER(neighbor_pe_idx,buf_idx).full)
    ROUTER(neighbor_pe_idx,buf_idx).packet(ROUTER(neighbor_pe_idx,buf_idx).buf_ptr+1,:) = pushedPackets(1,:);
    ROUTER(neighbor_pe_idx,buf_idx).buf_ptr = ROUTER(neighbor_pe_idx,buf_idx).buf_ptr + 1;    % increaes buffer pointer in ROUTER node
    
    if (ROUTER(neighbor_pe_idx,buf_idx).buf_ptr == NETWORK.buffer_size)
        ROUTER(neighbor_pe_idx,buf_idx).full     = 1;    % make full signal high if the CORE input buffer is filled with packets
    end
    
    if (size(pushedPackets,1) > 1)
        outPackets  = pushedPackets(2:end,:);
    else
        outPackets  = [];
    end
else
    outPackets  = pushedPackets;
end

end


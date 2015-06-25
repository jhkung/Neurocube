function [ ] = update_buffer( r_idx, b_idx )
% Update buffer when a packet is moved to the next buffer

global ROUTER;

ROUTER(r_idx,b_idx).packet = [ROUTER(r_idx,b_idx).packet(2:end,:); zeros(1,size(ROUTER(r_idx,b_idx).packet, 2))];
ROUTER(r_idx,b_idx).buf_ptr = ROUTER(r_idx,b_idx).buf_ptr - 1;
if (ROUTER(r_idx,b_idx).full == 1)
    ROUTER(r_idx,b_idx).full = 0;
end
            
end


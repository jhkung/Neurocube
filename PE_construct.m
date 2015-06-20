function [ PE ] = PE_construct( NN_type, num_MAC )
%% Constructor for PE (group of multiple MACs)

global NETWORK;
num_PEs     = NETWORK.num_rows * NETWORK.num_cols;


if strcmp(NN_type, 'CNN')
    for pe_idx = 1:num_PEs
        PE(pe_idx).init_flag    = 1;    % init_flag(1): initial computation of convolution in CNN (needs 3 operands for each MAC unit)
                                        % init_flag(0): requires 2 operands
        PE(pe_idx).mac_idx      = 0;    % MAC index for loading operands to proper MAC unit (arbitration purpose; Round-Robin?)
        PE(pe_idx).t_compute    = 4;    % assume each MAC requires 't_compute' to compute single MAC operation
        
        for mac_idx = 1:num_MAC
            PE(pe_idx,mac_idx).op_cnt       = 0;    % counts the number of operands being loaded from SRAM (cache)
            PE(pe_idx,mac_idx).compute_flag = 0;    % when all operands are ready begin computation
            PE(pe_idx,mac_idx).done         = 0;    % done(1): when computation is done
        end
    end
else
    error('NN TYPE NOT RECOGNIZED!');
end



end


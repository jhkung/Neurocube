function [ PE ] = PE_construct( NN_type, num_MAC )
%% Constructor for PE (group of multiple MACs)

global NETWORK;
num_PEs     = NETWORK.num_rows*NETWORK.num_cols;


if strcmp(NN_type, 'CNN')   % does PE struct has to be different depending on NN types??
    for pe_idx = 1:num_PEs
        PE(pe_idx).init_flag    = 1;    % init_flag(1): initial computation of convolution in CNN (needs 3 operands for each MAC unit)
                                        % init_flag(0): requires 2 operands
        PE(pe_idx).mac_idx      = 1;    % MAC index for loading operands to proper MAC unit (arbitration purpose; Round-Robin)
        PE(pe_idx).t_compute    = 4;    % assume each MAC requires 't_compute' to compute single MAC operation
        PE(pe_idx).num_MAC      = num_MAC;
        
        for idx = 1:num_MAC
            PE(pe_idx).MAC(idx).packet       = zeros(3,6);    % [src, dst, gen_time, packetID, data_type, arr_time]
            PE(pe_idx).MAC(idx).operand_cnt  = 0;             % # of operands being loaded to the MAC
            PE(pe_idx).MAC(idx).compute_flag = 0;             % when all operands are ready begin computation
            PE(pe_idx).MAC(idx).est_time     = 0;             % estimated time when each MAC computation is done ('sim_t' + 't_compute')
            PE(pe_idx).MAC(idx).conv_cnt     = 0;             % counts the number of computations for convolution operation
        end
    end
else
    error('NN TYPE NOT RECOGNIZED!');
end



end


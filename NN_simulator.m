%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation for neural network NoC with                %
% DRAMs, routers, processing engines (PEs)              %
%                                                       %
% Example of simple 2x2 NN NoC (MEM represents DRAM)    %
% Cores have its own caches (SRAMs)                     %
%   MEM                   MEM                           %
%    |                     |      <M_IN/M_OUT>          %
%  Router -------------- Router   <N_IN,E_IN,W_IN,S_IN> %
%    |                     |      <C_IN/C_OUT>          %
%   Core                  Core                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Programmed by DKim & JKung %%%%%%%%%%%%%%%
%%%%%%%%%%%% Recently Edited on 08.25.2015 %%%%%%%%%%%%%%

clc;
clear all;

% define each component as a struct
global DRAM;    global ROUTER;
global PE;      global SRAM;
global NETWORK;


DRAM_type           = 'DDR3';
DRAM_type           = 'HMC_INT';
DRAM                = DRAM_construct(DRAM_type);

% NETWORK: network struct for information on router network (delay, topology,...)
NETWORK.num_rows    = 4;
NETWORK.num_cols    = 4;
NETWORK.buffer_size = 2;    % default size is 2
NETWORK.buffer_arr  = {'C_IN', 'M_IN', 'N_IN', 'E_IN', 'W_IN', 'S_IN', 'C_OUT', 'M_OUT', 'N_OUT', 'E_OUT', 'W_OUT', 'S_OUT'};       % 12 buffers with 'buffer_size'
ROUTER              = ROUTER_construct();       % ROUTER(router_idx, buffer_idx): data, buf_ptr

NN_type             = 'CNN';
num_MAC             = 4;    % # of MACs/PE
PE                  = PE_construct(NN_type, num_MAC);

SRAM                = SRAM_construct();

global CNN;
CNN.imgWidth    = 16;    CNN.imgHeight   = 16;
CNN.p_imgWidth  = floor(CNN.imgWidth/NETWORK.num_cols);
CNN.p_imgHeight = floor(CNN.imgHeight/NETWORK.num_rows);
CNN.tempWidth   = 3;    CNN.tempHeight  = 3;
CNN.radius      = (CNN.tempWidth-1)/2;


%% simulation begin
global MEM_CENTRIC;    MEM_CENTRIC = 1;
global packetID;
global packetHistory;  packetHistory = [];
global SRAM_cap;       SRAM_cap    = 0;
% global DRAM_router_node;

% (total) numDATA = (locally stored templates) + (cell states + cell offsets)
numDATA         = NETWORK.num_rows*NETWORK.num_cols*(CNN.tempWidth*CNN.tempHeight) + 2*CNN.imgWidth*CNN.imgHeight;


global p_imgSize;   global imgSize;
global nRead;       global nNeighborRead;
global sim_t;       sim_t       = 0;
global stallMAC;    global pushedPackets;
time_max = 1000;           % for debugging purpose

nRead    = 0;             % number of data read from DRAM
nNeighborRead = 0;
rcv_complete  = 0;        % determines whether DRAM fetch is completed
mac_complete  = 0;
currPosition  = initPosition();    % [row_idx, col_idx] for PE compuation position in each partial image
pushedPackets = [];

temp_cnt = 0;

if (MEM_CENTRIC)
    
    % data packet generation from DRAM (genPacket kept as a reference)
    [ genPacket, packetID, image_idx ] = packetGen(NN_type, DRAM_type);        % generated packet by global address generator in DRAM die (memory-centric)
    if (length(genPacket) ~= numDATA)
        error('ENTIRE PACKETS ARE NOT GENERATED! - CHECK packetGen()');
    end
    
    readDRAM    = 1;        readBoundary    = 0;       readSRAM    = 0;
    blk_idx     = 0;        % blk_idx: index for handling data of each SRAM cap
    nData_to_Read   = numel(image_idx{1});     % # of cell states & offset to be read from each DRAM channel considering SRAM cap

    [ p_imgSize, imgSize ]          = initData();
    [ nNeighbor, neighborPacket ]   = genNeighborArray(genPacket, image_idx);

    while (~rcv_complete || ~mac_complete)     % if SRAM receives entire packets from DRAM
%     while (sim_t < time_max)  % DEBUG purpose

        sim_t = sim_t + 1;
        
        % packet: [src, dst, gen_time, packetID, data_type, arr_time]
        % 1) packet fetched from DRAM at each channel (at the same time)
        % and fed into ROUTER node (gen_time = gen_time + DRAM latency)
        if (readDRAM)
            msg         = sprintf('\n**Phase1: packet transfer [DRAM->SRAM]\n');      disp(msg);
            [ popFlag ] = popPacketDRAM();
            
            if (nRead == nData_to_Read)
                nRead       = 0;    readDRAM    = 0;
                nNeighborRead = 0;  initBound   = 1;
                blk_idx     = blk_idx + 1;
                
                if (SRAM_cap && strcmp(NN_type, 'CNN'))
                    readBoundary    = 1;
                end
            end
        elseif (readBoundary)
            % data fetch from DRAM for boundary data (for convolution operation)
            % prior to SRAM data fetching
            if strcmp(NN_type, 'CNN')
                if (initBound == 1)
                    % increase SRAM capacity to store neighboring packets
                    if (blk_idx == 1)
                        from_i = 1;
                    else
                        from_i  = sum(nNeighbor(1:blk_idx-1)) + 1;
                    end                    
                    to_i    = sum(nNeighbor(1:blk_idx));
                    
                    currPacket = neighborPacket(from_i:to_i,:);
                    updateSRAMcap(currPacket);
                    
                    % offset 'gen_t' to synchronize the packets
                    gen_t_offset        = sim_t - (DRAM(1).t_access + DRAM(1).t_interc) - currPacket(1,3);
                    currPacket(:,3)     = currPacket(:,3) + gen_t_offset;
                    initBound           = 0;
                end
                
                [currPacket] = popNeighborData( currPacket );
                updateDRAM_gen_t();
                
                if (nNeighborRead == nNeighbor(blk_idx))
                    readBoundary    = 0;
                end
            end
        else
            updateDRAM_gen_t();     % when readDRAM is idle, increment the 'gen_t' for DRAM packets in the queue
        end
        
        if (~readDRAM && ~readBoundary && SRAM_cap)
            temp_cnt = 0;
            for nodeIdx = 1:NETWORK.num_rows*NETWORK.num_cols
                temp_cnt = temp_cnt + SRAM(nodeIdx).ptr - SRAM(nodeIdx).capacity;
            end
        end
        
        % start fetching data from SRAM whenever partial image data are ready
        if (~isempty(packetHistory) && readBoundary == 0 && readSRAM == 0)
            for nodeIdx = 1:NETWORK.num_rows*NETWORK.num_cols
                if ( (packetHistory(end,4) == SRAM(nodeIdx).packet(end,4)) && (temp_cnt == nNeighbor(blk_idx)) )
                    readSRAM = 1
                    stallMAC    = zeros(NETWORK.num_rows, NETWORK.num_cols);
                    reset_conv_cnt();
                    break;
                end
            end
        end


        if (readSRAM == 1)
            msg = sprintf('\n**Phase2: packet transfer [SRAM->PE]\n');      disp(msg);
            % update MAC compute_flag & operand_cnt
            % sim_t > est_time, then set compute_flag as 0 & operand_cnt as 0 & set packets to zeros(1,6) & est_time to 0
            initializeMAC();
            
          
            % data fetch from SRAM to PE
            % p_imgSize: image size of partial image covered by SRAM
            % currPosition (NETWORK.num_row x NETWORK.num_col): position of partial image handled by each PE
            [pushedPackets] = fetchDataSRAM(NN_type, image_idx, blk_idx, currPosition);
            
            prevPosition    = currPosition;
            
            if (~isempty(pushedPackets))
                msg = sprintf('\nTODO: need to implement packet generation from SRAM to PE in neighboring cells\n');    disp(msg);
                % increase 'arr_t' by 1 whenever ROUTER buffer is full
                [pushedPackets] = pushPacketSRAMtoPE();
            end
        end
        
        % 2) packet transfer in each ROUTER node (X_IN(k) -> Y_OUT(k))
        % {'C_IN', 'M_IN', 'N_IN', 'E_IN', 'W_IN', 'S_IN', 'C_OUT', 'M_OUT', 'N_OUT', 'E_OUT', 'W_OUT', 'S_OUT'}
        routerPacketTransfer();

        
        % 3) packet transfer btw ROUTER nodes (Y_OUT(k) -> X_IN(l))
        routerInterTransfer();
        
        % 4) update compute_flag & conv_cnt & est_time
        if (readSRAM)
            [currPosition] = updateEstimateTime(prevPosition);
            
            [mac_complete] = checkCompleteMAC();
            if (mac_complete)
                readDRAM = 1;       readSRAM = 0;
                if (~isempty(DRAM(1).packet))
                    mac_complete = 0;
                end
                
                if (SRAM_cap)
                    shrinkSRAMcap();
                end
            end
        end      

        
        if (genPacket(end,4) == SRAM(NETWORK.num_rows*NETWORK.num_cols).packet(end,4))
            rcv_complete = 1;
        end

    end     % END while loop

end

sim_t








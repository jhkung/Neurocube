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
%%%%%%%%%%%% Recently Edited on 08.13.2015 %%%%%%%%%%%%%%

clc;
clear all;

% define each component as a struct
global DRAM;    global ROUTER;
global PE;      global SRAM;
global NETWORK;


DRAM_type           = 'DDR3';
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


%% simulation begin
global MEM_CENTRIC;    MEM_CENTRIC = 1;
global packetID;
global packetHistory;  packetHistory = [];
global DRAM_router_node;
global SRAM_cap;       SRAM_cap    = 0;

% (total) numDATA = (locally stored templates) + (cell states + cell offsets)
numDATA         = NETWORK.num_rows*NETWORK.num_cols*(CNN.tempWidth*CNN.tempHeight) + 2*CNN.imgWidth*CNN.imgHeight;

global nRead;
global sim_t;   sim_t = 0;
time_max = 300;           % for debugging purpose
nRead    = 0;             % number of data read from DRAM
rcv_complete  = 0;        % determines whether DRAM fetch is completed

if (MEM_CENTRIC)
    
    % data packet generation from DRAM (genPacket kept as a reference)
    [ genPacket, packetID, image_idx ] = packetGen(NN_type, DRAM_type, num_MAC);        % generated packet by global address generator in DRAM die (memory-centric)
    if (length(genPacket) ~= numDATA)
        error('ENTIRE PACKETS ARE NOT GENERATED! - CHECK packetGen()');
    end
    
    readDRAM    = 1;        readSRAM    = 0;
    blk_idx     = 0;        % blk_idx: index for handling data of each SRAM cap
    nData_to_Read   = 2*numel(image_idx{1})/numel(DRAM);     % # of cell states & offset to be read from each DRAM channel considering SRAM cap
    nData_per_SRAM  = 2*numel(image_idx{1})/numel(SRAM);     % # of cell states & offset stored in each SRAM
    
%     while (~rcv_complete)     % if SRAM receives entire packets from DRAM
    while (sim_t < time_max)  % DEBUG purpose
        
        sim_t = sim_t + 1;
        
        % packet: [src, dst, gen_time, packetID, data_type, arr_time]
        % 1) packet fetched from DRAM at each channel (at the same time)
        % and fed into ROUTER node (gen_time = gen_time + DRAM latency)
        if (readDRAM)
            msg         = sprintf('\n**Phase1: packet transfer [DRAM->SRAM]\n');      disp(msg);
            [ popFlag ] = popPacketDRAM();
            
            if (nRead == nData_to_Read)
                nRead       = 0;    readDRAM    = 0;
                blk_idx     = blk_idx + 1;
            end
        end
        
        if (~isempty(packetHistory) && packetHistory(end,4) == SRAM(NETWORK.num_rows*NETWORK.num_cols).packet(end,4))
            readSRAM = 1;
        end
        
%         if (readSRAM)
%             msg = sprintf('\n**Phase2: packet transfer [SRAM->PE]\n');      disp(msg);
%             
%             % data fetch from SRAM to PE
% %             fetchDataSRAM();
%         end
        
        % 2) packet transfer in each ROUTER node (X_IN(k) -> Y_OUT(k))
        % {'C_IN', 'M_IN', 'N_IN', 'E_IN', 'W_IN', 'S_IN', 'C_OUT', 'M_OUT', 'N_OUT', 'E_OUT', 'W_OUT', 'S_OUT'}
        routerPacketTransfer();

        
        % 3) packet transfer btw ROUTER nodes (Y_OUT(k) -> X_IN(l))
        routerInterTransfer();
        
        if (genPacket(end,4) == SRAM(NETWORK.num_rows*NETWORK.num_cols).packet(end,4))
            rcv_complete = 1;
        end
    end     % END while loop

end










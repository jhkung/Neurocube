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
NETWORK.buffer_size = 1;
NETWORK.buffer_arr  = {'C_IN', 'M_IN', 'N_IN', 'E_IN', 'W_IN', 'S_IN', 'C_OUT', 'M_OUT', 'N_OUT', 'E_OUT', 'W_OUT', 'S_OUT'};       % 12 buffers with 'buffer_size'
ROUTER              = ROUTER_construct();       % ROUTER(router_idx, buffer_idx): data, buf_ptr

NN_type             = 'CNN';
num_MAC             = 4;    % # of MACs/PE
PE                  = PE_construct(NN_type, num_MAC);



% simulation setting
global SIM_TYPE;    SIM_TYPE = 1;     % SIM_TYPE (0: memory request, 1: memory centric)


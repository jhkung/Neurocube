function [ p_imgSize, imgSize ] = initData( )
% Initialize data for PE computation

global SRAM;    global NETWORK;     global CNN;
global SRAM_cap;

if (SRAM_cap)
    p_imgSize = sqrt((SRAM(1).capacity - CNN.tempHeight*CNN.tempWidth)/2);
    imgSize   = p_imgSize*NETWORK.num_cols;
else
    p_imgSize = CNN.imgWidth/NETWORK.num_cols;
    imgSize   = p_imgSize*NETWORK.num_cols;
end

end


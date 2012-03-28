% open cpp binary file
function fid = cmm_open_write(filename)
    fid = fopen(filename,'w');
end
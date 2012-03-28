function s = cmm_read_size(fid)
    s = fread(fid,1,'int32');
end
function t = cmm_read_type(fid)
   t = fread(fid,1,'uint8=>char');
end
function cmm_write_size(fid, size)
   fwrite(fid,size,'int32');
end
function cmm_write_type(fid, type)   
   fwrite(fid, type, 'char');      %% Write data type to file
end
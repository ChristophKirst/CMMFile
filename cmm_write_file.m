% write data to binary file f for use with
% c++ via cmmfile.h or mathamtica via CMMFile.m
% note: list of strings is assumed to be cell of strings
% note: for dimension treatment see cmm_read_data
function cmm_write_file(f, data)
   if ischar(f)
      fid = cmm_open_write(f);
   else
      fid = f;
   end

   if ~iscell(data)
      error('cmm_write: exspect cell of data entries');
   end;

   for k=1:length(data)
      cmm_write(fid, data{k})
   end

   if ischar(f)
      fclose(fid);
   end
end

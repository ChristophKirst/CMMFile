% write single data entry to binary file f for use with
% c++ via cmmfile.h or mathamtica via CMMFile.m
% note: list of strings is assumed to be cell of strings
% note: for dimension treatment see cmm_read_data
function cmm_write(fid, data)
   if iscell(data)
      if ~ischarcell(data);
         error('cmm_write: exspect char cell!');
      else
         t = to_cmm_type('char');
      end
   else
      t = to_cmm_type(class(data));
   end
   
   s = cmm_dim(data);
   
   disp(['... writing ' t '(' num2str(s) ') to file...'])
   
   cmm_write_header(fid, t, s);
   cmm_write_data(fid, data, t, s);
end
      
 

% read data form binary file f 
% created by c++ via cmmfile.h or or by Mathematica via CMMFile.m
% returns cell of data entries
function data = cmm_read_file(f)
   if ischar(f)
      fid = cmm_open_read(f);
   else
      fid = f;
   end
   
   data = {};
   k = 1;
   
   t = cmm_read_type(fid)
   while ~feof(fid)
      fseek(fid, -1, 'cof');
      if strcmp(t, 'S')
         seq = cmm_read_sequence(fid);
         for i=1:length(seq)
            data{k+i-1} = seq{i};
         end
      else
         data{k} = cmm_read(fid);
      end
      t = cmm_read_type(fid);
      k=k+1;
   end
   %data = data(1:end-1);
   
   if ischar(f)
      fclose(fid);
   end
end



      
